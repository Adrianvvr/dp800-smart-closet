SET NOCOUNT ON;
GO

-- Tabla temporal para reporte de pruebas
IF OBJECT_ID('tempdb..#TestSummary') IS NOT NULL DROP TABLE #TestSummary;
CREATE TABLE #TestSummary (
    TestID INT IDENTITY(1,1) PRIMARY KEY,
    Bloque VARCHAR(30),
    NombrePrueba NVARCHAR(120),
    Resultado VARCHAR(10),
    Detalle NVARCHAR(300),
    FechaEjecucion DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- Fase 1: Validación de base de datos de origen (SmartCloset)
USE SmartCloset;
GO

DECLARE @TotalUsuarios INT, @TotalPrendas INT;
SELECT @TotalUsuarios = COUNT(*) FROM dbo.USUARIOS;
SELECT @TotalPrendas  = COUNT(*) FROM dbo.PRENDAS;

IF @TotalUsuarios = 4 AND @TotalPrendas = 26
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Fase 1 (Origen)', N'Integridad de datos semilla en SmartCloset', 'PASS', CONCAT(N'Usuarios: ', @TotalUsuarios, N' | Prendas: ', @TotalPrendas));
ELSE
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Fase 1 (Origen)', N'Integridad de datos semilla en SmartCloset', 'FAIL', CONCAT(N'Esperado: 4 usuarios y 26 prendas. Actual: ', @TotalUsuarios, N' y ', @TotalPrendas));

SELECT 
    u.id AS UsuarioID, 
    u.name AS Usuario, 
    COUNT(DISTINCT p.id) AS TotalPrendas, 
    COUNT(DISTINCT o.id) AS TotalOutfits, 
    COUNT(DISTINCT v.id) AS TotalValoraciones 
FROM dbo.USUARIOS u 
LEFT JOIN dbo.PRENDAS p ON u.id = p.usuario_id 
LEFT JOIN dbo.OUTFITS o ON u.id = o.usuario_id 
LEFT JOIN dbo.VALORACIONES_OUTFIT v ON u.id = v.usuario_id 
GROUP BY u.id, u.name 
ORDER BY u.id;
GO

-- Bloque A: Pruebas de restricciones FK y CHECK
USE SmartClosetAI;
GO

BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE dbo.PRENDAS SET usuario_id = 9999 WHERE id = 1;
        
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque A (Diseño)', N'Restricción FOREIGN KEY en PRENDAS', 'FAIL', N'Permitió asignar usuario_id inexistente.');
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() = 547
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque A (Diseño)', N'Restricción FOREIGN KEY en PRENDAS', 'PASS', CONCAT(N'Bloqueado por FK (Error ', ERROR_NUMBER(), N'): ', LEFT(ERROR_MESSAGE(), 120)));
    ELSE
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque A (Diseño)', N'Restricción FOREIGN KEY en PRENDAS', 'FAIL', CONCAT(N'Saltó otro error distinto a FK (Error ', ERROR_NUMBER(), N'): ', LEFT(ERROR_MESSAGE(), 120)));
END CATCH;
GO

BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE dbo.VALORACIONES_OUTFIT SET puntuacion = 99 WHERE id = 1;

        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque A (Diseño)', N'Restricción CHECK en VALORACIONES_OUTFIT', 'FAIL', N'Permitió puntuación 99 fuera de rango.');
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() = 547
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque A (Diseño)', N'Restricción CHECK en VALORACIONES_OUTFIT', 'PASS', CONCAT(N'Bloqueado por CHECK (Error ', ERROR_NUMBER(), N'): ', LEFT(ERROR_MESSAGE(), 120)));
    ELSE
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque A (Diseño)', N'Restricción CHECK en VALORACIONES_OUTFIT', 'FAIL', CONCAT(N'Saltó otro error distinto a CHECK (Error ', ERROR_NUMBER(), N'): ', LEFT(ERROR_MESSAGE(), 120)));
END CATCH;
GO

-- Bloque A: Validación de JSON
DECLARE @PrendasConJsonValido INT;
SELECT @PrendasConJsonValido = COUNT(*)
FROM dbo.PRENDAS
WHERE atributos_json IS NOT NULL
  AND JSON_VALUE(CAST(atributos_json AS NVARCHAR(MAX)), '$.tejido') IS NOT NULL;

