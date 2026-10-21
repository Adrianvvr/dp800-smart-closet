-- Optimización de consultas e índices

USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Limpieza previa de índices secundarios
DROP INDEX IF EXISTS IX_PRENDAS_Usuario_Categoria_Limpia ON dbo.PRENDAS;
DROP INDEX IF EXISTS IX_PRENDAS_AtributosJSON ON dbo.PRENDAS;
DROP INDEX IF EXISTS IX_OUTFITS_Usuario_Ocasion ON dbo.OUTFITS;
DROP INDEX IF EXISTS IX_VALORACIONES_Usuario_Puntuacion ON dbo.VALORACIONES_OUTFIT;
DROP INDEX IF EXISTS IX_DOCUMENTOS_Usuario_Tipo ON dbo.DOCUMENTOS_BUSQUEDA;
GO

-- Generación de volumen para pruebas de rendimiento
ALTER TABLE dbo.PRENDAS DISABLE TRIGGER trg_SincronizarChunkPrenda;

SET IDENTITY_INSERT dbo.PRENDAS ON;

;WITH CTE_Numeros AS (
    SELECT TOP (2000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + 1000 AS n
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
)
INSERT INTO dbo.PRENDAS (
    id, usuario_id, marca_id, nombre, descripcion, talla, categoria, 
    color_principal, atributos_json, precio_compra, esta_limpia, contador_usos
)
SELECT 
    n,
    ((n % 4) + 1) AS usuario_id,
    ((n % 12) + 1) AS marca_id,
    CONCAT(N'Prenda histórica archivo #', n),
    REPLICATE(N'Prenda de archivo almacenada fuera de temporada para pruebas de volumen y lectura de páginas en disco. ', 4),
    N'M',
    CASE (n % 4) 
        WHEN 0 THEN N'Pantalón' 
        WHEN 1 THEN N'Camisa' 
        WHEN 2 THEN N'Chaqueta' 
        ELSE N'Calzado' 
    END,
    N'Gris',
    CAST(N'{"temporada": "Invierno", "tejido": "Algodón", "impermeable": false}' AS JSON),
    45.00,
    0 AS esta_limpia,
    1
FROM CTE_Numeros;

SET IDENTITY_INSERT dbo.PRENDAS OFF;
GO

UPDATE STATISTICS dbo.PRENDAS WITH FULLSCAN;
GO

-- Rendimiento sin índices
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

SET STATISTICS IO, TIME ON;

SELECT 
    p.id,
    p.nombre,
    p.color_principal,
    p.precio_compra,
    p.contador_usos
FROM dbo.PRENDAS p
WHERE p.usuario_id = 1
  AND p.categoria = N'Pantalón'
  AND p.esta_limpia = 1
ORDER BY p.contador_usos DESC;

SET STATISTICS IO, TIME OFF;
GO

-- Índices optimizados: cubrientes, filtrados y JSON
CREATE NONCLUSTERED INDEX IX_PRENDAS_Usuario_Categoria_Covering
ON SmartClosetAI.dbo.PRENDAS (usuario_id, categoria)
INCLUDE (nombre, descripcion);

CREATE NONCLUSTERED INDEX IX_PRENDAS_Usuario_Categoria_Limpia
ON dbo.PRENDAS (usuario_id ASC, categoria ASC, contador_usos DESC)
INCLUDE (nombre, color_principal, precio_compra, marca_id)
WHERE esta_limpia = 1;
GO

CREATE JSON INDEX IX_PRENDAS_AtributosJSON
ON dbo.PRENDAS (atributos_json)
FOR ('$');
GO

-- Índices de soporte para JOINs y RLS
CREATE NONCLUSTERED INDEX IX_OUTFITS_Usuario_Ocasion
ON dbo.OUTFITS (usuario_id ASC, ocasion_id ASC)
INCLUDE (nombre, fecha_planificada, fue_usado);

CREATE NONCLUSTERED INDEX IX_VALORACIONES_Usuario_Puntuacion
ON dbo.VALORACIONES_OUTFIT (usuario_id ASC, outfit_id ASC)
INCLUDE (puntuacion, comentario);

CREATE NONCLUSTERED INDEX IX_DOCUMENTOS_Usuario_Tipo
ON dbo.DOCUMENTOS_BUSQUEDA (usuario_id ASC, tipo_origen ASC)
INCLUDE (origen_id, titulo);
GO

-- Rendimiento tras aplicar índices
DBCC DROPCLEANBUFFERS WITH NO_INFOMSGS;

SET STATISTICS IO, TIME ON;

SELECT 
    p.id,
    p.nombre,
    p.color_principal,
    p.precio_compra,
    p.contador_usos
FROM dbo.PRENDAS p
WHERE p.usuario_id = 1
  AND p.categoria = N'Pantalón'
  AND p.esta_limpia = 1
ORDER BY p.contador_usos DESC;

SET STATISTICS IO, TIME OFF;
GO

-- Limpieza de datos de prueba temporales
DELETE FROM dbo.PRENDAS WHERE id >= 1000;

DBCC CHECKIDENT ('dbo.PRENDAS', RESEED, 26) WITH NO_INFOMSGS;

ALTER TABLE dbo.PRENDAS ENABLE TRIGGER trg_SincronizarChunkPrenda;
GO

-- Verificación de índices creados
SELECT 
    OBJECT_NAME(i.object_id) AS Tabla,
    i.name AS NombreIndice,
    i.type_desc AS TipoIndice,
    i.has_filter AS EsFiltrado,
    i.filter_definition AS FiltroAplicado
FROM sys.indexes i
WHERE OBJECT_SCHEMA_NAME(i.object_id) = 'dbo'
  AND i.name IS NOT NULL
ORDER BY Tabla, i.index_id;
GO