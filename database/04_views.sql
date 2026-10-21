USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Vista de Inventario: Expone atributos JSON y calcula Coste por Uso
CREATE OR ALTER VIEW dbo.vw_InventarioPrendasJSON
AS
SELECT 
    p.id AS prenda_id,
    p.usuario_id,
    u.name AS propietario,
    p.nombre AS prenda,
    ISNULL(m.nombre, N'Sin marca') AS marca,
    p.categoria,
    p.color_principal,
    p.talla,
    JSON_VALUE(p.atributos_json, '$.temporada') AS temporada,
    JSON_VALUE(p.atributos_json, '$.tejido') AS tejido,
    JSON_VALUE(p.atributos_json, '$.corte') AS corte,
    JSON_VALUE(p.atributos_json, '$.estilo') AS estilo,
    CAST(JSON_VALUE(p.atributos_json, '$.impermeable') AS BIT) AS es_impermeable,
    CAST(JSON_VALUE(p.atributos_json, '$.requiere_plancha') AS BIT) AS requiere_plancha,
    p.esta_limpia,
    p.contador_usos,
    p.precio_compra,
    CAST(p.precio_compra / NULLIF(p.contador_usos, 0) AS DECIMAL(10,2)) AS coste_por_uso,
    p.fecha_ultimo_uso,
    p.descripcion
FROM dbo.PRENDAS p
INNER JOIN dbo.USUARIOS u ON p.usuario_id = u.id
LEFT JOIN dbo.MARCAS m ON p.marca_id = m.id;
GO

-- Analítica Armario: Métricas y rotación mediante CTE y Window Functions
CREATE OR ALTER VIEW dbo.vw_AnaliticaArmarioUsuario
AS
WITH CTE_MetricasBase AS (
    SELECT 
        p.id AS prenda_id,
        p.usuario_id,
        u.name AS propietario,
        p.nombre AS prenda,
        p.categoria,
        JSON_VALUE(p.atributos_json, '$.temporada') AS temporada,
        p.precio_compra,
        p.contador_usos,
        p.esta_limpia
    FROM dbo.PRENDAS p
    INNER JOIN dbo.USUARIOS u ON p.usuario_id = u.id
)
SELECT 
    prenda_id,
    usuario_id,
    propietario,
    prenda,
    categoria,
    temporada,
    precio_compra,
    contador_usos,
    DENSE_RANK() OVER (PARTITION BY usuario_id ORDER BY contador_usos DESC) AS ranking_uso_usuario,
    ROW_NUMBER() OVER (PARTITION BY usuario_id, categoria ORDER BY contador_usos DESC, precio_compra DESC) AS ranking_en_categoria,
    CAST((contador_usos * 100.0) / NULLIF(SUM(contador_usos) OVER (PARTITION BY usuario_id), 0) AS DECIMAL(5,2)) AS porcentaje_uso_armario,
    CAST(AVG(precio_compra) OVER (PARTITION BY usuario_id) AS DECIMAL(10,2)) AS precio_medio_usuario,
    CAST(precio_compra - AVG(precio_compra) OVER (PARTITION BY usuario_id) AS DECIMAL(10,2)) AS diferencia_vs_media
FROM CTE_MetricasBase;
GO

-- Resumen de Outfits: Estado actual de prendas, valoraciones y agregación (STRING_AGG)
CREATE OR ALTER VIEW dbo.vw_ResumenOutfitsExperiencias
AS
SELECT 
    o.id AS outfit_id,
    o.usuario_id,
    u.name AS propietario,
    o.nombre AS nombre_outfit,
    ISNULL(oc.nombre, N'Sin ocasión') AS ocasion,
    oc.nivel_formalidad,
    o.fecha_planificada,
    o.fue_usado,
    (SELECT COUNT(*) FROM dbo.OUTFIT_PRENDA op WHERE op.outfit_id = o.id) AS total_prendas,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM dbo.OUTFIT_PRENDA op
            INNER JOIN dbo.PRENDAS p ON op.prenda_id = p.id
            WHERE op.outfit_id = o.id AND p.esta_limpia = 0
        ) THEN CAST(0 AS BIT)
        ELSE CAST(1 AS BIT)
    END AS disponible_limpio_hoy,
    prendas_lista.detalle_prendas,
    o.notas AS notas_planificacion,
    v.puntuacion AS valoracion_estrellas,
    v.comentario AS comentario_experiencia
FROM dbo.OUTFITS o
INNER JOIN dbo.USUARIOS u ON o.usuario_id = u.id
LEFT JOIN dbo.OCASIONES oc ON o.ocasion_id = oc.id
LEFT JOIN dbo.VALORACIONES_OUTFIT v ON o.id = v.outfit_id AND o.usuario_id = v.usuario_id
OUTER APPLY (
    SELECT STRING_AGG(CONCAT(p.nombre, N' (', p.color_principal, N')'), N' + ') AS detalle_prendas
    FROM dbo.OUTFIT_PRENDA op
    INNER JOIN dbo.PRENDAS p ON op.prenda_id = p.id
    WHERE op.outfit_id = o.id
) prendas_lista;
GO

-- Pruebas de las vistas generadas

SELECT prenda_id, propietario, prenda, marca, temporada, tejido, estilo, es_impermeable, coste_por_uso
FROM dbo.vw_InventarioPrendasJSON
WHERE es_impermeable = 1;

SELECT propietario, ranking_uso_usuario, prenda, categoria, contador_usos, porcentaje_uso_armario, diferencia_vs_media
FROM dbo.vw_AnaliticaArmarioUsuario
WHERE ranking_uso_usuario <= 3
ORDER BY usuario_id, ranking_uso_usuario;

SELECT outfit_id, propietario, nombre_outfit, ocasion, total_prendas, disponible_limpio_hoy, valoracion_estrellas, detalle_prendas
FROM dbo.vw_ResumenOutfitsExperiencias;
GO