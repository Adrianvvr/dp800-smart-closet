-- Implementación Seguridad Bloque C (SQL Server 2025)

USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Limpieza idempotente de objetos de seguridad previos
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'Pol_AislamientoArmarioUsuario')
BEGIN
    ALTER SECURITY POLICY sec.Pol_AislamientoArmarioUsuario WITH (STATE = OFF);
    DROP SECURITY POLICY sec.Pol_AislamientoArmarioUsuario;
END;
GO

DROP FUNCTION IF EXISTS sec.fn_PredicadoSeguridadUsuario;
GO

IF SCHEMA_ID('sec') IS NOT NULL
    DROP SCHEMA sec;
GO

-- Quitar máscaras previas en caso de reejecución
IF EXISTS (SELECT 1 FROM sys.masked_columns WHERE object_id = OBJECT_ID('dbo.USUARIOS') AND name = 'email')
    ALTER TABLE dbo.USUARIOS ALTER COLUMN email DROP MASKED;

IF EXISTS (SELECT 1 FROM sys.masked_columns WHERE object_id = OBJECT_ID('dbo.USUARIOS') AND name = 'remember_token')
    ALTER TABLE dbo.USUARIOS ALTER COLUMN remember_token DROP MASKED;
GO

-- Eliminar usuarios de prueba y roles previos
DROP USER IF EXISTS usr_lucia;
DROP USER IF EXISTS usr_carlos;
DROP USER IF EXISTS usr_elena;
DROP USER IF EXISTS usr_mateo;
DROP USER IF EXISTS usr_auditor;
DROP ROLE IF EXISTS rol_UsuarioApp;
DROP ROLE IF EXISTS rol_AuditorSoporte;
GO

-- Creación de roles y usuarios (sin logins ni contraseñas)
CREATE ROLE rol_UsuarioApp;
CREATE ROLE rol_AuditorSoporte;
GO

-- Usuarios mapeados
CREATE USER usr_lucia   WITHOUT LOGIN; 
CREATE USER usr_carlos  WITHOUT LOGIN; 
CREATE USER usr_elena   WITHOUT LOGIN; 
CREATE USER usr_mateo   WITHOUT LOGIN; 
CREATE USER usr_auditor WITHOUT LOGIN; 
GO

ALTER ROLE rol_UsuarioApp ADD MEMBER usr_lucia;
ALTER ROLE rol_UsuarioApp ADD MEMBER usr_carlos;
ALTER ROLE rol_UsuarioApp ADD MEMBER usr_elena;
ALTER ROLE rol_UsuarioApp ADD MEMBER usr_mateo;

ALTER ROLE rol_AuditorSoporte ADD MEMBER usr_auditor;
GO

-- Principio de Mínimo Privilegio (GRANT / DENY)

-- Permisos para rol_UsuarioApp
GRANT SELECT ON dbo.MARCAS TO rol_UsuarioApp;
GRANT SELECT ON dbo.OCASIONES TO rol_UsuarioApp;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.PRENDAS TO rol_UsuarioApp;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.OUTFITS TO rol_UsuarioApp;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.OUTFIT_PRENDA TO rol_UsuarioApp;
GRANT SELECT, INSERT, UPDATE ON dbo.VALORACIONES_OUTFIT TO rol_UsuarioApp;
GRANT SELECT ON dbo.DOCUMENTOS_BUSQUEDA TO rol_UsuarioApp;

GRANT SELECT ON dbo.vw_InventarioPrendasJSON TO rol_UsuarioApp;
GRANT SELECT ON dbo.vw_AnaliticaArmarioUsuario TO rol_UsuarioApp;
GRANT SELECT ON dbo.vw_ResumenOutfitsExperiencias TO rol_UsuarioApp;
GRANT SELECT ON dbo.fn_BuscarMarcaAproximada TO rol_UsuarioApp;
GRANT EXECUTE ON dbo.usp_RegistrarUsoYValoracionOutfit TO rol_UsuarioApp;
GRANT EXECUTE ON dbo.usp_AltaPrendaConAtributosJSON TO rol_UsuarioApp;

