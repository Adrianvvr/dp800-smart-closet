-- Capa de programabilidad avanzada DP-800

USE SmartClosetAI;
GO

-- Habilitar Preview Features para funciones avanzadas (Fuzzy Matching)
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

SET NOCOUNT ON;
GO

-- iTVF: Búsqueda aproximada de marcas (Fuzzy Matching + Regex)
CREATE OR ALTER FUNCTION dbo.fn_BuscarMarcaAproximada
(
    @TextoBusqueda NVARCHAR(100),
    @MaxDistancia INT = 3
)
RETURNS TABLE
AS
RETURN
(
    WITH CTE_EntradaLimpia AS (
        -- Limpiar símbolos manteniendo alfanuméricos y espacios
        SELECT TRIM(REGEXP_REPLACE(@TextoBusqueda, N'[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ ]', N'')) AS texto_limpio
    )
    SELECT 
        m.id AS marca_id,
        m.nombre AS marca_oficial,
        m.sitio_web,
        e.texto_limpio AS termino_buscado,
        -- Cálculo de Distancia de Levenshtein
        EDIT_DISTANCE(UPPER(m.nombre), UPPER(e.texto_limpio)) AS distancia_edicion,
        -- Cálculo de similitud porcentual
        EDIT_DISTANCE_SIMILARITY(UPPER(m.nombre), UPPER(e.texto_limpio)) AS porcentaje_similitud
    FROM dbo.MARCAS m
    CROSS JOIN CTE_EntradaLimpia e
    WHERE EDIT_DISTANCE(UPPER(m.nombre), UPPER(e.texto_limpio)) <= @MaxDistancia
       OR m.nombre LIKE CONCAT(N'%', e.texto_limpio, N'%')
);
GO

-- Trigger DML: Sincronizar chunks de búsqueda y resetear embeddings
CREATE OR ALTER TRIGGER dbo.trg_SincronizarChunkPrenda
ON dbo.PRENDAS
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar si se modificaron campos relevantes
    IF NOT (
        UPDATE(nombre) OR UPDATE(descripcion) OR UPDATE(categoria) OR 
        UPDATE(color_principal) OR UPDATE(atributos_json) OR UPDATE(esta_limpia)
    )
    BEGIN
        RETURN;
    END;

    MERGE INTO dbo.DOCUMENTOS_BUSQUEDA AS Target
    USING (
        SELECT 
            i.usuario_id,
            N'PRENDA' AS tipo_origen,
            i.id AS origen_id,
            i.nombre AS titulo,
            CONCAT(
                N'Prenda: ', i.nombre, N'. ',
                N'Categoría: ', i.categoria, N'. ',
                N'Marca: ', ISNULL(m.nombre, N'Sin marca'), N'. ',
                N'Color: ', i.color_principal, N'. ',
                N'Temporada: ', ISNULL(JSON_VALUE(i.atributos_json, '$.temporada'), N'Todas'), N'. ',
                N'Tejido: ', ISNULL(JSON_VALUE(i.atributos_json, '$.tejido'), N'No especificado'), N'. ',
                N'Estilo: ', ISNULL(JSON_VALUE(i.atributos_json, '$.estilo'), N'Estándar'), N'. ',
                N'Estado limpieza: ', CASE WHEN i.esta_limpia = 1 THEN N'Limpia y disponible' ELSE N'Sucia en lavandería' END, N'. ',
                N'Descripción: ', ISNULL(i.descripcion, N'')
            ) AS contenido_texto,
            CAST(
                JSON_OBJECT(
                    'categoria': i.categoria,
                    'marca': ISNULL(m.nombre, N''),
                    'color': i.color_principal,
                    'esta_limpia': CASE WHEN i.esta_limpia = 1 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
                ) AS JSON
            ) AS metadatos_json
        FROM inserted i
        LEFT JOIN dbo.MARCAS m ON i.marca_id = m.id
    ) AS Source
    ON (Target.tipo_origen = Source.tipo_origen AND Target.origen_id = Source.origen_id)
    WHEN MATCHED THEN
        UPDATE SET 
            Target.usuario_id = Source.usuario_id,
            Target.titulo = Source.titulo,
            Target.contenido_texto = Source.contenido_texto,
            Target.metadatos_json = Source.metadatos_json,
            Target.embedding = NULL,
            Target.updated_at = SYSDATETIME()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (usuario_id, tipo_origen, origen_id, titulo, contenido_texto, metadatos_json, embedding)
        VALUES (Source.usuario_id, Source.tipo_origen, Source.origen_id, Source.titulo, Source.contenido_texto, Source.metadatos_json, NULL);
END;
GO

