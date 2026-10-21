-- Población de datos SmartClosetAI (conserva IDs, usa JSON nativo y genera chunks para IA)

USE SmartClosetAI;
GO

SET NOCOUNT ON;
GO

-- Limpiar tablas y reiniciar la secuencia de documentos
DELETE FROM DOCUMENTOS_BUSQUEDA;
DELETE FROM VALORACIONES_OUTFIT;
DELETE FROM OUTFIT_PRENDA;
DELETE FROM OUTFITS;
DELETE FROM PRENDAS;
DELETE FROM OCASIONES;
DELETE FROM MARCAS;
DELETE FROM USUARIOS;

ALTER SEQUENCE seq_documento_id RESTART WITH 1;
GO

-- Insertar usuarios manteniendo IDs originales
SET IDENTITY_INSERT USUARIOS ON;

INSERT INTO USUARIOS (id, name, email, email_verified_at, password, remember_token, created_at, updated_at) VALUES
(1, N'Lucía Martín Gómez', N'lucia.martin@smartcloset.es', '2026-01-10 09:15:00', N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'tok_lucia_01a9b', '2026-01-10 09:00:00', '2026-01-10 09:15:00'),
(2, N'Carlos Gómez Navarro', N'carlos.gomez@smartcloset.es', '2026-01-12 18:30:00', N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', N'tok_carlos_88f2c', '2026-01-12 18:20:00', '2026-01-12 18:30:00'),
(3, N'Elena Rostova Vega', N'elena.rostova@smartcloset.es', '2026-02-01 11:05:00', N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, '2026-02-01 11:00:00', '2026-02-01 11:05:00'),
(4, N'Mateo Silva Mendoza', N'mateo.silva@smartcloset.es', NULL, N'$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', NULL, '2026-02-15 20:45:00', '2026-02-15 20:45:00');

SET IDENTITY_INSERT USUARIOS OFF;
GO

-- Insertar marcas
SET IDENTITY_INSERT MARCAS ON;

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

SET IDENTITY_INSERT MARCAS OFF;
GO

-- Insertar ocasiones
SET IDENTITY_INSERT OCASIONES ON;

INSERT INTO OCASIONES (id, nombre, descripcion, nivel_formalidad) VALUES
(1, N'Boda o ceremonia de día', N'Eventos formales al aire libre, fincas o jardines donde se exige etiqueta elegante pero adaptada a temperaturas altas o sol directo.', 5),
(2, N'Evento de gala o cóctel nocturno', N'Celebraciones formales de noche, cenas de etiqueta o inauguraciones que requieren sastrería oscura o vestidos de fiesta.', 5),
(3, N'Reunión ejecutiva o cliente', N'Entorno corporativo estricto, presentaciones ante dirección o cierres de ventas donde proyectar seriedad y profesionalidad.', 4),
(4, N'Oficina Smart Casual', N'Día a día laboral en oficina moderna, permite combinar prendas estructuradas como blazers con básicos cómodos sin corbata.', 3),
(5, N'Cena o terraza nocturna', N'Salidas informales pero cuidadas con amigos o en pareja en restaurantes, bares de copas o terrazas de entretiempo.', 3),
(6, N'Viaje de trabajo o vuelo', N'Desplazamientos largos en tren o avión que requieren prendas elásticas, que no se arruguen y permitan cambios bruscos de climatización.', 2),
(7, N'Paseo urbano o recados', N'Actividades cotidianas de fin de semana, compras, museos o caminatas largas por asfalto priorizando comodidad en el calzado.', 2),
(8, N'Deporte o ruta exterior', N'Entrenamiento físico, running o senderismo en la naturaleza con prendas técnicas, transpirables o resistentes a la lluvia.', 1);

SET IDENTITY_INSERT OCASIONES OFF;
GO

-- Insertar prendas (con atributos en JSON nativo)
SET IDENTITY_INSERT PRENDAS ON;

INSERT INTO PRENDAS (
    id, usuario_id, marca_id, nombre, descripcion, talla, categoria, 
    color_principal, atributos_json, precio_compra, foto_url, esta_limpia, 
    fecha_ensuciado, fecha_ultimo_uso, contador_usos
) VALUES
-- Lucía (usuario 1)
(1, 1, 1, N'Vestido midi de lino verde oliva', 
 N'Vestido fluido 100% lino rústico con escote en pico y espalda descubierta. Tejido muy fresco y transpirable ideal para ceremonias de verano con mucho calor, aunque tiende a arrugarse al estar sentada.', 
 N'M', N'Vestido', N'Verde oliva', 
 N'{"temporada": "Verano", "tejido": "100% Lino rústico", "corte": "Fluido midi", "estilo": "Formal ceremonia", "impermeable": false, "requiere_plancha": true}', 
 89.95, N'/img/prendas/u1_vestido_lino_oliva.jpg', 1, NULL, '2026-06-20 23:00:00', 2),

(2, 1, 1, N'Sandalias de tacón bloque en piel camel', 
 N'Sandalias de tiras cruzadas en cuero vacuno suave con tacón ancho de 6 cm y plantilla acolchada. Estilizan sin cansar el pie, perfectas para aguantar de pie en bodas o jardines con césped.', 
 N'38', N'Calzado', N'Marrón camel', 
 N'{"temporada": "Verano", "tejido": "Cuero vacuno", "corte": "Tacón bloque 6cm", "estilo": "Elegante cómodo", "impermeable": false, "requiere_plancha": false}', 
 79.95, N'/img/prendas/u1_sandalias_piel_camel.jpg', 1, NULL, '2026-06-20 23:00:00', 5),

(3, 1, 2, N'Blazer oversize de crepé beige', 
 N'Americana de corte relajado y hombreras marcadas en tejido fluido que no necesita plancha. Forro interior fino de viscosa, perfecta para oficina en entretiempo o para cubrir los hombros en noches frescas.', 
 N'M', N'Chaqueta', N'Beige piedra', 
 N'{"temporada": "Primavera", "tejido": "Crepé y viscosa", "corte": "Oversize", "estilo": "Smart Casual", "impermeable": false, "requiere_plancha": false}', 
 59.95, N'/img/prendas/u1_blazer_crepe_beige.jpg', 1, NULL, '2026-05-15 23:30:00', 9),

(4, 1, 9, N'Blusa de seda natural blanca', 
 N'Camisa de caída fluida en morera de seda con cuello camisero oculto y puños abotonados. Tacto frío muy elegante para reuniones formales, aunque delicada ante manchas o roce de bolsos.', 
 N'S', N'Camisa', N'Blanco roto', 
 N'{"temporada": "Todas", "tejido": "100% Seda morera", "corte": "Fluido clásico", "estilo": "Ejecutivo formal", "impermeable": false, "requiere_plancha": true}', 
 110.00, N'/img/prendas/u1_blusa_seda_blanca.jpg', 0, '2026-06-28 20:00:00', '2026-06-28 20:00:00', 6),

(5, 1, 8, N'Pantalón palazzo de pinzas negro', 
 N'Pantalón de vestir de tiro muy alto y pernera ancha fluida en mezcla de poliéster reciclado y elastano. Alarga la figura, no oprime la cintura tras comer y viste tanto para eventos como para despacho.', 
 N'38', N'Pantalón', N'Negro', 
 N'{"temporada": "Otoño", "tejido": "Poliéster reciclado y elastano", "corte": "Palazzo tiro alto", "estilo": "Formal versátil", "impermeable": false, "requiere_plancha": false}', 
 49.99, N'/img/prendas/u1_palazzo_negro.jpg', 1, NULL, '2026-05-10 19:00:00', 11),

(6, 1, 4, N'Vaqueros rectos 501 Crop azul medio', 
 N'Pantalón denim 100% algodón rígido sin elasticidad, tiro alto y largo tobillero. Tejido grueso muy duradero para uso casual o viernes en la oficina, pero algo caluroso si sube de 28 grados.', 
 N'38', N'Pantalón', N'Azul índigo', 
 N'{"temporada": "Primavera", "tejido": "Denim 100% algodón rígido", "corte": "Recto tobillero", "estilo": "Casual urbano", "impermeable": false, "requiere_plancha": false}', 
 95.00, N'/img/prendas/u1_levis_501_crop.jpg', 1, NULL, '2026-05-15 23:30:00', 14),

(7, 1, 1, N'Mocasines destalonados de ante negro', 
 N'Zapato plano tipo mule en piel vuelta muy blanda con hebilla dorada discreta. Cómodos para conducir y trabajar en interior, pero nada recomendables si hay previsión de lluvia.', 
 N'38', N'Calzado', N'Negro', 
 N'{"temporada": "Primavera", "tejido": "Ante piel vuelta", "corte": "Mule plano", "estilo": "Smart Casual", "impermeable": false, "requiere_plancha": false}', 
 69.95, N'/img/prendas/u1_mocasin_ante_negro.jpg', 1, NULL, '2026-05-15 23:30:00', 7),

(8, 1, 11, N'Abrigo largo de lana virgen gris marengo', 
 N'Abrigo masculino de corte recto hasta la rodilla con solapa ancha y tejido denso 80% lana. Abriga muchísimo frente al viento frío de invierno manteniendo una silueta ejecutiva impecable.', 
 N'M', N'Abrigo', N'Gris oscuro', 
 N'{"temporada": "Invierno", "tejido": "80% Lana virgen", "corte": "Recto largo", "estilo": "Ejecutivo invernal", "impermeable": false, "requiere_plancha": false}', 
 225.00, N'/img/prendas/u1_abrigo_lana_gris.jpg', 1, NULL, '2026-02-18 21:00:00', 12),

-- Carlos (usuario 2)
(9, 2, 1, N'Traje sastre de lana fría azul marino', 
 N'Conjunto de dos piezas de corte slim italiano en lana super 110s. Tejido ligero, termorregulador y resistente a las arrugas, pensado para reuniones ejecutivas o bodas sin pasar agobio.', 
 N'50', N'Traje', N'Azul marino', 
 N'{"temporada": "Primavera", "tejido": "Lana fría Super 110s", "corte": "Slim italiano", "estilo": "Sastrería ejecutiva", "impermeable": false, "requiere_plancha": false}', 
 299.00, N'/img/prendas/u2_traje_lana_fria.jpg', 1, NULL, '2026-04-10 18:00:00', 3),

(10, 2, 5, N'Camisa Oxford de algodón celeste', 
 N'Camisa de corte regular con cuello abotonado (button-down) en tejido Oxford de algodón grueso pero transpirable. Un comodín para llevar sin corbata bajo americana o con chinos.', 
 N'L', N'Camisa', N'Azul celeste', 
 N'{"temporada": "Todas", "tejido": "Algodón Oxford", "corte": "Regular button-down", "estilo": "Smart Casual", "impermeable": false, "requiere_plancha": true}', 
 65.00, N'/img/prendas/u2_camisa_oxford_celeste.jpg', 1, NULL, '2026-04-10 18:00:00', 10),

(11, 2, 3, N'Pantalón chino elástico slim beige', 
 N'Pantalón de sarga de algodón con un 3% de elastano. Permite total libertad de movimiento para viajar o estar sentado ocho horas en la oficina sin perder la forma.', 
 N'42', N'Pantalón', N'Beige arena', 
 N'{"temporada": "Primavera", "tejido": "Sarga algodón y elastano", "corte": "Slim elástico", "estilo": "Oficina cómodo", "impermeable": false, "requiere_plancha": false}', 
 39.90, N'/img/prendas/u2_chino_beige_uniqlo.jpg', 0, '2026-06-25 22:00:00', '2026-06-25 22:00:00', 16),

(12, 2, 5, N'Polo de piqué verde botella', 
 N'Polo de manga corta en algodón piqué con cuello estructurado que no se deforma al lavar. Ideal para cenas informales de verano o viernes de oficina relajados.', 
 N'L', N'Polo', N'Verde oscuro', 
 N'{"temporada": "Verano", "tejido": "Algodón piqué", "corte": "Regular manga corta", "estilo": "Smart Casual", "impermeable": false, "requiere_plancha": false}', 
 49.90, N'/img/prendas/u2_polo_pique_verde.jpg', 1, NULL, '2026-06-12 23:00:00', 8),

(13, 2, 6, N'Zapatillas técnicas Air Zoom Pegasus 40', 
 N'Zapatillas de running con malla transpirable e inserciones de espuma reactiva. Excelente absorción de impactos para entrenar en asfalto o caminatas largas de fin de semana.', 
 N'43', N'Calzado', N'Blanco y gris', 
 N'{"temporada": "Todas", "tejido": "Malla técnica transpirable", "corte": "Deportivo amortiguado", "estilo": "Running y paseo", "impermeable": false, "requiere_plancha": false}', 
 129.99, N'/img/prendas/u2_nike_pegasus_blancas.jpg', 1, NULL, '2026-05-02 14:00:00', 22),

(14, 2, 1, N'Zapatos Oxford de piel marrón chocolate', 
 N'Calzado clásico de cordones en piel calf brillante con suela mixta de cuero y goma antideslizante. Muy elegantes para traje, aunque los primeros usos resultaron algo rígidos en el talón.', 
 N'43', N'Calzado', N'Marrón oscuro', 
 N'{"temporada": "Todas", "tejido": "Piel calf y suela mixta", "corte": "Oxford cordones", "estilo": "Formal clásico", "impermeable": false, "requiere_plancha": false}', 
 119.00, N'/img/prendas/u2_oxford_piel_marron.jpg', 1, NULL, '2026-04-10 18:00:00', 4),

(15, 2, 4, N'Cazadora Trucker vaquera azul lavado', 
 N'Chaqueta denim clásica de entretiempo con bolsillos en el pecho. Corta bien el viento fresco de la mañana o de una terraza por la noche sin abrigar en exceso.', 
 N'L', N'Chaqueta', N'Azul medio', 
 N'{"temporada": "Otoño", "tejido": "Denim algodón", "corte": "Trucker clásica", "estilo": "Casual entretiempo", "impermeable": false, "requiere_plancha": false}', 
 99.00, N'/img/prendas/u2_trucker_levis.jpg', 1, NULL, '2026-05-02 14:00:00', 9),

(16, 2, 3, N'Camiseta Airism de algodón blanca', 
 N'Camiseta básica de cuello redondo con interior técnico que evacúa el sudor rápidamente y exterior de apariencia algodón premium. No transparenta y mantiene el cuerpo seco.', 
 N'L', N'Camiseta', N'Blanco', 
 N'{"temporada": "Verano", "tejido": "Algodón técnico Airism", "corte": "Regular cuello redondo", "estilo": "Básico transpirable", "impermeable": false, "requiere_plancha": false}', 
 19.90, N'/img/prendas/u2_camiseta_airism_blanca.jpg', 1, NULL, '2026-05-02 14:00:00', 19),

-- Elena (usuario 3)
(17, 3, 11, N'Pantalón sastre técnico antiarrugas azul noche', 
 N'Pantalón de corte recto tobillero con cintura trasera elástica invisible. Tejido sintético japonés de secado rápido que sale intacto de la maleta, diseñado para viajes de negocios.', 
 N'36', N'Pantalón', N'Azul marino', 
 N'{"temporada": "Todas", "tejido": "Sintético técnico japonés", "corte": "Recto tobillero elástico", "estilo": "Viaje ejecutivo", "impermeable": false, "requiere_plancha": false}', 
 89.00, N'/img/prendas/u3_pantalon_viaje_cos.jpg', 1, NULL, '2026-05-20 21:00:00', 13),

(18, 3, 3, N'Jersey de cuello cisne en lana merino extrafina', 
 N'Prenda de punto fino 100% lana merino en tono negro. Regula la temperatura en aviones o salas con aire acondicionado fuerte sin ocupar espacio en el equipaje de mano.', 
 N'S', N'Punto', N'Negro', 
 N'{"temporada": "Invierno", "tejido": "100% Lana merino extrafina", "corte": "Cuello cisne fino", "estilo": "Minimalista funcional", "impermeable": false, "requiere_plancha": false}', 
 39.90, N'/img/prendas/u3_merino_negro_uniqlo.jpg', 1, NULL, '2026-03-14 19:00:00', 15),

(19, 3, 8, N'Gabardina impermeable clásica color camel', 
 N'Trench de doble botonadura con cinturón y tejido gabardina de algodón con acabado repelente al agua. Ideal para días lluviosos de otoño o primavera sobre ropa de oficina.', 
 N'S', N'Abrigo', N'Beige camel', 
 N'{"temporada": "Otoño", "tejido": "Gabardina algodón hidrofugado", "corte": "Trench doble botonadura", "estilo": "Clásico lluvia", "impermeable": true, "requiere_plancha": false}', 
 79.99, N'/img/prendas/u3_trench_camel.jpg', 1, NULL, '2026-04-22 20:00:00', 8),

(20, 3, 10, N'Zapatillas urbanas 327 en ante gris y blanco', 
 N'Deportivas de estética retro muy ligeras con suela dentada de goma. Combinan con pantalón sastre para caminar kilómetros en viajes de trabajo sin sacrificar un aspecto moderno.', 
 N'37', N'Calzado', N'Gris perla', 
 N'{"temporada": "Todas", "tejido": "Ante y nylon ligero", "corte": "Retro urbano", "estilo": "Smart Casual viaje", "impermeable": false, "requiere_plancha": false}', 
 110.00, N'/img/prendas/u3_nb_327_gris.jpg', 1, NULL, '2026-05-20 21:00:00', 18),

(21, 3, 7, N'Chaqueta cortavientos impermeable Torrentshell', 
 N'Membrana técnica de tres capas totalmente impermeable y transpirable con cremalleras de ventilación en axilas. Imprescindible para senderismo con lluvia intensa o viento de montaña.', 
 N'S', N'Chaqueta', N'Verde esmeralda', 
 N'{"temporada": "Todas", "tejido": "Membrana técnica H2No 3 capas", "corte": "Técnico montaña", "estilo": "Outdoor impermeable", "impermeable": true, "requiere_plancha": false}', 
 180.00, N'/img/prendas/u3_patagonia_shell.jpg', 0, '2026-06-14 17:00:00', '2026-06-14 17:00:00', 5),

-- Mateo (usuario 4)
(22, 4, 11, N'Sobrecamisa de sarga de algodón pesado caqui', 
 N'Prenda híbrida entre camisa y chaqueta de corte cuadrado en algodón orgánico de alto gramaje. Muy cómoda para llevar abierta sobre camiseta en entornos creativos o cenas informales.', 
 N'XL', N'Chaqueta', N'Verde caqui', 
 N'{"temporada": "Otoño", "tejido": "Sarga algodón orgánico pesado", "corte": "Boxy cuadrado", "estilo": "Creativo urbano", "impermeable": false, "requiere_plancha": false}', 
 79.00, N'/img/prendas/u4_sobrecamisa_caqui.jpg', 1, NULL, '2026-05-28 23:45:00', 11),

(23, 4, 3, N'Camiseta oversize de algodón pesado crudo', 
 N'Camiseta de manga caída y cuello cerrado en punto grueso que no se deforma ni marca. Estética minimalista limpia, aunque algo calurosa en pleno agosto.', 
 N'XL', N'Camiseta', N'Blanco crudo', 
 N'{"temporada": "Verano", "tejido": "Punto algodón alto gramaje", "corte": "Oversize hombro caído", "estilo": "Streetwear minimalista", "impermeable": false, "requiere_plancha": false}', 
 24.90, N'/img/prendas/u4_camiseta_heavy_crudo.jpg', 1, NULL, '2026-05-28 23:45:00', 14),

(24, 4, 2, N'Pantalón cargo relaxed fit gris antracita', 
 N'Pantalón de corte holgado en tejido ripstop resistente a desgarros con bolsillos laterales planos. Muy funcional y cómodo para el día a día urbano.', 
 N'44', N'Pantalón', N'Gris antracita', 
 N'{"temporada": "Otoño", "tejido": "Algodón Ripstop antidesgarro", "corte": "Relaxed cargo", "estilo": "Urbano utilitario", "impermeable": false, "requiere_plancha": false}', 
 45.95, N'/img/prendas/u4_cargo_antracita.jpg', 1, NULL, '2026-05-28 23:45:00', 9),

(25, 4, 12, N'Botas 1460 de cuero liso negro con cámara de aire', 
 N'Bota icónica de ocho ojales con suela cosida Goodyear resistente al agua y a suelos resbaladizos. Protegen de la lluvia y el frío, pero pesan bastante si hay que caminar rápido.', 
 N'44', N'Calzado', N'Negro', 
 N'{"temporada": "Invierno", "tejido": "Cuero liso Smooth y suela PVC", "corte": "Bota 8 ojales", "estilo": "Urbano resistente", "impermeable": true, "requiere_plancha": false}', 
 199.00, N'/img/prendas/u4_drmartens_1460.jpg', 1, NULL, '2026-03-05 22:00:00', 17),

(26, 4, 7, N'Forro polar Retro Pile de borreguillo beige', 
 N'Chaqueta térmica muy cálida y suave en poliéster reciclado con cuello alto. Retiene el calor corporal en acampadas o días gélidos secos, pero deja pasar el viento fuerte si no llevas capa exterior.', 
 N'XL', N'Chaqueta', N'Beige natural', 
 N'{"temporada": "Invierno", "tejido": "Poliéster reciclado borreguillo", "corte": "Regular térmico", "estilo": "Outdoor cálido", "impermeable": false, "requiere_plancha": false}', 
 150.00, N'/img/prendas/u4_patagonia_pile.jpg', 1, NULL, '2026-02-20 19:00:00', 7);

SET IDENTITY_INSERT PRENDAS OFF;
GO

-- Insertar outfits planificados
SET IDENTITY_INSERT OUTFITS ON;

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

SET IDENTITY_INSERT OUTFITS OFF;
GO

-- Relacionar outfits con prendas
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

-- Insertar valoraciones de outfits
SET IDENTITY_INSERT VALORACIONES_OUTFIT ON;

INSERT INTO VALORACIONES_OUTFIT (id, outfit_id, usuario_id, puntuacion, comentario, created_at) VALUES
(1, 1, 1, 5, N'Un acierto total para una boda tan calurosa. El lino me permitió estar fresca durante toda la ceremonia al sol sin sensación de agobio, aunque la falda se arrugó bastante durante el viaje en coche. Las sandalias de tacón ancho sujetan genial el tobillo y no me dolieron nada los pies tras ocho horas de baile.', '2026-06-21 11:30:00'),
(2, 2, 1, 4, N'Combinación muy versátil y estilosa. La blazer beige abrigó lo justo cuando bajó la temperatura en la terraza por la noche. Le quito una estrella porque los vaqueros rígidos resultan un poco incómodos en la cintura después de una cena copiosa.', '2026-05-16 10:15:00'),
(3, 4, 2, 4, N'El traje de lana fría es espectacular: transpira de maravilla en salas cerradas y llegó al final del día sin una sola arruga en las mangas. Sin embargo, los zapatos Oxford marrones todavía están muy duros y me hicieron una pequeña rozadura en el talón izquierdo al volver caminando.', '2026-04-11 09:00:00'),
(4, 5, 2, 3, N'Las zapatillas Pegasus y la camiseta técnica funcionaron de diez para caminar toda la mañana, pero a partir de la una de la tarde subió la temperatura y la cazadora vaquera me sobraba por completo; tuve que llevarla en la mano el resto del paseo.', '2026-05-03 19:20:00'),
(5, 6, 2, 5, N'El conjunto perfecto para los viernes de verano en la oficina. El pantalón chino elástico es comodísimo para estar sentado frente al ordenador y el polo verde mantiene una presencia formal pero relajada para salir directo a comer.', '2026-06-13 12:00:00'),
(6, 7, 3, 5, N'Mi uniforme definitivo para viajar en avión. El pantalón técnico no cogió ni una marca tras dos horas de vuelo, el jersey de lana merino me salvó del aire acondicionado helado de la cabina y la gabardina aguantó perfectamente el chaparrón al aterrizar.', '2026-04-23 22:10:00'),
(7, 8, 3, 2, N'La chaqueta impermeable Patagonia cumplió de sobra manteniendo el torso seco bajo la tormenta, pero cometí el error de llevar las zapatillas urbanas de ante gris: se empaparon en el primer charco y resbalaban bastante en las piedras mojadas.', '2026-06-14 20:40:00'),
(8, 9, 4, 4, N'Estéticamente el conjunto quedó brutal para el evento en la galería, las capas de algodón pesado tienen mucha presencia. El único punto negativo es que las botas Dr. Martens resultaron demasiado pesadas y calurosas para una noche de finales de mayo.', '2026-05-29 13:00:00');

SET IDENTITY_INSERT VALORACIONES_OUTFIT OFF;
GO

-- Generar chunks de búsqueda en DOCUMENTOS_BUSQUEDA

-- Chunks de prendas
INSERT INTO DOCUMENTOS_BUSQUEDA (usuario_id, tipo_origen, origen_id, titulo, contenido_texto, metadatos_json)
SELECT 
    p.usuario_id,
    N'PRENDA' AS tipo_origen,
    p.id AS origen_id,
    p.nombre AS titulo,
    CONCAT(
        N'Prenda: ', p.nombre, N'. ',
        N'Categoría: ', p.categoria, N'. ',
        N'Marca: ', ISNULL(m.nombre, N'Sin marca'), N'. ',
        N'Color: ', p.color_principal, N'. ',
        N'Temporada: ', ISNULL(JSON_VALUE(p.atributos_json, '$.temporada'), N'Todas'), N'. ',
        N'Tejido: ', ISNULL(JSON_VALUE(p.atributos_json, '$.tejido'), N'No especificado'), N'. ',
        N'Estilo: ', ISNULL(JSON_VALUE(p.atributos_json, '$.estilo'), N'Estándar'), N'. ',
        N'Estado limpieza: ', CASE WHEN p.esta_limpia = 1 THEN N'Limpia y disponible' ELSE N'Sucia en lavandería' END, N'. ',
        N'Descripción: ', ISNULL(p.descripcion, N'')
    ) AS contenido_texto,
    CAST(
        CONCAT(
            N'{"categoria":"', p.categoria,
            N'","marca":"', ISNULL(m.nombre, N''),
            N'","color":"', p.color_principal,
            N'","esta_limpia":', CASE WHEN p.esta_limpia = 1 THEN 'true' ELSE 'false' END, N'}'
        ) AS JSON
    ) AS metadatos_json
FROM PRENDAS p
LEFT JOIN MARCAS m ON p.marca_id = m.id;

-- Chunks de outfits (incluyendo listado de sus prendas)
INSERT INTO DOCUMENTOS_BUSQUEDA (usuario_id, tipo_origen, origen_id, titulo, contenido_texto, metadatos_json)
SELECT 
    o.usuario_id,
    N'OUTFIT' AS tipo_origen,
    o.id AS origen_id,
    o.nombre AS titulo,
    CONCAT(
        N'Outfit planificado: ', o.nombre, N'. ',
        N'Ocasión: ', ISNULL(oc.nombre, N'General'), N' (Formalidad ', ISNULL(CAST(oc.nivel_formalidad AS NVARCHAR(5)), N'N/A'), N'/5 - ', ISNULL(oc.descripcion, N''), N'). ',
        N'Prendas incluidas: ', ISNULL(prendas_agg.lista_prendas, N'Ninguna'), N'. ',
        N'Notas de planificación: ', ISNULL(o.notas, N'')
    ) AS contenido_texto,
    CAST(
        CONCAT(
            N'{"ocasion":"', ISNULL(oc.nombre, N''),
            N'","nivel_formalidad":', ISNULL(CAST(oc.nivel_formalidad AS NVARCHAR(5)), '0'),
            N',"fue_usado":', CASE WHEN o.fue_usado = 1 THEN 'true' ELSE 'false' END, N'}'
        ) AS JSON
    ) AS metadatos_json
FROM OUTFITS o
LEFT JOIN OCASIONES oc ON o.ocasion_id = oc.id
OUTER APPLY (
    SELECT STRING_AGG(p.nombre, N', ') AS lista_prendas
    FROM OUTFIT_PRENDA op
    INNER JOIN PRENDAS p ON op.prenda_id = p.id
    WHERE op.outfit_id = o.id
) prendas_agg;

-- Chunks de valoraciones post-uso
INSERT INTO DOCUMENTOS_BUSQUEDA (usuario_id, tipo_origen, origen_id, titulo, contenido_texto, metadatos_json)
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
        CONCAT(
            N'{"outfit_id":', v.outfit_id,
            N',"puntuacion":', v.puntuacion, N'}'
        ) AS JSON
    ) AS metadatos_json
FROM VALORACIONES_OUTFIT v
INNER JOIN OUTFITS o ON v.outfit_id = o.id
LEFT JOIN OCASIONES oc ON o.ocasion_id = oc.id
OUTER APPLY (
    SELECT STRING_AGG(p.nombre, N', ') AS lista_prendas
    FROM OUTFIT_PRENDA op
    INNER JOIN PRENDAS p ON op.prenda_id = p.id
    WHERE op.outfit_id = o.id
) prendas_agg;
GO

-- Validar la carga de chunks generados
SELECT tipo_origen, COUNT(*) AS TotalChunks
FROM DOCUMENTOS_BUSQUEDA
GROUP BY tipo_origen;
GO