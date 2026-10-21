-- Generación de embeddings y mantenimiento de vectores (Bloque E)

USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Prueba unitaria rápida del modelo externo
SELECT 
    SUBSTRING(
        CAST(
            AI_GENERATE_EMBEDDINGS(
                N'Vestido fresco de lino para boda en verano' USE MODEL ModeloEmbeddingsOllama
            ) AS VARCHAR(MAX)
        ), 1, 80
    ) + '...' AS MuestraVectorPruebaUnitaria;
GO

-- SP: Vectorizar únicamente chunks nuevos o modificados (embedding NULL)
CREATE OR ALTER PROCEDURE dbo.usp_SincronizarEmbeddingsPendientes
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @FilasPendientes INT;
    SELECT @FilasPendientes = COUNT(*) 
    FROM dbo.DOCUMENTOS_BUSQUEDA 
    WHERE embedding IS NULL;

    IF @FilasPendientes > 0
    BEGIN
        UPDATE dbo.DOCUMENTOS_BUSQUEDA
        SET embedding = CAST(
            AI_GENERATE_EMBEDDINGS(contenido_texto USE MODEL ModeloEmbeddingsOllama)
            AS VECTOR(768)
        ),
        updated_at = SYSDATETIME()
        WHERE embedding IS NULL;
    END;

    SELECT 
        @FilasPendientes AS ChunksProcesadosEnEstaEjecucion,
        (SELECT COUNT(*) FROM dbo.DOCUMENTOS_BUSQUEDA WHERE embedding IS NOT NULL) AS TotalChunksConVector,
        (SELECT COUNT(*) FROM dbo.DOCUMENTOS_BUSQUEDA WHERE embedding IS NULL) AS TotalChunksPendientes;
END;
GO

GRANT EXECUTE ON dbo.usp_SincronizarEmbeddingsPendientes TO rol_UsuarioApp;
GO

-- Ejecutar vectorización
EXEC dbo.usp_SincronizarEmbeddingsPendientes;
GO

-- Verificar completitud y muestra de vectores generados
SELECT 
    tipo_origen,
    COUNT(*) AS TotalChunks,
    SUM(CASE WHEN embedding IS NOT NULL THEN 1 ELSE 0 END) AS ChunksConVector768,
    SUM(CASE WHEN embedding IS NULL THEN 1 ELSE 0 END) AS ChunksSinEmbedding
FROM dbo.DOCUMENTOS_BUSQUEDA
GROUP BY tipo_origen;

SELECT TOP 5
    id,
    usuario_id,
    tipo_origen,
    titulo,
    SUBSTRING(CAST(embedding AS VARCHAR(MAX)), 1, 65) + '...' AS MuestraVector768,
    updated_at
FROM dbo.DOCUMENTOS_BUSQUEDA
ORDER BY id;
GO