-- Restricción estricta sobre tabla USUARIOS
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.USUARIOS TO rol_UsuarioApp;

-- Permisos para rol_AuditorSoporte
GRANT SELECT ON SCHEMA::dbo TO rol_AuditorSoporte;

-- Ocultar campos sensibles incluso al auditor
DENY SELECT ON dbo.USUARIOS (password, remember_token) TO rol_AuditorSoporte;

REVOKE UNMASK FROM rol_UsuarioApp;
REVOKE UNMASK FROM rol_AuditorSoporte;
GO

-- Dynamic Data Masking (DDM) en emails y tokens
ALTER TABLE dbo.USUARIOS 
ALTER COLUMN email ADD MASKED WITH (FUNCTION = 'email()');

ALTER TABLE dbo.USUARIOS 
ALTER COLUMN remember_token ADD MASKED WITH (FUNCTION = 'default()');
GO

-- Row-Level Security (RLS): Aislamiento multi-tenant
CREATE SCHEMA sec;
GO

-- Predicado de seguridad
CREATE OR ALTER FUNCTION sec.fn_PredicadoSeguridadUsuario(@usuario_id INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS acceso_permitido
    WHERE 
        IS_MEMBER('db_owner') = 1 
        OR IS_ROLEMEMBER('rol_AuditorSoporte') = 1
        OR CAST(SESSION_CONTEXT(N'usuario_id') AS INT) = @usuario_id
        OR (USER_NAME() = N'usr_lucia'  AND @usuario_id = 1)
        OR (USER_NAME() = N'usr_carlos' AND @usuario_id = 2)
        OR (USER_NAME() = N'usr_elena'  AND @usuario_id = 3)
        OR (USER_NAME() = N'usr_mateo'  AND @usuario_id = 4);
GO

-- Directiva de Seguridad RLS
CREATE SECURITY POLICY sec.Pol_AislamientoArmarioUsuario
    ADD FILTER PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.PRENDAS,
    ADD BLOCK  PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.PRENDAS AFTER INSERT,
    ADD BLOCK  PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.PRENDAS AFTER UPDATE,

    ADD FILTER PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.OUTFITS,
    ADD BLOCK  PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.OUTFITS AFTER INSERT,
    ADD BLOCK  PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.OUTFITS AFTER UPDATE,

    ADD FILTER PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.VALORACIONES_OUTFIT,
    ADD BLOCK  PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.VALORACIONES_OUTFIT AFTER INSERT,

    ADD FILTER PREDICATE sec.fn_PredicadoSeguridadUsuario(usuario_id) ON dbo.DOCUMENTOS_BUSQUEDA
WITH (STATE = ON);
GO

-- Pruebas de demostración RLS y DDM

-- Prueba usr_lucia (Solo debe ver lo suyo)
EXECUTE AS USER = 'usr_lucia';
    SELECT 
        USER_NAME() AS UsuarioConectado,
        COUNT(*) AS PrendasVisibles,
        (SELECT COUNT(*) FROM dbo.DOCUMENTOS_BUSQUEDA) AS ChunksIAVisibles
    FROM dbo.PRENDAS;

    SELECT id, usuario_id, nombre, categoria, color_principal 
    FROM dbo.PRENDAS;
REVERT;

-- Prueba usr_carlos (Solo debe ver lo suyo)
EXECUTE AS USER = 'usr_carlos';
    SELECT 
        USER_NAME() AS UsuarioConectado,
        COUNT(*) AS PrendasVisibles,
        (SELECT COUNT(*) FROM dbo.DOCUMENTOS_BUSQUEDA) AS ChunksIAVisibles
    FROM dbo.PRENDAS;

    SELECT id, usuario_id, nombre, categoria, color_principal 
    FROM dbo.PRENDAS;
REVERT;

-- Prueba usr_auditor (Visibilidad global + Email enmascarado)
EXECUTE AS USER = 'usr_auditor';
    SELECT 
        USER_NAME() AS UsuarioConectado,
        COUNT(*) AS TotalPrendasAuditadas 
    FROM dbo.PRENDAS;

    SELECT id, name, email, created_at 
    FROM dbo.USUARIOS;
REVERT;
GO