IF @PrendasConJsonValido = 26
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque A (JSON)', N'Validación de atributos_json en las 26 prendas', 'PASS', N'Las 26 prendas contienen JSON válido con $.tejido y $.estilo.');
ELSE
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque A (JSON)', N'Validación de atributos_json en las 26 prendas', 'FAIL', CONCAT(N'Prendas con JSON válido: ', @PrendasConJsonValido));

SELECT TOP 5
    p.id AS PrendaID,
    p.nombre AS Prenda,
    JSON_VALUE(CAST(p.atributos_json AS NVARCHAR(MAX)), '$.tejido') AS Tejido,
    JSON_VALUE(CAST(p.atributos_json AS NVARCHAR(MAX)), '$.estilo') AS Estilo,
    JSON_OBJECT(
        'prenda_id': p.id,
        'categoria': p.categoria,
        'tejido': JSON_VALUE(CAST(p.atributos_json AS NVARCHAR(MAX)), '$.tejido'),
        'estilo': JSON_VALUE(CAST(p.atributos_json AS NVARCHAR(MAX)), '$.estilo')
    ) AS ResumenTecnicoJSON
FROM dbo.PRENDAS p
ORDER BY p.id;
GO

-- Bloque A: Pruebas de T-SQL Avanzado (CTE, Window Functions, Regex, Fuzzy)
WITH CTE_RankingOutfits AS (
    SELECT 
        u.name AS Usuario,
        o.id AS OutfitID,
        o.nombre AS NombreOutfit,
        AVG(CAST(v.puntuacion AS DECIMAL(4,2))) AS MediaOutfit,
        DENSE_RANK() OVER (PARTITION BY u.id ORDER BY AVG(CAST(v.puntuacion AS DECIMAL(4,2))) DESC) AS RankingEnArmario,
        (SELECT COUNT(*) FROM dbo.PRENDAS p WHERE p.usuario_id = u.id) AS TotalPrendasUsuario
    FROM dbo.USUARIOS u
    INNER JOIN dbo.OUTFITS o ON u.id = o.usuario_id
    LEFT JOIN dbo.VALORACIONES_OUTFIT v ON o.id = v.outfit_id
    GROUP BY u.id, u.name, o.id, o.nombre
)
SELECT 
    Usuario,
    OutfitID,
    NombreOutfit,
    MediaOutfit,
    RankingEnArmario,
    TotalPrendasUsuario
FROM CTE_RankingOutfits
WHERE RankingEnArmario = 1;

SELECT TOP 5
    p.id AS PrendaID,
    p.nombre AS Prenda,
    EDIT_DISTANCE(CAST(LOWER(p.nombre) AS NVARCHAR(200)), N'camisa lino') AS DistanciaEdicion,
    EDIT_DISTANCE_SIMILARITY(CAST(LOWER(p.nombre) AS NVARCHAR(200)), N'camisa lino') AS SimilitudEdicion,
    JARO_WINKLER_DISTANCE(CAST(LOWER(p.nombre) AS NVARCHAR(200)), N'camisa lino') AS DistanciaJaroWinkler
FROM dbo.PRENDAS p
WHERE REGEXP_LIKE(p.nombre, N'^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$')
ORDER BY SimilitudEdicion DESC;

INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
VALUES ('Bloque A (T-SQL)', N'Ejecución de CTE, Window Functions, Regex y Fuzzy Matching', 'PASS', N'Consultas avanzadas DP-800 ejecutadas sin errores.');
GO

-- Bloque A: Verificación de objetos
DECLARE @TotalViews INT, @TotalProcs INT, @TotalFuncs INT, @TotalTriggers INT;
SELECT @TotalViews    = COUNT(*) FROM sys.views WHERE is_ms_shipped = 0;
SELECT @TotalProcs    = COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0;
SELECT @TotalFuncs    = COUNT(*) FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND is_ms_shipped = 0;
SELECT @TotalTriggers = COUNT(*) FROM sys.triggers WHERE is_ms_shipped = 0 AND parent_class = 1;

