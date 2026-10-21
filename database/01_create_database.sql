USE master;
GO

-- Si la base de datos existe, cerramos conexiones activas y la recreamos limpia
IF DB_ID('SmartClosetAI') IS NOT NULL
BEGIN
    ALTER DATABASE SmartClosetAI SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE SmartClosetAI;
END;
GO

CREATE DATABASE SmartClosetAI;
GO

-- Asegurar nivel de compatibilidad 170 para soporte de VECTOR y JSON nativo
ALTER DATABASE SmartClosetAI SET COMPATIBILITY_LEVEL = 170;
GO

USE SmartClosetAI;
GO

-- Comprobación final
SELECT 
    name AS BaseDeDatos, 
    compatibility_level AS NivelCompatibilidad, 
    collation_name AS Intercalacion
FROM sys.databases 
WHERE name = 'SmartClosetAI';
GO