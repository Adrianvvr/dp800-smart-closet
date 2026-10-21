-- Crear la base de datos si no existe
IF DB_ID('SmartCloset') IS NULL
BEGIN
    CREATE DATABASE SmartCloset;
END;
GO

USE SmartCloset;
GO

SET NOCOUNT ON;
GO

-- Limpiar el esquema previo
DROP TABLE IF EXISTS VALORACIONES_OUTFIT;
DROP TABLE IF EXISTS OUTFIT_PRENDA;
DROP TABLE IF EXISTS OUTFITS;
DROP TABLE IF EXISTS PRENDAS;
DROP TABLE IF EXISTS OCASIONES;
DROP TABLE IF EXISTS MARCAS;
DROP TABLE IF EXISTS USUARIOS;
GO

-- Creación de tablas

-- Usuarios
CREATE TABLE USUARIOS (
    id INT PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(150) NOT NULL UNIQUE,
    email_verified_at DATETIME2 NULL,
    password NVARCHAR(255) NOT NULL,
    remember_token NVARCHAR(100) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

-- Marcas
CREATE TABLE MARCAS (
    id INT PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL UNIQUE,
    sitio_web NVARCHAR(255) NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

-- Ocasiones
CREATE TABLE OCASIONES (
    id INT PRIMARY KEY,
    nombre NVARCHAR(50) NOT NULL UNIQUE,
    descripcion NVARCHAR(255) NULL,
    nivel_formalidad TINYINT NOT NULL CHECK (nivel_formalidad BETWEEN 1 AND 5)
);
GO

-- Prendas
CREATE TABLE PRENDAS (
    id INT PRIMARY KEY,
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

-- Outfits
CREATE TABLE OUTFITS (
    id INT PRIMARY KEY,
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

-- Relación Outfits - Prendas
CREATE TABLE OUTFIT_PRENDA (
    outfit_id INT NOT NULL,
    prenda_id INT NOT NULL,
    PRIMARY KEY (outfit_id, prenda_id),
    CONSTRAINT FK_OUTFIT_PRENDA_OUTFITS FOREIGN KEY (outfit_id) REFERENCES OUTFITS(id) ON DELETE CASCADE,
    CONSTRAINT FK_OUTFIT_PRENDA_PRENDAS FOREIGN KEY (prenda_id) REFERENCES PRENDAS(id) ON DELETE CASCADE
);
GO

-- Valoraciones
CREATE TABLE VALORACIONES_OUTFIT (
    id INT PRIMARY KEY,
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

-- Inserción de datos iniciales

-- Usuarios
INSERT INTO USUARIOS (id, name, email, email_verified_at, password, remember_token, created_at, updated_at) VALUES
(1, N'Lucía Martín Gómez', N'lucia.martin@smartcloset.es', '2026-01-10 09:15:00', N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'tok_lucia_01a9b', '2026-01-10 09:00:00', '2026-01-10 09:15:00'),
(2, N'Carlos Gómez Navarro', N'carlos.gomez@smartcloset.es', '2026-01-12 18:30:00', N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'tok_carlos_88f2c', '2026-01-12 18:20:00', '2026-01-12 18:30:00'),
(3, N'Elena Rostova Vega', N'elena.rostova@smartcloset.es', '2026-02-01 11:05:00', N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, '2026-02-01 11:00:00', '2026-02-01 11:05:00'),
(4, N'Mateo Silva Mendoza', N'mateo.silva@smartcloset.es', NULL, N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, '2026-02-15 20:45:00', '2026-02-15 20:45:00');
GO

-- Marcas
INSERT INTO MARCAS (id, nombre, sitio_web) VALUES
(1, N'Massimo Dutti', N'https://www.massimodutti.com'),
(2, N'Zara', N'https://www.zara.com'),
(3, N'Uniqlo', N'https://www.uniqlo.com'),
(4, N'Levi''s', N'https://www.levi.com'),
(5, N'Scalpers', N'https://www.scalperscompany.com'),
(6, N'Nike', N'https://www.nike.com'),
(7, N'Patagonia', N'https://eu.patagonia.com'),
(8, N'Mango', N'https://shop.mango.com'),
(9, N'Adolfo Domínguez', N'https://www.adolfodominguez.com'),
(10, N'New Balance', N'https://www.newbalance.es'),
(11, N'COS', N'https://www.cos.com'),
(12, N'Dr. Martens', N'https://www.drmartens.com');
GO

-- Ocasiones
INSERT INTO OCASIONES (id, nombre, descripcion, nivel_formalidad) VALUES
(1, N'Boda o ceremonia de día', N'Eventos formales al aire libre, fincas o jardines donde se exige etiqueta elegante pero adaptada a temperaturas altas o sol directo.', 5),
(2, N'Evento de gala o cóctel nocturno', N'Celebraciones formales de noche, cenas de etiqueta o inauguraciones que requieren sastrería oscura o vestidos de fiesta.', 5),
(3, N'Reunión ejecutiva o cliente', N'Entorno corporativo estricto, presentaciones ante dirección o cierres de ventas donde proyectar seriedad y profesionalidad.', 4),
(4, N'Oficina Smart Casual', N'Día a día laboral en oficina moderna, permite combinar prendas estructuradas como blazers con básicos cómodos sin corbata.', 3),
(5, N'Cena o terraza nocturna', N'Salidas informales pero cuidadas con amigos o en pareja en restaurantes, bares de copas o terrazas de entretiempo.', 3),
(6, N'Viaje de trabajo o vuelo', N'Desplazamientos largos en tren o avión que requieren prendas elásticas, que no se arruguen y permitan cambios bruscos de climatización.', 2),
(7, N'Paseo urbano o recados', N'Actividades cotidianas de fin de semana, compras, museos o caminatas largas por asfalto priorizando comodidad en el calzado.', 2),
(8, N'Deporte o ruta exterior', N'Entrenamiento físico, running o senderismo en la naturaleza con prendas técnicas, transpirables o resistentes a la lluvia.', 1);
GO

-- Prendas
INSERT INTO PRENDAS (id, usuario_id, marca_id, nombre, descripcion, talla, temporada, categoria, color_principal, precio_compra, foto_url, esta_limpia, fecha_ensuciado, fecha_ultimo_uso, contador_usos) VALUES
(1, 1, 1, N'Vestido midi de lino verde oliva', N'Vestido fluido 100% lino rústico con escote en pico y espalda descubierta. Tejido muy fresco y transpirable ideal para ceremonias de verano con mucho calor, aunque tiende a arrugarse al estar sentada.', N'M', N'Verano', N'Vestido', N'Verde oliva', 89.95, N'/img/prendas/u1_vestido_lino_oliva.jpg', 1, NULL, '2026-06-20 23:00:00', 2),
(2, 1, 1, N'Sandalias de tacón bloque en piel camel', N'Sandalias de tiras cruzadas en cuero vacuno suave con tacón ancho de 6 cm y plantilla acolchada. Estilizan sin cansar el pie, perfectas para aguantar de pie en bodas o jardines con césped.', N'38', N'Verano', N'Calzado', N'Marrón camel', 79.95, N'/img/prendas/u1_sandalias_piel_camel.jpg', 1, NULL, '2026-06-20 23:00:00', 5),
(3, 1, 2, N'Blazer oversize de crepé beige', N'Americana de corte relajado y hombreras marcadas en tejido fluido que no necesita plancha. Forro interior fino de viscosa, perfecta para oficina en entretiempo o para cubrir los hombros en noches frescas.', N'M', N'Primavera', N'Chaqueta', N'Beige piedra', 59.95, N'/img/prendas/u1_blazer_crepe_beige.jpg', 1, NULL, '2026-05-15 23:30:00', 9),
(4, 1, 9, N'Blusa de seda natural blanca', N'Camisa de caída fluida en morera de seda con cuello camisero oculto y puños abotonados. Tacto frío muy elegante para reuniones formales, aunque delicada ante manchas o roce de bolsos.', N'S', N'Todas', N'Camisa', N'Blanco roto', 110.00, N'/img/prendas/u1_blusa_seda_blanca.jpg', 0, '2026-06-28 20:00:00', '2026-06-28 20:00:00', 6),
(5, 1, 8, N'Pantalón palazzo de pinzas negro', N'Pantalón de vestir de tiro muy alto y pernera ancha fluida en mezcla de poliéster reciclado y elastano. Alarga la figura, no oprime la cintura tras comer y viste tanto para eventos como para despacho.', N'38', N'Otoño', N'Pantalón', N'Negro', 49.99, N'/img/prendas/u1_palazzo_negro.jpg', 1, NULL, '2026-05-10 19:00:00', 11),
(6, 1, 4, N'Vaqueros rectos 501 Crop azul medio', N'Pantalón denim 100% algodón rígido sin elasticidad, tiro alto y largo tobillero. Tejido grueso muy duradero para uso casual o viernes en la oficina, pero algo caluroso si sube de 28 grados.', N'38', N'Primavera', N'Pantalón', N'Azul índigo', 95.00, N'/img/prendas/u1_levis_501_crop.jpg', 1, NULL, '2026-05-15 23:30:00', 14),
(7, 1, 1, N'Mocasines destalonados de ante negro', N'Zapato plano tipo mule en piel vuelta muy blanda con hebilla dorada discreta. Cómodos para conducir y trabajar en interior, pero nada recomendables si hay previsión de lluvia.', N'38', N'Primavera', N'Calzado', N'Negro', 69.95, N'/img/prendas/u1_mocasin_ante_negro.jpg', 1, NULL, '2026-05-15 23:30:00', 7),
(8, 1, 11, N'Abrigo largo de lana virgen gris marengo', N'Abrigo masculino de corte recto hasta la rodilla con solapa ancha y tejido denso 80% lana. Abriga muchísimo frente al viento frío de invierno manteniendo una silueta ejecutiva impecable.', N'M', N'Invierno', N'Abrigo', N'Gris oscuro', 225.00, N'/img/prendas/u1_abrigo_lana_gris.jpg', 1, NULL, '2026-02-18 21:00:00', 12),
(9, 2, 1, N'Traje sastre de lana fría azul marino', N'Conjunto de dos piezas de corte slim italiano en lana super 110s. Tejido ligero, termorregulador y resistente a las arrugas, pensado para reuniones ejecutivas o bodas sin pasar agobio.', N'50', N'Primavera', N'Traje', N'Azul marino', 299.00, N'/img/prendas/u2_traje_lana_fria.jpg', 1, NULL, '2026-04-10 18:00:00', 3),
(10, 2, 5, N'Camisa Oxford de algodón celeste', N'Camisa de corte regular con cuello abotonado (button-down) en tejido Oxford de algodón grueso pero transpirable. Un comodín para llevar sin corbata bajo americana o con chinos.', N'L', N'Todas', N'Camisa', N'Azul celeste', 65.00, N'/img/prendas/u2_camisa_oxford_celeste.jpg', 1, NULL, '2026-04-10 18:00:00', 10),
(11, 2, 3, N'Pantalón chino elástico slim beige', N'Pantalón de sarga de algodón con un 3% de elastano. Permite total libertad de movimiento para viajar o estar sentado ocho horas en la oficina sin perder la forma.', N'42', N'Primavera', N'Pantalón', N'Beige arena', 39.90, N'/img/prendas/u2_chino_beige_uniqlo.jpg', 0, '2026-06-25 22:00:00', '2026-06-25 22:00:00', 16),
(12, 2, 5, N'Polo de piqué verde botella', N'Polo de manga corta en algodón piqué con cuello estructurado que no se deforma al lavar. Ideal para cenas informales de verano o viernes de oficina relajados.', N'L', N'Verano', N'Polo', N'Verde oscuro', 49.90, N'/img/prendas/u2_polo_pique_verde.jpg', 1, NULL, '2026-06-12 23:00:00', 8),
(13, 2, 6, N'Zapatillas técnicas Air Zoom Pegasus 40', N'Zapatillas de running con malla transpirable e inserciones de espuma reactiva. Excelente absorción de impactos para entrenar en asfalto o caminatas largas de fin de semana.', N'43', N'Todas', N'Calzado', N'Blanco y gris', 129.99, N'/img/prendas/u2_nike_pegasus_blancas.jpg', 1, NULL, '2026-05-02 14:00:00', 22),
(14, 2, 1, N'Zapatos Oxford de piel marrón chocolate', N'Calzado clásico de cordones en piel calf brillante con suela mixta de cuero y goma antideslizante. Muy elegantes para traje, aunque los primeros usos resultaron algo rígidos en el talón.', N'43', N'Todas', N'Calzado', N'Marrón oscuro', 119.00, N'/img/prendas/u2_oxford_piel_marron.jpg', 1, NULL, '2026-04-10 18:00:00', 4),
(15, 2, 4, N'Cazadora Trucker vaquera azul lavado', N'Chaqueta denim clásica de entretiempo con bolsillos en el pecho. Corta bien el viento fresco de la mañana o de una terraza por la noche sin abrigar en exceso.', N'L', N'Otoño', N'Chaqueta', N'Azul medio', 99.00, N'/img/prendas/u2_trucker_levis.jpg', 1, NULL, '2026-05-02 14:00:00', 9),
(16, 2, 3, N'Camiseta Airism de algodón blanca', N'Camiseta básica de cuello redondo con interior técnico que evacúa el sudor rápidamente y exterior de apariencia algodón premium. No transparenta y mantiene el cuerpo seco.', N'L', N'Verano', N'Camiseta', N'Blanco', 19.90, N'/img/prendas/u2_camiseta_airism_blanca.jpg', 1, NULL, '2026-05-02 14:00:00', 19),
(17, 3, 11, N'Pantalón sastre técnico antiarrugas azul noche', N'Pantalón de corte recto tobillero con cintura trasera elástica invisible. Tejido sintético japonés de secado rápido que sale intacto de la maleta, diseñado para viajes de negocios.', N'36', N'Todas', N'Pantalón', N'Azul marino', 89.00, N'/img/prendas/u3_pantalon_viaje_cos.jpg', 1, NULL, '2026-05-20 21:00:00', 13),
(18, 3, 3, N'Jersey de cuello cisne en lana merino extrafina', N'Prenda de punto fino 100% lana merino en tono negro. Regula la temperatura en aviones o salas con aire acondicionado fuerte sin ocupar espacio en el equipaje de mano.', N'S', N'Invierno', N'Punto', N'Negro', 39.90, N'/img/prendas/u3_merino_negro_uniqlo.jpg', 1, NULL, '2026-03-14 19:00:00', 15),
(19, 3, 8, N'Gabardina impermeable clásica color camel', N'Trench de doble botonadura con cinturón y tejido gabardina de algodón con acabado repelente al agua. Ideal para días lluviosos de otoño o primavera sobre ropa de oficina.', N'S', N'Otoño', N'Abrigo', N'Beige camel', 79.99, N'/img/prendas/u3_trench_camel.jpg', 1, NULL, '2026-04-22 20:00:00', 8),
(20, 3, 10, N'Zapatillas urbanas 327 en ante gris y blanco', N'Deportivas de estética retro muy ligeras con suela dentada de goma. Combinan con pantalón sastre para caminar kilómetros en viajes de trabajo sin sacrificar un aspecto moderno.', N'37', N'Todas', N'Calzado', N'Gris perla', 110.00, N'/img/prendas/u3_nb_327_gris.jpg', 1, NULL, '2026-05-20 21:00:00', 18),
(21, 3, 7, N'Chaqueta cortavientos impermeable Torrentshell', N'Membrana técnica de tres capas totalmente impermeable y transpirable con cremalleras de ventilación en axilas. Imprescindible para senderismo con lluvia intensa o viento de montaña.', N'S', N'Todas', N'Chaqueta', N'Verde esmeralda', 180.00, N'/img/prendas/u3_patagonia_shell.jpg', 0, '2026-06-14 17:00:00', '2026-06-14 17:00:00', 5),
(22, 4, 11, N'Sobrecamisa de sarga de algodón pesado caqui', N'Prenda híbrida entre camisa y chaqueta de corte cuadrado en algodón orgánico de alto gramaje. Muy cómoda para llevar abierta sobre camiseta en entornos creativos o cenas informales.', N'XL', N'Otoño', N'Chaqueta', N'Verde caqui', 79.00, N'/img/prendas/u4_sobrecamisa_caqui.jpg', 1, NULL, '2026-05-28 23:45:00', 11),
(23, 4, 3, N'Camiseta oversize de algodón pesado crudo', N'Camiseta de manga caída y cuello cerrado en punto grueso que no se deforma ni marca. Estética minimalista limpia, aunque algo calurosa en pleno agosto.', N'XL', N'Verano', N'Camiseta', N'Blanco crudo', 24.90, N'/img/prendas/u4_camiseta_heavy_crudo.jpg', 1, NULL, '2026-05-28 23:45:00', 14),
(24, 4, 2, N'Pantalón cargo relaxed fit gris antracita', N'Pantalón de corte holgado en tejido ripstop resistente a desgarros con bolsillos laterales planos. Muy funcional y cómodo para el día a día urbano.', N'44', N'Otoño', N'Pantalón', N'Gris antracita', 45.95, N'/img/prendas/u4_cargo_antracita.jpg', 1, NULL, '2026-05-28 23:45:00', 9),
(25, 4, 12, N'Botas 1460 de cuero liso negro con cámara de aire', N'Bota icónica de ocho ojales con suela cosida Goodyear resistente al agua y a suelos resbaladizos. Protegen de la lluvia y el frío, pero pesan bastante si hay que caminar rápido.', N'44', N'Invierno', N'Calzado', N'Negro', 199.00, N'/img/prendas/u4_drmartens_1460.jpg', 1, NULL, '2026-03-05 22:00:00', 17),
(26, 4, 7, N'Forro polar Retro Pile de borreguillo beige', N'Chaqueta térmica muy cálida y suave en poliéster reciclado con cuello alto. Retiene el calor corporal en acampadas o días gélidos secos, pero deja pasar el viento fuerte si no llevas capa exterior.', N'XL', N'Invierno', N'Chaqueta', N'Beige natural', 150.00, N'/img/prendas/u4_patagonia_pile.jpg', 1, NULL, '2026-02-20 19:00:00', 7);
GO

-- Outfits
INSERT INTO OUTFITS (id, usuario_id, ocasion_id, nombre, notas, fecha_planificada, fue_usado) VALUES
(1, 1, 1, N'Look Invitada Boda en Finca de Verano', N'Ceremonia al mediodía en Sevilla con previsión de 34 grados. Priorizar el vestido de lino verde por transpirabilidad y las sandalias de tacón ancho para no hundirme en el césped del cóctel.', '2026-06-20', 1),
(2, 1, 5, N'Cena de viernes en terraza con amigas', N'Noche de primavera agradable pero refrescará a partir de las once. Combinar vaqueros rectos con la blazer fluida beige y mocasines destalonados para ir arreglada pero sin parecer de oficina.', '2026-05-15', 1),
(3, 1, 3, N'Presentación de resultados trimestrales', N'Reunión formal en sala de juntas con clientes internacionales. Llevar el pantalón palazzo negro con la blusa de seda blanca y el abrigo de lana gris para el trayecto a primera hora.', '2026-11-10', 0),
(4, 2, 3, N'Comité de Dirección y cierre de contrato', N'Jornada larga en sede central. Usar el traje azul marino de lana fría con la camisa Oxford celeste sin corbata y zapatos Oxford marrones bien lustrados.', '2026-04-10', 1),
(5, 2, 7, N'Sábado de paseo largo por el centro y compras', N'Caminata de más de 10 km por Madrid con sol suave al mediodía. Llevar camiseta transpirable Airism, cazadora vaquera por si corre aire en la sombra y las Pegasus blancas.', '2026-05-02', 1),
(6, 2, 4, N'Viernes Smart Casual en consultora', N'Día sin visitas externas pero con comida de equipo al salir. Combinar el pantalón chino elástico beige con el polo de piqué verde botella.', '2026-06-12', 1),
(7, 3, 6, N'Vuelo matinal a Bruselas y jornada de trabajo', N'Salgo a las 6:00 AM hacia el aeropuerto con amenaza de lluvia. Necesito ropa que no se arrugue en el avión: pantalón técnico azul, jersey fino de merino, gabardina camel y zapatillas grises.', '2026-04-22', 1),
(8, 3, 8, N'Ruta de senderismo por la sierra con lluvia', N'Previsión de chubascos y rachas de viento en cota alta. Imprescindible llevar la chaqueta impermeable Patagonia como capa exterior.', '2026-06-14', 1),
(9, 4, 5, N'Inauguración de exposición y cena en galería', N'Ambiente creativo e informal de tarde-noche. Llevar el pantalón cargo antracita con la camiseta gruesa cruda, sobrecamisa caqui abierta y las botas Dr. Martens.', '2026-05-28', 1);
GO

-- Relación Outfits - Prendas
INSERT INTO OUTFIT_PRENDA (outfit_id, prenda_id) VALUES
(1, 1), (1, 2),
(2, 3), (2, 6), (2, 7),
(3, 4), (3, 5), (3, 8),
(4, 9), (4, 10), (4, 14),
(5, 13), (5, 15), (5, 16),
(6, 11), (6, 12), (6, 13),
(7, 17), (7, 18), (7, 19), (7, 20),
(8, 21), (8, 20),
(9, 22), (9, 23), (9, 24), (9, 25);
GO

-- Valoraciones
INSERT INTO VALORACIONES_OUTFIT (id, outfit_id, usuario_id, puntuacion, comentario, created_at) VALUES
(1, 1, 1, 5, N'Un acierto total para una boda tan calurosa. El lino me permitió estar fresca durante toda la ceremonia al sol sin sensación de agobio, aunque la falda se arrugó bastante durante el viaje en coche. Las sandalias de tacón ancho sujetan genial el tobillo y no me dolieron nada los pies tras ocho horas de baile.', '2026-06-21 11:30:00'),
(2, 2, 1, 4, N'Combinación muy versátil y estilosa. La blazer beige abrigó lo justo cuando bajó la temperatura en la terraza por la noche. Le quito una estrella porque los vaqueros rígidos resultan un poco incómodos en la cintura después de una cena copiosa.', '2026-05-16 10:15:00'),
(3, 4, 2, 4, N'El traje de lana fría es espectacular: transpira de maravilla en salas cerradas y llegó al final del día sin una sola arruga en las mangas. Sin embargo, los zapatos Oxford marrones todavía están muy duros y me hicieron una pequeña rozadura en el talón izquierdo al volver caminando.', '2026-04-11 09:00:00'),
(4, 5, 2, 3, N'Las zapatillas Pegasus y la camiseta técnica funcionaron de diez para caminar toda la mañana, pero a partir de la una de la tarde subió la temperatura y la cazadora vaquera me sobraba por completo; tuve que llevarla en la mano el resto del paseo.', '2026-05-03 19:20:00'),
(5, 6, 2, 5, N'El conjunto perfecto para los viernes de verano en la oficina. El pantalón chino elástico es comodísimo para estar sentado frente al ordenador y el polo verde mantiene una presencia formal pero relajada para salir directo a comer.', '2026-06-13 12:00:00'),
(6, 7, 3, 5, N'Mi uniforme definitivo para viajar en avión. El pantalón técnico no cogió ni una marca tras dos horas de vuelo, el jersey de lana merino me salvó del aire acondicionado helado de la cabina y la gabardina aguantó perfectamente el chaparrón al aterrizar.', '2026-04-23 22:10:00'),
(7, 8, 3, 2, N'La chaqueta impermeable Patagonia cumplió de sobra manteniendo el torso seco bajo la tormenta, pero cometí el error de llevar las zapatillas urbanas de ante gris: se empaparon en el primer charco y resbalaban bastante en las piedras mojadas.', '2026-06-14 20:40:00'),
(8, 9, 4, 4, N'Estéticamente el conjunto quedó brutal para el evento en la galería, las capas de algodón pesado tienen mucha presencia. El único punto negativo es que las botas Dr. Martens resultaron demasiado pesadas y calurosas para una noche de finales de mayo.', '2026-05-29 13:00:00');
GO