-- SP: Registrar uso de outfit y guardar valoración transaccionalmente
CREATE OR ALTER PROCEDURE dbo.usp_RegistrarUsoYValoracionOutfit
    @OutfitID INT,
    @UsuarioID INT,
    @Puntuacion TINYINT,
    @Comentario NVARCHAR(1000),
    @MarcarPrendasSucias BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TranCounter INT = @@TRANCOUNT;
    DECLARE @Ahora DATETIME2 = SYSDATETIME();
    DECLARE @ValoracionID INT;

    BEGIN TRY
        IF @Puntuacion NOT BETWEEN 1 AND 5
        BEGIN
            ;THROW 50001, N'Error de validación: La puntuación debe estar comprendida entre 1 y 5.', 1;
        END;

        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.OUTFITS 
            WHERE id = @OutfitID AND usuario_id = @UsuarioID
        )
        BEGIN
            ;THROW 50002, N'Error de integridad/seguridad: El outfit indicado no existe o no pertenece al usuario especificado.', 1;
        END;

        IF NOT EXISTS (
            SELECT 1 
            FROM dbo.OUTFIT_PRENDA 
            WHERE outfit_id = @OutfitID
        )
        BEGIN
            ;THROW 50003, N'Error de negocio: El outfit no tiene prendas asociadas y no puede registrarse su uso.', 1;
        END;

        IF @TranCounter = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION Trn_RegistrarUsoOutfit;

        UPDATE dbo.OUTFITS
        SET fue_usado = 1,
            updated_at = @Ahora
        WHERE id = @OutfitID AND usuario_id = @UsuarioID;

        UPDATE p
        SET p.contador_usos = p.contador_usos + 1,
            p.fecha_ultimo_uso = @Ahora,
            p.esta_limpia = CASE WHEN @MarcarPrendasSucias = 1 THEN 0 ELSE p.esta_limpia END,
            p.fecha_ensuciado = CASE WHEN @MarcarPrendasSucias = 1 THEN @Ahora ELSE p.fecha_ensuciado END,
            p.updated_at = @Ahora
        FROM dbo.PRENDAS p
        INNER JOIN dbo.OUTFIT_PRENDA op ON p.id = op.prenda_id
        WHERE op.outfit_id = @OutfitID
          AND p.usuario_id = @UsuarioID;

        MERGE INTO dbo.VALORACIONES_OUTFIT AS Target
        USING (
            SELECT @OutfitID AS outfit_id, @UsuarioID AS usuario_id
        ) AS Source
        ON (Target.outfit_id = Source.outfit_id AND Target.usuario_id = Source.usuario_id)
        WHEN MATCHED THEN
            UPDATE SET 
                Target.puntuacion = @Puntuacion,
                Target.comentario = @Comentario,
                Target.created_at = @Ahora
        WHEN NOT MATCHED THEN
            INSERT (outfit_id, usuario_id, puntuacion, comentario, created_at)
            VALUES (@OutfitID, @UsuarioID, @Puntuacion, @Comentario, @Ahora);

        SELECT @ValoracionID = id 
        FROM dbo.VALORACIONES_OUTFIT 
        WHERE outfit_id = @OutfitID AND usuario_id = @UsuarioID;

        MERGE INTO dbo.DOCUMENTOS_BUSQUEDA AS Target
        USING (
            SELECT 
                v.usuario_id,
                N'VALORACION' AS tipo_origen,
                v.id AS origen_id,
                CONCAT(N'Valoración de ', o.nombre, N' (', v.puntuacion, N'/5 estrellas)') AS titulo,
                CONCAT(
                    N'Experiencia y valoración del outfit "', o.nombre, N'" usado en ocasión de ', ISNULL(oc.nombre, N'General'), N'. ',
                    N'Puntuación otorgada: ', v.puntuacion, N' sobre 5. ',
                    N'Prendas llevadas en esa ocasión: ', ISNULL(prendas_agg.lista_prendas, N''), N'. ',
                    N'Comentario de experiencia post-uso: ', ISNULL(v.comentario, N'')
                ) AS contenido_texto,
                CAST(
                    JSON_OBJECT(
                        'outfit_id': v.outfit_id,
                        'puntuacion': v.puntuacion
                    ) AS JSON
                ) AS metadatos_json
            FROM dbo.VALORACIONES_OUTFIT v
            INNER JOIN dbo.OUTFITS o ON v.outfit_id = o.id
            LEFT JOIN dbo.OCASIONES oc ON o.ocasion_id = oc.id
            OUTER APPLY (
                SELECT STRING_AGG(p.nombre, N', ') AS lista_prendas
                FROM dbo.OUTFIT_PRENDA op
                INNER JOIN dbo.PRENDAS p ON op.prenda_id = p.id
                WHERE op.outfit_id = o.id
            ) prendas_agg
            WHERE v.id = @ValoracionID
        ) AS Source
        ON (Target.tipo_origen = Source.tipo_origen AND Target.origen_id = Source.origen_id)
        WHEN MATCHED THEN
            UPDATE SET 
                Target.titulo = Source.titulo,
                Target.contenido_texto = Source.contenido_texto,
                Target.metadatos_json = Source.metadatos_json,
                Target.embedding = NULL,
                Target.updated_at = @Ahora
        WHEN NOT MATCHED THEN
            INSERT (usuario_id, tipo_origen, origen_id, titulo, contenido_texto, metadatos_json, embedding)
            VALUES (Source.usuario_id, Source.tipo_origen, Source.origen_id, Source.titulo, Source.contenido_texto, Source.metadatos_json, NULL);

        IF @TranCounter = 0
            COMMIT TRANSACTION;

        SELECT 
            N'OK' AS Estado,
            @OutfitID AS OutfitID,
            @ValoracionID AS ValoracionID,
            @Puntuacion AS PuntuacionRegistrada,
            @Ahora AS FechaProceso;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1
        BEGIN
            ROLLBACK TRANSACTION;
        END
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCounter = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION Trn_RegistrarUsoOutfit;
        END;

        ;THROW;
    END CATCH;