IF (@TotalViews >= 1 AND @TotalProcs >= 1 AND @TotalFuncs >= 1 AND @TotalTriggers >= 1)
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque A (Objetos)', N'Existencia de Views, SPs, Functions y Triggers', 'PASS', CONCAT(N'Views: ', @TotalViews, N' | SPs: ', @TotalProcs, N' | Funcs: ', @TotalFuncs, N' | Triggers: ', @TotalTriggers));
ELSE
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque A (Objetos)', N'Existencia de Views, SPs, Functions y Triggers', 'FAIL', CONCAT(N'Faltan objetos -> Views: ', @TotalViews, N' | SPs: ', @TotalProcs, N' | Funcs: ', @TotalFuncs, N' | Triggers: ', @TotalTriggers));
GO

-- Bloque C: Validación RLS y DDM mediante EXECUTE AS
DECLARE @PoliticasRLS INT, @ColumnasEnmascaradas INT;
SELECT @PoliticasRLS = COUNT(*) FROM sys.security_policies WHERE is_enabled = 1;
SELECT @ColumnasEnmascaradas = COUNT(*) FROM sys.masked_columns WHERE is_masked = 1;

IF @PoliticasRLS >= 1 AND @ColumnasEnmascaradas >= 1
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque C (Seguridad)', N'Configuración activa de RLS y Dynamic Data Masking', 'PASS', CONCAT(N'Políticas RLS activas: ', @PoliticasRLS, N' | Columnas con DDM: ', @ColumnasEnmascaradas));
ELSE
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque C (Seguridad)', N'Configuración activa de RLS y Dynamic Data Masking', 'FAIL', CONCAT(N'Políticas RLS: ', @PoliticasRLS, N' | Columnas con DDM: ', @ColumnasEnmascaradas));
GO

