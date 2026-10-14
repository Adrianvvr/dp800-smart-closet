-- =============================================================================
-- PROYECTO: Armario Inteligente DP-800
-- FASE 1: Esquema Relacional de Origen ("Antes") - Versión Ajustada
-- ARCHIVO: database/01_schema_base.sql
-- DESCRIPCIÓN: DDL transaccional base con integridad
-- =============================================================================

IF DB_ID('ArmarioDB') IS NULL
BEGIN
    CREATE DATABASE SmartCloset;
END;
GO

USE SmartCloset;
GO

-- Limpieza en orden inverso de dependencias
DROP TABLE IF EXISTS VALORACIONES_OUTFIT;
DROP TABLE IF EXISTS OUTFIT_PRENDA;
DROP TABLE IF EXISTS OUTFITS;
DROP TABLE IF EXISTS PRENDAS;
DROP TABLE IF EXISTS OCASIONES;
DROP TABLE IF EXISTS MARCAS;
DROP TABLE IF EXISTS USUARIOS;
GO

-- 1. Tabla USUARIOS
CREATE TABLE USUARIOS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(150) NOT NULL UNIQUE,
    email_verified_at DATETIME2 NULL,
    password NVARCHAR(255) NOT NULL,
    remember_token NVARCHAR(100) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

-- 2. Tabla MARCAS (se elimina la redundancia de enlace / sitio_web)
CREATE TABLE MARCAS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL UNIQUE,
    sitio_web NVARCHAR(255) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

-- 3. Tabla OCASIONES
CREATE TABLE OCASIONES (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL UNIQUE,
    descripcion NVARCHAR(255) NULL,
    nivel_formalidad TINYINT NOT NULL CHECK (nivel_formalidad BETWEEN 1 AND 5)
);
GO

-- 4. Tabla PRENDAS
CREATE TABLE PRENDAS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    marca_id INT NULL,
    nombre NVARCHAR(150) NOT NULL,
    descripcion NVARCHAR(1000) NULL,
    talla NVARCHAR(20) NULL,
    temporada NVARCHAR(50) NULL,
    categoria NVARCHAR(50) NOT NULL,
    color_principal NVARCHAR(50) NOT NULL,
    precio_compra DECIMAL(10,2) NULL,
    foto_url NVARCHAR(500) NULL,
    esta_limpia BIT NOT NULL DEFAULT 1,
    fecha_ensuciado DATETIME2 NULL,
    fecha_ultimo_uso DATETIME2 NULL,
    contador_usos INT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_PRENDAS_USUARIOS FOREIGN KEY (usuario_id) REFERENCES USUARIOS(id),
    CONSTRAINT FK_PRENDAS_MARCAS FOREIGN KEY (marca_id) REFERENCES MARCAS(id)
);
GO

-- 5. Tabla OUTFITS
CREATE TABLE OUTFITS (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    ocasion_id INT NULL,
    nombre NVARCHAR(150) NOT NULL,
    notas NVARCHAR(1000) NULL,
    fecha_planificada DATE NULL,
    fue_usado BIT NOT NULL DEFAULT 0,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_OUTFITS_USUARIOS FOREIGN KEY (usuario_id) REFERENCES USUARIOS(id),
    CONSTRAINT FK_OUTFITS_OCASIONES FOREIGN KEY (ocasion_id) REFERENCES OCASIONES(id)
);
GO

-- 6. Tabla intermedia OUTFIT_PRENDA (con borrado en cascada en ambos extremos)
CREATE TABLE OUTFIT_PRENDA (
    outfit_id INT NOT NULL,
    prenda_id INT NOT NULL,
    PRIMARY KEY (outfit_id, prenda_id),
    CONSTRAINT FK_OUTFIT_PRENDA_OUTFITS FOREIGN KEY (outfit_id) REFERENCES OUTFITS(id) ON DELETE CASCADE,
    CONSTRAINT FK_OUTFIT_PRENDA_PRENDAS FOREIGN KEY (prenda_id) REFERENCES PRENDAS(id) ON DELETE CASCADE
);
GO

-- 7. Tabla VALORACIONES_OUTFIT (con restricción de unicidad)
CREATE TABLE VALORACIONES_OUTFIT (
    id INT IDENTITY(1,1) PRIMARY KEY,
    outfit_id INT NOT NULL,
    usuario_id INT NOT NULL,
    puntuacion TINYINT NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario NVARCHAR(1000) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_VALORACIONES_OUTFITS FOREIGN KEY (outfit_id) REFERENCES OUTFITS(id) ON DELETE CASCADE,
    CONSTRAINT FK_VALORACIONES_USUARIOS FOREIGN KEY (usuario_id) REFERENCES USUARIOS(id),
    CONSTRAINT UQ_VALORACION_USUARIO_OUTFIT UNIQUE (outfit_id, usuario_id)
);
GO