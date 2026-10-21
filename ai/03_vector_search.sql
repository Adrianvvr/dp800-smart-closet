-- Búsqueda inteligente: Full-Text Search, Búsqueda Vectorial y Búsqueda Híbrida (RRF)

USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Configuración de Full-Text Search si está instalado
IF FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') = 1
BEGIN
    EXEC sp_executesql N'
        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = ''ftc_SmartCloset'')
            CREATE FULLTEXT CATALOG ftc_SmartCloset AS DEFAULT;

        IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(''dbo.DOCUMENTOS_BUSQUEDA''))
            CREATE FULLTEXT INDEX ON dbo.DOCUMENTOS_BUSQUEDA (
                titulo LANGUAGE Spanish,
                contenido_texto LANGUAGE Spanish
            )
            KEY INDEX PK_DOCUMENTOS_BUSQUEDA ON ftc_SmartCloset
            WITH CHANGE_TRACKING AUTO;
    ';
END;
GO

-- SP: Búsqueda Vectorial pura (KNN mediante distancia coseno)
CREATE OR ALTER PROCEDURE dbo.usp_BuscarArmarioVectorial
    @ConsultaTexto NVARCHAR(500),
    @UsuarioID INT = NULL,
    @TipoOrigen NVARCHAR(20) = NULL,
    @TopK INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF @UsuarioID IS NOT NULL
        EXEC sp_set_session_context @key = N'usuario_id', @value = @UsuarioID;

    DECLARE @VectorConsulta VECTOR(768);

    SET @VectorConsulta = CAST(
        AI_GENERATE_EMBEDDINGS(@ConsultaTexto USE MODEL ModeloEmbeddingsOllama)
        AS VECTOR(768)
    );

    SELECT TOP (@TopK)
        ROW_NUMBER() OVER (ORDER BY VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) ASC) AS Ranking,
        d.id AS DocumentoID,
        d.usuario_id AS UsuarioID,
        d.tipo_origen AS TipoOrigen,
        d.origen_id AS OrigenID,
        d.titulo AS Titulo,
        CAST(VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) AS DECIMAL(8,4)) AS DistanciaCoseno,
        CAST((1.0 - VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta)) * 100.0 AS DECIMAL(5,2)) AS SimilitudPorcentaje,
        d.contenido_texto AS ContenidoChunk,
        d.metadatos_json AS Metadatos
    FROM dbo.DOCUMENTOS_BUSQUEDA d
    WHERE d.embedding IS NOT NULL
      AND (@UsuarioID IS NULL OR d.usuario_id = @UsuarioID)
      AND (@TipoOrigen IS NULL OR d.tipo_origen = @TipoOrigen)
    ORDER BY VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) ASC;
END;
GO

-- SP: Búsqueda Híbrida Robusta (Vectorial + Léxica) usando Reciprocal Rank Fusion (RRF)
CREATE OR ALTER PROCEDURE dbo.usp_BuscarArmarioHibridoRRF
    @ConsultaTexto NVARCHAR(500),
    @UsuarioID INT = NULL,
    @TipoOrigen NVARCHAR(20) = NULL,
    @TopK INT = 5,
    @ConstanteRRF INT = 60
