-- ===========================================================================
-- ARCHIVO SEED: DATOS CATÁLOGO DE ATHLOS (Limpios y sin NULLs)
-- ===========================================================================

-- 1. cat_tipo_cliente
INSERT INTO public.cat_tipo_cliente (id_tipo_cliente, nombre_tipo) VALUES
(1, 'Empresa'),
(2, 'Persona')
ON CONFLICT (id_tipo_cliente) DO NOTHING;

-- 2. estado_pago
INSERT INTO public.estado_pago (id_estado_pago, nombre_estado, descripcion) VALUES
(1, 'Pendiente', 'Sin pago registrado'),
(2, 'Parcial', 'Pago a medias'),
(3, 'Pagado', 'Total liquidado')
ON CONFLICT (id_estado_pago) DO NOTHING;

-- 3. estado_orden
INSERT INTO public.estado_orden (id_estado, nombre_estado, descripcion) VALUES
(1, 'Pendiente', 'Orden recibida pero no iniciada'),
(2, 'En Producción', 'La orden está en taller'),
(3, 'Finalizada', 'Prendas listas para entrega'),
(4, 'Entregada', 'El cliente ya recibió el pedido')
ON CONFLICT (id_estado) DO NOTHING;

-- 4. roles
INSERT INTO public.roles (id_rol, nombre_rol) VALUES
(1, 'Administrador'),
(2, 'Produccion'),
(3, 'Cajas'),
(4, 'Invitado')
ON CONFLICT (id_rol) DO NOTHING;

-- 5. estado_lote
INSERT INTO public.estado_lote (id_estado_lote, nombre_estado, descripcion) VALUES
(1, 'Pendiente', 'Lote creado por la Edge Function, listo para iniciar'),
(2, 'En Corte', 'El cortador tiene la tela y está sacando las piezas'),
(3, 'Listo para Sublimado', 'Tela cortada, esperando diseño'),
(4, 'En Sublimado', 'Se está aplicando el diseño/estampado'),
(5, 'Listo para Confección', 'Piezas listas para ser cosidas'),
(6, 'En Confección', 'El costurero está armando la prenda'),
(7, 'Terminado', 'Prenda lista y revisada')
ON CONFLICT (id_estado_lote) DO NOTHING;

-- 6. area_produccion
INSERT INTO public.area_produccion (id_area, nombre_area) VALUES
(1, 'Corte'),
(2, 'Sublimado'),
(3, 'Confección'),
(4, 'Ventas/Cajas')
ON CONFLICT (id_area) DO NOTHING;

-- 7. estado_asignacion (Reemplazando NULLs por valores descriptivos)
INSERT INTO public.estado_asignacion (id_estado_asignacion, nombre_estado, descripcion) VALUES
(1, 'Asignado', 'El trabajador ha recibido la tarea'),
(2, 'En Proceso', 'La tarea está siendo ejecutada actualmente'),
(3, 'Terminado', 'La tarea ha sido completada con éxito')
ON CONFLICT (id_estado_asignacion) DO NOTHING;

-- 8. tallas
INSERT INTO public.tallas (id_talla, nombre_talla, descripcion) VALUES
(1, 'XS', 'Extra Pequeño / Extra Small'),
(2, 'S', 'Pequeño / Small'),
(3, 'M', 'Mediano / Medium'),
(4, 'L', 'Grande / Large'),
(5, 'XL', 'Extra Grande / Extra Large'),
(6, 'XXL', 'Doble Extra Grande'),
(7, 'TU', 'Talla Única (Accesorios/Gorras)'),
(8, '4-6', 'Infantil Niños pequeños'),
(9, '8-10', 'Infantil Niños medianos'),
(10, '12-14', 'Infantil Adolescentes')
ON CONFLICT (id_talla) DO NOTHING;

-- 9. estado_movimiento
INSERT INTO public.estado_movimiento (id_estado_mov, nombre_movimiento, descripcion) VALUES
(1, 'Ingreso', 'Ingreso de material al inventario'),
(2, 'Salida', 'Uso de material en producción')
ON CONFLICT (id_estado_mov) DO NOTHING;

-- 10. categoria_insumo
INSERT INTO public.categoria_insumo (id_categoria, nombre_categoria) VALUES
(1, 'Telas y Tejidos'),
(2, 'Hilos'),
(3, 'Avíos y Mercería'),
(4, 'Etiquetas y Apliques'),
(5, 'Empaque y Embalaje')
ON CONFLICT (id_categoria) DO NOTHING;

-- 11. unidad_medida
INSERT INTO public.unidad_medida (id_unidad, nom_unidad, abreviatura) VALUES
(1, 'Metros', 'm'),
(2, 'Unidad', 'u'),
(3, 'Cono', 'cono')
ON CONFLICT (id_unidad) DO NOTHING;

-- 12. categoria_unidad
INSERT INTO public.categoria_unidad (id_categoria, id_unidad) VALUES
(1, 1),
(2, 3),
(3, 1),
(3, 2),
(4, 2),
(5, 2),
(5, 1)
ON CONFLICT DO NOTHING;

-- 13. tipo_prenda
INSERT INTO public.tipo_prenda (id_tipo_prenda, nombre_prenda, descripcion, categoria_prenda) VALUES
(1, 'Polera / T-Shirt', 'Prenda básica de punto manga corta o larga sin cierre.', 'Superior'),
(2, 'Polo', 'Prenda superior con cuello camisero y botones en el pecho.', 'Superior'),
(3, 'Camisa', 'Prenda formal o casual tejida en plano, con botones frontales completos.', 'Superior'),
(4, 'Top Deportivo', 'Prenda superior ceñida y corta para actividad física.', 'Superior'),
(5, 'Pantalón Deportivo / Jogger', 'Pantalón largo casual o deportivo (ej. buzo).', 'Inferior'),
(6, 'Pantalón de Vestir / Jeans', 'Pantalón casual o formal de tela plana.', 'Inferior'),
(7, 'Short / Pantaloneta', 'Pantalón corto deportivo o casual.', 'Inferior'),
(8, 'Calza / Leggings', 'Prenda inferior ceñida al cuerpo de tela altamente elástica.', 'Inferior'),
(9, 'Sudadera / Hoodie', 'Buzo cerrado grueso, con o sin capucha.', 'Exterior'),
(10, 'Campera / Chamarra', 'Prenda de abrigo abierta con cierre frontal o botones.', 'Exterior'),
(11, 'Chaleco', 'Prenda de abrigo sin mangas.', 'Exterior'),
(12, 'Saco / Blazer', 'Prenda exterior formal con solapas.', 'Exterior'),
(13, 'Gorra / Sombrero', 'Prenda para cubrir la cabeza.', 'Accesorio'),
(14, 'Calcetines / Medias', 'Prenda tubular para cubrir los pies.', 'Accesorio'),
(15, 'Chaqueta Deportiva', 'Prenda deportiva, torso', 'Superior'),
(16, 'Buso Deportivo', 'Prenda Deportiva, extremidades inferiores', 'Inferior')
ON CONFLICT (id_tipo_prenda) DO NOTHING;