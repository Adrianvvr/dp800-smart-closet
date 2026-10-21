-- Configuración del modelo de embeddings local (Ollama + Caddy)
-- Prerrequisitos: Ollama (11434), Caddy HTTPS (11435) y certificado raíz importado.

USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Habilitar endpoints REST externos y características en Preview
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
GO

EXEC sp_configure 'external rest endpoint enabled', 1;
RECONFIGURE WITH OVERRIDE;
GO

ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

-- Registrar el modelo externo apuntando al proxy HTTPS
IF EXISTS (SELECT 1 FROM sys.external_models WHERE name = 'ModeloEmbeddingsOllama')
BEGIN
    DROP EXTERNAL MODEL ModeloEmbeddingsOllama;
END;
GO

CREATE EXTERNAL MODEL ModeloEmbeddingsOllama
WITH (
    LOCATION = 'https://localhost:11435/api/embed',
    API_FORMAT = 'Ollama',
    MODEL_TYPE = EMBEDDINGS,
    MODEL = 'nomic-embed-text'
);
GO

-- Verificación del modelo creado
SELECT 
    external_model_id AS ModeloID,
    name AS NombreModeloSQL,
    location AS EndpointLocalHTTPS,
    api_format AS FormatoAPI,
    model_type_desc AS TipoModelo,
    model AS ModeloOllama
FROM sys.external_models
WHERE name = 'ModeloEmbeddingsOllama';
GO