AS
BEGIN
    SET NOCOUNT ON;

    IF @UsuarioID IS NOT NULL
        EXEC sp_set_session_context @key = N'usuario_id', @value = @UsuarioID;

    -- Embedding de la consulta
    DECLARE @VectorConsulta VECTOR(768);
    SET @VectorConsulta = CAST(
        AI_GENERATE_EMBEDDINGS(@ConsultaTexto USE MODEL ModeloEmbeddingsOllama)
        AS VECTOR(768)
    );

    -- Tokenización de palabras clave relevantes (>3 caracteres y sin stop-words)
    ;WITH CTE_PalabrasConsulta AS (
        SELECT DISTINCT TRIM(value) AS palabra
        FROM STRING_SPLIT(
            REGEXP_REPLACE(@ConsultaTexto, N'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ ]', N' '), 
            N' '
        )
        WHERE LEN(TRIM(value)) > 3
          AND LOWER(TRIM(value)) NOT IN (N'para', N'como', N'algo', N'este', N'esta', N'unos', N'unas', N'pero', N'porque', N'cuando', N'donde', N'llevar', N'ponerme', N'viajar')
    ),
    -- Cruce léxico ponderado (Título pesa 2, Contenido pesa 1)
    CTE_CoincidenciasDetalle AS (
        SELECT 
            d.id AS DocumentoID,
            d.usuario_id,
            d.tipo_origen,
            d.origen_id,
            d.titulo,
            d.contenido_texto,
            VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) AS distancia_coseno,
            (CASE WHEN d.titulo LIKE CONCAT(N'%', p.palabra, N'%') THEN 2 ELSE 0 END +
             CASE WHEN d.contenido_texto LIKE CONCAT(N'%', p.palabra, N'%') THEN 1 ELSE 0 END) AS peso_palabra
        FROM dbo.DOCUMENTOS_BUSQUEDA d
        INNER JOIN CTE_PalabrasConsulta p 
            ON d.titulo LIKE CONCAT(N'%', p.palabra, N'%') 
            OR d.contenido_texto LIKE CONCAT(N'%', p.palabra, N'%')
        WHERE d.embedding IS NOT NULL
          AND (@UsuarioID IS NULL OR d.usuario_id = @UsuarioID)
          AND (@TipoOrigen IS NULL OR d.tipo_origen = @TipoOrigen)
    ),
    -- Agrupación de puntaje léxico por documento
    CTE_PuntajesAgrupados AS (
        SELECT 
            DocumentoID, usuario_id, tipo_origen, origen_id, 
            titulo, contenido_texto, distancia_coseno,
            SUM(peso_palabra) AS puntos_lexicos
        FROM CTE_CoincidenciasDetalle
        GROUP BY 
            DocumentoID, usuario_id, tipo_origen, origen_id, 
            titulo, contenido_texto, distancia_coseno
    ),
    -- Unión con resultados puramente vectoriales
    CTE_MetricasCompletas AS (
        SELECT 
            d.id AS DocumentoID,
            d.usuario_id,
            d.tipo_origen,
            d.origen_id,
            d.titulo,
            d.contenido_texto,
            VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) AS distancia_coseno,
            ISNULL(pa.puntos_lexicos, 0) AS puntos_lexicos
        FROM dbo.DOCUMENTOS_BUSQUEDA d
        LEFT JOIN CTE_PuntajesAgrupados pa ON d.id = pa.DocumentoID
        WHERE d.embedding IS NOT NULL
          AND (@UsuarioID IS NULL OR d.usuario_id = @UsuarioID)
          AND (@TipoOrigen IS NULL OR d.tipo_origen = @TipoOrigen)
    ),
    -- Generación de rankings independientes (Vectorial y Léxico)
    CTE_Rankings AS (
        SELECT 
            DocumentoID, usuario_id, tipo_origen, origen_id,
            titulo, contenido_texto, distancia_coseno, puntos_lexicos,
            ROW_NUMBER() OVER (ORDER BY distancia_coseno ASC) AS rank_vectorial,
            CASE 
                WHEN puntos_lexicos > 0 
                THEN ROW_NUMBER() OVER (ORDER BY puntos_lexicos DESC, distancia_coseno ASC)
                ELSE 999 
            END AS rank_lexico
        FROM CTE_MetricasCompletas
    )
    -- Fusión RRF final
    SELECT TOP (@TopK)
        ROW_NUMBER() OVER (
            ORDER BY 
                (1.0 / (@ConstanteRRF + rank_vectorial)) + 
                (CASE WHEN puntos_lexicos > 0 THEN (1.0 / (@ConstanteRRF + rank_lexico)) ELSE 0.0 END) 
            DESC
        ) AS RankingFinalRRF,
        DocumentoID,
        usuario_id AS UsuarioID,
        tipo_origen AS TipoOrigen,
        titulo AS Titulo,
        CAST(
            (1.0 / (@ConstanteRRF + rank_vectorial)) + 
            (CASE WHEN puntos_lexicos > 0 THEN (1.0 / (@ConstanteRRF + rank_lexico)) ELSE 0.0 END)
            AS DECIMAL(8,5)
        ) AS ScoreRRF,
        rank_vectorial AS PosicionVectorial,
        CASE WHEN puntos_lexicos > 0 THEN rank_lexico ELSE NULL END AS PosicionLexica,
        puntos_lexicos AS PuntuacionLexica,
        CAST((1.0 - distancia_coseno) * 100.0 AS DECIMAL(5,2)) AS SimilitudVectorialPct,
        contenido_texto AS ContenidoChunk
    FROM CTE_Rankings
    ORDER BY ScoreRRF DESC, distancia_coseno ASC;
END;
GO

GRANT EXECUTE ON dbo.usp_BuscarArmarioVectorial TO rol_UsuarioApp;
GRANT EXECUTE ON dbo.usp_BuscarArmarioHibridoRRF TO rol_UsuarioApp;
GO

-- Demostración: Fallo en SQL Clásico vs Éxito en Búsqueda Vectorial e Híbrida

SELECT id, nombre, descripcion 
FROM dbo.PRENDAS 
WHERE usuario_id = 1 
  AND descripcion LIKE N'%asarme de calor en un evento%';

EXEC dbo.usp_BuscarArmarioVectorial
    @ConsultaTexto = N'ropa fresca para no asarme de calor en un evento al sol',
    @UsuarioID = 1,
    @TopK = 4;

EXEC dbo.usp_BuscarArmarioHibridoRRF
    @ConsultaTexto = N'ropa impermeable que no se arrugue en la maleta para viajar con lluvia',
    @UsuarioID = 3,
    @TopK = 5;
GO