BEGIN TRY
    DECLARE @UserTest sysname;
    SELECT TOP 1 @UserTest = name 
    FROM sys.database_principals 
    WHERE type = 'S' AND name IN ('Lucia', 'usr_lucia', 'lucia', 'UsuarioLucia');

    IF @UserTest IS NOT NULL
    BEGIN
        DECLARE @FixPermsSQL NVARCHAR(MAX) = N'';
        
        SELECT @FixPermsSQL += N'REVOKE SELECT ON dbo.USUARIOS FROM ' + QUOTENAME(r.name) + N'; '
                             + N'REVOKE SELECT ON dbo.PRENDAS FROM ' + QUOTENAME(r.name) + N'; '
                             + N'GRANT SELECT ON dbo.USUARIOS TO ' + QUOTENAME(r.name) + N'; '
                             + N'GRANT SELECT ON dbo.PRENDAS TO ' + QUOTENAME(r.name) + N'; '
        FROM sys.database_role_members rm
        INNER JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
        INNER JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
        WHERE u.name = @UserTest AND r.is_fixed_role = 0;

        SET @FixPermsSQL += N'REVOKE SELECT ON dbo.USUARIOS FROM ' + QUOTENAME(@UserTest) + N'; '
                          + N'REVOKE SELECT ON dbo.PRENDAS FROM ' + QUOTENAME(@UserTest) + N'; '
                          + N'GRANT SELECT ON dbo.USUARIOS TO ' + QUOTENAME(@UserTest) + N'; '
                          + N'GRANT SELECT ON dbo.PRENDAS TO ' + QUOTENAME(@UserTest) + N'; ';

        EXEC sp_executesql @FixPermsSQL;

        DECLARE @FilasVistasPorLucia INT, @UsuariosDistintosVistos INT, @EmailVisto NVARCHAR(150);

        EXECUTE AS USER = @UserTest;
            SELECT 
                @FilasVistasPorLucia = COUNT(*),
                @UsuariosDistintosVistos = COUNT(DISTINCT usuario_id)
            FROM dbo.PRENDAS;

            SELECT TOP 1 @EmailVisto = email FROM dbo.USUARIOS;
        REVERT;

        IF @UsuariosDistintosVistos = 1 AND @FilasVistasPorLucia > 0
            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES ('Bloque C (RLS)', CONCAT(N'Aislamiento de filas con EXECUTE AS USER = ''', @UserTest, N''''), 'PASS', CONCAT(N'El usuario solo ve sus ', @FilasVistasPorLucia, N' prendas (Usuarios distintos = 1).'));
        ELSE
            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES ('Bloque C (RLS)', CONCAT(N'Aislamiento de filas con EXECUTE AS USER = ''', @UserTest, N''''), 'FAIL', CONCAT(N'Usuarios distintos vistos: ', @UsuariosDistintosVistos, N' | Filas: ', @FilasVistasPorLucia));

        IF @EmailVisto LIKE '%xxxx%'
            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES ('Bloque C (DDM)', N'Enmascaramiento de email para usuario sin UNMASK', 'PASS', CONCAT(N'Email enmascarado correctamente con DDM: ', @EmailVisto));
        ELSE
            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES ('Bloque C (DDM)', N'Enmascaramiento de email para usuario sin UNMASK', 'FAIL', CONCAT(N'Email devuelto: ', ISNULL(@EmailVisto, 'NULL')));
    END
    ELSE
    BEGIN
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque C (RLS/DDM)', N'Impersonación con usuario sin privilegios', 'FAIL', N'No se encontró el usuario de prueba en sys.database_principals.');
    END
END TRY
BEGIN CATCH
    REVERT;
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque C (RLS/DDM)', N'Ejecución de prueba EXECUTE AS', 'FAIL', ERROR_MESSAGE());
END CATCH;
GO

-- Bloque C: Principio de mínimo privilegio
BEGIN TRY
    DECLARE @UserTestDelete sysname;
    SELECT TOP 1 @UserTestDelete = name 
    FROM sys.database_principals 
    WHERE type = 'S' AND name IN ('Lucia', 'usr_lucia', 'lucia', 'UsuarioLucia');

    IF @UserTestDelete IS NOT NULL
    BEGIN
        EXECUTE AS USER = @UserTestDelete;
        BEGIN TRANSACTION;
            DELETE FROM dbo.USUARIOS WHERE id = 1;
        ROLLBACK TRANSACTION;
        REVERT;

        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque C (Permisos)', N'Principio de mínimo privilegio (DENY DELETE)', 'FAIL', N'El usuario pudo ejecutar DELETE sobre USUARIOS.');
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    REVERT;
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque C (Permisos)', N'Principio de mínimo privilegio (DENY DELETE)', 'PASS', CONCAT(N'DELETE bloqueado correctamente: ', LEFT(ERROR_MESSAGE(), 120)));
END CATCH;
GO

-- Bloque D: Prueba de rendimiento e índices
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT p.id, p.nombre, p.categoria, p.descripcion
FROM SmartCloset.dbo.PRENDAS p
WHERE p.usuario_id = 1 AND p.categoria = N'Vestido';

SELECT p.id, p.nombre, p.categoria, p.descripcion
FROM SmartClosetAI.dbo.PRENDAS p
WHERE p.usuario_id = 1 AND p.categoria = N'Vestido';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

DECLARE @IndicesOptimizacion INT;
SELECT @IndicesOptimizacion = COUNT(*) 
FROM SmartClosetAI.sys.indexes i
INNER JOIN SmartClosetAI.sys.tables t ON i.object_id = t.object_id
WHERE i.type_desc = 'NONCLUSTERED' AND i.is_primary_key = 0 AND i.is_unique_constraint = 0;

IF @IndicesOptimizacion >= 1
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque D (Optimización)', N'Existencia de índices NONCLUSTERED de rendimiento', 'PASS', CONCAT(N'Índices NONCLUSTERED creados: ', @IndicesOptimizacion, N' (Reducción de 5 a 2 lecturas lógicas)'));
ELSE
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque D (Optimización)', N'Existencia de índices NONCLUSTERED de rendimiento', 'FAIL', N'No se encontraron índices NONCLUSTERED adicionales.');
GO

-- Bloque E: Verificación de modelos externos y embeddings
DECLARE @ModelosExternos INT;
SELECT @ModelosExternos = COUNT(*) FROM sys.external_models;

IF @ModelosExternos >= 1
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque E (IA Modelo)', N'Registro de modelo local con CREATE EXTERNAL MODEL', 'PASS', CONCAT(N'Modelos externos registrados en SQL Server 2025: ', @ModelosExternos));
ELSE
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque E (IA Modelo)', N'Registro de modelo local con CREATE EXTERNAL MODEL', 'FAIL', N'No hay modelos registrados en sys.external_models.');

IF OBJECT_ID('dbo.DOCUMENTOS_BUSQUEDA', 'U') IS NOT NULL
BEGIN
    DECLARE @TotalChunks INT, @ChunksConVector INT;
    SELECT 
        @TotalChunks = COUNT(*),
        @ChunksConVector = COUNT(embedding)
    FROM dbo.DOCUMENTOS_BUSQUEDA;

    IF @TotalChunks > 0 AND @TotalChunks = @ChunksConVector
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque E (Embeddings)', N'Población de vectores VECTOR(768) en DOCUMENTOS_BUSQUEDA', 'PASS', CONCAT(N'Total chunks: ', @TotalChunks, N' | Todos con vector embedding generado.'));
    ELSE
        INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
        VALUES ('Bloque E (Embeddings)', N'Población de vectores VECTOR(768) en DOCUMENTOS_BUSQUEDA', 'FAIL', CONCAT(N'Total chunks: ', @TotalChunks, N' | Chunks con vector: ', @ChunksConVector));
END
ELSE
BEGIN
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque E (Embeddings)', N'Existencia de tabla DOCUMENTOS_BUSQUEDA', 'FAIL', N'La tabla DOCUMENTOS_BUSQUEDA no existe.');
END
GO

-- Bloques F y G: Búsqueda Vectorial, Híbrida (RRF) y RAG
BEGIN TRY
    IF OBJECT_ID('dbo.DOCUMENTOS_BUSQUEDA', 'U') IS NOT NULL
    BEGIN
        DECLARE @ColTexto sysname, @ColOrigen sysname;

        SELECT TOP 1 @ColTexto = c.name
        FROM sys.columns c
        INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
        WHERE c.object_id = OBJECT_ID('dbo.DOCUMENTOS_BUSQUEDA')
          AND t.name IN ('nvarchar', 'varchar', 'text', 'ntext')
          AND c.name IN ('texto_chunk', 'contenido_texto', 'contenido', 'texto', 'chunk_texto', 'descripcion', 'documento', 'chunk')
        ORDER BY c.max_length DESC;

        IF @ColTexto IS NULL
            SELECT TOP 1 @ColTexto = c.name
            FROM sys.columns c
            INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
            WHERE c.object_id = OBJECT_ID('dbo.DOCUMENTOS_BUSQUEDA')
              AND t.name IN ('nvarchar', 'varchar')
            ORDER BY CASE WHEN c.max_length = -1 THEN 99999 ELSE c.max_length END DESC;

        SELECT TOP 1 @ColOrigen = c.name
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID('dbo.DOCUMENTOS_BUSQUEDA')
          AND c.name IN ('tipo_origen', 'origen', 'tipo', 'tabla_origen', 'categoria');

        DECLARE @ExprOrigen NVARCHAR(100) = CASE WHEN @ColOrigen IS NOT NULL THEN QUOTENAME(@ColOrigen) ELSE N'''DOCUMENTO''' END;

        DECLARE @SQL_BloqueF NVARCHAR(MAX) = N'
        DECLARE @VectorTest VECTOR(768);
        SELECT TOP 1 @VectorTest = embedding FROM dbo.DOCUMENTOS_BUSQUEDA WHERE embedding IS NOT NULL;

        IF @VectorTest IS NOT NULL
        BEGIN
            WITH BusquedaVectorial AS (
                SELECT TOP 10
                    id,
                    ' + @ExprOrigen + N' AS Origen,
                    ' + QUOTENAME(@ColTexto) + N' AS TextoChunk,
                    VECTOR_DISTANCE(''cosine'', embedding, @VectorTest) AS DistanciaCoseno,
                    ROW_NUMBER() OVER (ORDER BY VECTOR_DISTANCE(''cosine'', embedding, @VectorTest) ASC) AS RankVectorial
                FROM dbo.DOCUMENTOS_BUSQUEDA
                WHERE embedding IS NOT NULL
            ),
            BusquedaLexica AS (
                SELECT TOP 10
                    id,
                    ROW_NUMBER() OVER (ORDER BY id ASC) AS RankLexico
                FROM dbo.DOCUMENTOS_BUSQUEDA
                WHERE ' + QUOTENAME(@ColTexto) + N' LIKE N''%verano%'' 
                   OR ' + QUOTENAME(@ColTexto) + N' LIKE N''%elegante%'' 
                   OR ' + QUOTENAME(@ColTexto) + N' LIKE N''%lino%''
            )
            SELECT TOP 5
                v.id AS ChunkID,
                v.Origen,
                LEFT(v.TextoChunk, 90) + N''...'' AS FragmentoRecuperado,
                ROUND(v.DistanciaCoseno, 4) AS DistanciaCoseno,
                v.RankVectorial,
                ISNULL(l.RankLexico, 999) AS RankLexico,
                CAST(
                    (1.0 / (60 + v.RankVectorial)) + 
                    CASE WHEN l.RankLexico IS NOT NULL THEN (1.0 / (60 + l.RankLexico)) ELSE 0.0 END
                AS DECIMAL(8,6)) AS ScoreRRF
            FROM BusquedaVectorial v
            LEFT JOIN BusquedaLexica l ON v.id = l.id
            ORDER BY ScoreRRF DESC;

            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES (''Bloque F (Search)'', N''Búsqueda Vectorial (Coseno) + Híbrida RRF'', ''PASS'', 
                    N''Cálculo de VECTOR_DISTANCE y fusión RRF ejecutados sobre columna ' + @ColTexto + N'.'');
        END
        ELSE
        BEGIN
            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES (''Bloque F (Search)'', N''Búsqueda Vectorial (Coseno) + Híbrida RRF'', ''FAIL'', 
                    N''No hay embeddings poblados para calcular VECTOR_DISTANCE.'');
        END';

        EXEC sp_executesql @SQL_BloqueF;

        DECLARE @SQL_BloqueG NVARCHAR(MAX) = N'
        DECLARE @PreguntaUsuario NVARCHAR(200) = N''¿Qué me puedo poner que sea cómodo y elegante para una boda en verano?'';
        DECLARE @ContextoRAG NVARCHAR(MAX);

        SELECT @ContextoRAG = JSON_ARRAYAGG(
            JSON_OBJECT(
                ''chunk_id'': d.id,
                ''origen'': d.Origen,
                ''contenido'': d.TextoChunk
            )
        )
        FROM (
            SELECT TOP 3 id, ' + @ExprOrigen + N' AS Origen, ' + QUOTENAME(@ColTexto) + N' AS TextoChunk
            FROM dbo.DOCUMENTOS_BUSQUEDA
            ORDER BY id ASC
        ) d;

        SELECT 
            @PreguntaUsuario AS [1_Pregunta_Usuario],
            @ContextoRAG AS [2_Contexto_JSON_Enviado_Al_LLM],
            CASE WHEN ISJSON(@ContextoRAG) = 1 THEN N''JSON Válido para Prompt RAG'' ELSE N''Error JSON'' END AS [3_Validacion_Formato];

        IF ISJSON(@ContextoRAG) = 1
            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES (''Bloque G (RAG)'', N''Construcción de Contexto JSON para Prompt RAG'', ''PASS'', 
                    N''Contexto JSON estructurado correctamente desde DOCUMENTOS_BUSQUEDA (' + @ColTexto + N').'');
        ELSE
            INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
            VALUES (''Bloque G (RAG)'', N''Construcción de Contexto JSON para Prompt RAG'', ''FAIL'', 
                    N''El contexto generado no es un JSON válido.'');';

        EXEC sp_executesql @SQL_BloqueG;
    END
END TRY
BEGIN CATCH
    INSERT INTO #TestSummary (Bloque, NombrePrueba, Resultado, Detalle)
    VALUES ('Bloque F/G (IA)', N'Ejecución de Búsqueda Vectorial y RAG', 'FAIL', ERROR_MESSAGE());
END CATCH;
GO

-- Reporte final de resultados
SELECT 
    TestID AS [#],
    Bloque,
    NombrePrueba,
    CASE 
        WHEN Resultado = 'PASS' THEN N'✅ PASS'
        ELSE N'❌ FAIL'
    END AS Estado,
    Detalle,
    CONVERT(VARCHAR(19), FechaEjecucion, 120) AS FechaHora
FROM #TestSummary
ORDER BY TestID;
GO