END;
GO

-- SP: Insertar nueva prenda con atributos en formato JSON nativo
CREATE OR ALTER PROCEDURE dbo.usp_AltaPrendaConAtributosJSON
    @UsuarioID INT,
    @MarcaID INT = NULL,
    @Nombre NVARCHAR(150),
    @Descripcion NVARCHAR(1000),
    @Talla NVARCHAR(20),
    @Categoria NVARCHAR(50),
    @ColorPrincipal NVARCHAR(50),
    @Temporada NVARCHAR(50),
    @Tejido NVARCHAR(100),
    @Corte NVARCHAR(100),
    @Estilo NVARCHAR(100),
    @Impermeable BIT = 0,
    @RequierePlancha BIT = 0,
    @PrecioCompra DECIMAL(10,2) = NULL,
    @NuevaPrendaID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TranCounter INT = @@TRANCOUNT;
    DECLARE @AtributosJSON JSON;

    BEGIN TRY
        IF @Talla IS NOT NULL AND NOT REGEXP_LIKE(@Talla, N'^(XS|S|M|L|XL|XXL|[3-5][0-9])$')
        BEGIN
            ;THROW 50010, N'Formato de talla inválido (REGEXP_LIKE). Use XS, S, M, L, XL, XXL o numeración entre 30 y 59.', 1;
        END;

        SET @AtributosJSON = CAST(
            JSON_OBJECT(
                'temporada': @Temporada,
                'tejido': @Tejido,
                'corte': @Corte,
                'estilo': @Estilo,
                'impermeable': @Impermeable,
                'requiere_plancha': @RequierePlancha
            ) AS JSON
        );

        IF @TranCounter = 0
            BEGIN TRANSACTION;
        ELSE
            SAVE TRANSACTION Trn_AltaPrenda;

        INSERT INTO dbo.PRENDAS (
            usuario_id, marca_id, nombre, descripcion, talla, 
            categoria, color_principal, atributos_json, precio_compra, esta_limpia
        )
        VALUES (
            @UsuarioID, @MarcaID, @Nombre, @Descripcion, @Talla, 
            @Categoria, @ColorPrincipal, @AtributosJSON, @PrecioCompra, 1
        );

        SET @NuevaPrendaID = SCOPE_IDENTITY();

        IF @TranCounter = 0
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1
            ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1
        BEGIN
            IF @TranCounter = 0
                ROLLBACK TRANSACTION;
            ELSE
                ROLLBACK TRANSACTION Trn_AltaPrenda;
        END;

        ;THROW;
    END CATCH;
END;
GO

-- Pruebas de verificación de los objetos de programabilidad
SELECT * FROM dbo.fn_BuscarMarcaAproximada(N'Zarra!!', 2);
SELECT * FROM dbo.fn_BuscarMarcaAproximada(N'Massimo Duti', 2);

EXEC dbo.usp_RegistrarUsoYValoracionOutfit
    @OutfitID = 3,
    @UsuarioID = 1,
    @Puntuacion = 5,
    @Comentario = N'La blusa de seda y el pantalón palazzo proyectaron una imagen impecable ante los clientes internacionales. El abrigo gris abrigó perfecto a primera hora.',
    @MarcarPrendasSucias = 0;

SELECT id, usuario_id, tipo_origen, origen_id, titulo, updated_at
FROM dbo.DOCUMENTOS_BUSQUEDA
WHERE tipo_origen = N'VALORACION' AND origen_id = 9;
GO