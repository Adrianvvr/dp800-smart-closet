-- Implementación RAG: Búsqueda vectorial, construcción de contexto e invocación al LLM

USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Procedimiento principal de RAG
CREATE OR ALTER PROCEDURE dbo.usp_ConsultarEstilistaRAG
    @PreguntaUsuario NVARCHAR(500),
    @UsuarioID INT = 1,
    @TopK INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    -- Fijar contexto de usuario (RLS)
    EXEC sp_set_session_context @key = N'usuario_id', @value = @UsuarioID;

    -- Generar embedding de la pregunta
    DECLARE @VectorConsulta VECTOR(768);
    SET @VectorConsulta = CAST(
        AI_GENERATE_EMBEDDINGS(@PreguntaUsuario USE MODEL ModeloEmbeddingsOllama)
        AS VECTOR(768)
    );

    -- Recuperar top K chunks por distancia coseno
    DECLARE @ContextoRecuperado NVARCHAR(MAX);

    ;WITH CTE_TopChunks AS (
        SELECT TOP (@TopK)
            d.id,
            d.titulo,
            d.contenido_texto,
            VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) AS distancia
        FROM dbo.DOCUMENTOS_BUSQUEDA d
        WHERE d.embedding IS NOT NULL
          AND d.usuario_id = @UsuarioID
        ORDER BY VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) ASC
    )
    SELECT @ContextoRecuperado = STRING_AGG(
        CONCAT(N'[- Documento: ', titulo, N' | Detalles: ', contenido_texto, N']'),
        CHAR(13) + CHAR(10)
    )
    FROM CTE_TopChunks;

    -- Construir el prompt con el contexto recuperado (Grounding)
    DECLARE @SystemPrompt NVARCHAR(MAX) = N'Eres un estilista personal inteligente que aconseja al usuario basándote EXCLUSIVAMENTE en las prendas, outfits y experiencias previas de su armario que se proporcionan en el contexto. Responde en español, de forma concisa, educada y justificando tu recomendación con los detalles del contexto (tejidos, comodidad y comentarios previos). No inventes prendas que no aparezcan en el contexto.';
    
    DECLARE @UserPrompt NVARCHAR(MAX) = CONCAT(
        N'CONTEXTO DEL ARMARIO Y EXPERIENCIAS RECUPERADAS:', CHAR(13), CHAR(10),
        @ContextoRecuperado, CHAR(13), CHAR(10), CHAR(13), CHAR(10),
        N'PREGUNTA DEL USUARIO: ', @PreguntaUsuario
    );

    -- Preparar payload JSON para Ollama
    DECLARE @Payload NVARCHAR(MAX) = JSON_OBJECT(
        'model': 'llama3.2:3b',
        'system': @SystemPrompt,
        'prompt': @UserPrompt,
        'stream': CAST(0 AS BIT)
    );

    -- Invocar LLM local a través del proxy
    DECLARE @Status INT;
    DECLARE @Response NVARCHAR(MAX);

    EXEC @Status = sp_invoke_external_rest_endpoint
        @method = N'POST',
        @url = N'https://localhost:11435/api/generate',
        @payload = @Payload,
        @response = @Response OUTPUT;

    -- Extraer respuesta del LLM
    DECLARE @RespuestaLLM NVARCHAR(MAX);

    IF @Status = 0
    BEGIN
        SET @RespuestaLLM = JSON_VALUE(@Response, '$.result.response');
    END
    ELSE
    BEGIN
        SET @RespuestaLLM = CONCAT(N'Error en la invocación al LLM. Código de estado: ', @Status, N'. Detalle: ', @Response);
    END;

    -- Devolver los chunks recuperados
    SELECT 
        ROW_NUMBER() OVER (ORDER BY VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) ASC) AS Ranking,
        d.id AS DocumentoID,
        d.titulo AS Titulo,
        CAST((1.0 - VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta)) * 100.0 AS DECIMAL(5,2)) AS SimilitudPct,
        d.contenido_texto AS ChunkRecuperado
    FROM dbo.DOCUMENTOS_BUSQUEDA d
    WHERE d.embedding IS NOT NULL
      AND d.usuario_id = @UsuarioID
    ORDER BY VECTOR_DISTANCE('cosine', d.embedding, @VectorConsulta) ASC
    OFFSET 0 ROWS FETCH NEXT @TopK ROWS ONLY;

    -- Devolver la respuesta final generada
    SELECT 
        @PreguntaUsuario AS [1_PreguntaUsuario],
        @ContextoRecuperado AS [2_ContextoArmadoParaLLM],
        @RespuestaLLM AS [3_RespuestaEstilistaRAG];
END;
GO

-- Conceder permisos de ejecución
GRANT EXECUTE ON dbo.usp_ConsultarEstilistaRAG TO rol_UsuarioApp;
GO

-- Prueba del pipeline RAG
EXEC dbo.usp_ConsultarEstilistaRAG
    @PreguntaUsuario = N'¿Qué conjunto me recomiendas para una boda al mediodía con mucho calor en el campo?',
    @UsuarioID = 1,
    @TopK = 3;
GO