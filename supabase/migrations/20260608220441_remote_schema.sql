alter table "public"."notificaciones" drop constraint "notificaciones_prioridad_check";

alter table "public"."profiles" add column "fcm_token" text;

alter table "public"."notificaciones" add constraint "notificaciones_prioridad_check" CHECK (((prioridad)::text = ANY ((ARRAY['informativa'::character varying, 'advertencia'::character varying, 'critica'::character varying])::text[]))) not valid;

alter table "public"."notificaciones" validate constraint "notificaciones_prioridad_check";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.tiene_administrador()
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id_rol = 1 LIMIT 1
  );
$function$
;

CREATE OR REPLACE FUNCTION public.activar_y_completar_perfil(p_usuario_id uuid, p_nombre text, p_apellido text, p_ci text, p_telefono text, p_direccion text, p_nuevo_rol integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- 1. Seguridad: Solo el Admin (Rol 1) puede ejecutar esto
    IF (SELECT id_rol FROM profiles WHERE id = auth.uid()) != 1 THEN
        RAISE EXCEPTION 'No tienes permisos para autorizar perfiles.';
    END IF;

    -- 2. Actualización de datos reales
    UPDATE profiles
    SET 
        nom_cliente = p_nombre,
        apellido_cliente = p_apellido,
        ci_cliente = p_ci,
        num_telefono = p_telefono,
        direccion = p_direccion,
        id_rol = p_nuevo_rol -- Aquí es donde le damos el poder
    WHERE id = p_usuario_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.crear_orden_completa(p_id_cliente uuid, p_fecha_entrega date, p_notas_adicionales text, p_imagen_modelo text, p_prioridad text, p_anticipo numeric, p_metodo_pago text, p_items jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_num_orden        uuid;
  v_id_detalle       uuid;
  v_item             jsonb;
  v_talla            jsonb;
  v_cantidad_total   int;
  v_subtotal_item    numeric;
  v_costo_total      numeric := 0;
  v_id_estado_pago   int;
BEGIN
  -- Validación de entrada
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'La orden debe tener al menos un ítem';
  END IF;

  -- 1. INSERT orden
  INSERT INTO orden (id_cliente, fecha_entrega, notas_adicionales, imagen_modelo, prioridad)
  VALUES (p_id_cliente, p_fecha_entrega, p_notas_adicionales, p_imagen_modelo, p_prioridad)
  RETURNING num_orden INTO v_num_orden;

  -- 2. Por cada item del array
  FOR v_item IN SELECT jsonb_array_elements(p_items)
  LOOP
    -- 2a. Validar XOR conjunto/plantilla
    IF (v_item->>'id_conjunto' IS NULL AND v_item->>'id_plantilla' IS NULL) THEN
      RAISE EXCEPTION 'Cada item debe tener id_conjunto o id_plantilla';
    END IF;
    IF (v_item->>'id_conjunto' IS NOT NULL AND v_item->>'id_plantilla' IS NOT NULL) THEN
      RAISE EXCEPTION 'Un item no puede tener ambos id_conjunto e id_plantilla';
    END IF;

    -- 2b. Cantidad total = suma de cantidades de las tallas del item
    SELECT COALESCE(SUM((t->>'cantidad')::int), 0)
    INTO v_cantidad_total
    FROM jsonb_array_elements(v_item->'tallas') AS t;

    IF v_cantidad_total <= 0 THEN
      RAISE EXCEPTION 'Cada item debe tener al menos una talla con cantidad > 0';
    END IF;

    -- 2c. Subtotal = precio_unitario * cantidad_total
    v_subtotal_item := (v_item->>'precio_unitario')::numeric * v_cantidad_total;

    -- 2d. INSERT detalle_orden
    INSERT INTO detalle_orden (
      num_orden, id_conjunto, id_plantilla,
      cantidad_total, precio_unitario, subtotal
    )
    VALUES (
      v_num_orden,
      (v_item->>'id_conjunto')::uuid,
      (v_item->>'id_plantilla')::uuid,
      v_cantidad_total,
      (v_item->>'precio_unitario')::numeric,
      v_subtotal_item
    )
    RETURNING id_detalle INTO v_id_detalle;

    -- 2e. INSERT detalle_orden_talla
    FOR v_talla IN SELECT jsonb_array_elements(v_item->'tallas')
    LOOP
      INSERT INTO detalle_orden_talla (id_detalle, id_talla, cantidad)
      VALUES (
        v_id_detalle,
        (v_talla->>'id_talla')::int,
        (v_talla->>'cantidad')::int
      );
    END LOOP;

    -- 2f. Acumular costo
    v_costo_total := v_costo_total + v_subtotal_item;
  END LOOP;

  -- 3. Calcular estado de pago en base al costo total y el anticipo
  IF p_anticipo >= v_costo_total THEN
    v_id_estado_pago := 3; -- Pagado
  ELSIF p_anticipo > 0 THEN
    v_id_estado_pago := 2; -- Abonado
  ELSE
    v_id_estado_pago := 1; -- Pendiente
  END IF;

  -- 4. Actualizar costo_total Y el estado de pago de la orden
  UPDATE orden 
  SET costo_total = v_costo_total,
      id_estado_pago = v_id_estado_pago
  WHERE num_orden = v_num_orden;

  -- 5. Registrar el anticipo en pago_cliente
  IF p_anticipo > 0 THEN
    INSERT INTO pago_cliente (id_orden, id_cliente, monto, metodo_pago)
    VALUES (v_num_orden, p_id_cliente, p_anticipo, p_metodo_pago);
  END IF;

  RETURN v_num_orden;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generar_alertas_sistema()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- =========================================================================
    -- REGLA 1: ENTREGAS PARA HOY (Dirigido a Jefes - id_usuario = NULL)
    -- =========================================================================
    INSERT INTO public.notificaciones (tipo, titulo, mensaje, prioridad)
    SELECT 
        'ENTREGA_HOY', 
        '🚨 Entrega para HOY', 
        'La orden ' || num_orden || ' debe ser entregada el día de hoy.',
        'critica'
    FROM public.orden
    WHERE fecha_entrega::date = CURRENT_DATE 
      AND id_estado != 3 
      AND NOT EXISTS (
          SELECT 1 FROM public.notificaciones 
          WHERE tipo = 'ENTREGA_HOY' 
            AND id_usuario IS NULL
            AND mensaje LIKE '%' || num_orden || '%' 
            AND fecha_creacion::date = CURRENT_DATE
      );

    -- =========================================================================
    -- REGLA 2: ENTREGAS DE LA SEMANA (Dirigido a Jefes - id_usuario = NULL)
    -- =========================================================================
    INSERT INTO public.notificaciones (tipo, titulo, mensaje, prioridad)
    SELECT 
        'ENTREGA_SEMANA', 
        '📅 Entrega próxima', 
        'La orden ' || num_orden || ' está programada para el ' || to_char(fecha_entrega, 'DD/MM/YYYY'),
        'informativa'
    FROM public.orden
    WHERE fecha_entrega::date BETWEEN CURRENT_DATE + INTERVAL '1 day' AND CURRENT_DATE + INTERVAL '7 days'
      AND id_estado != 3
      AND NOT EXISTS (
          SELECT 1 FROM public.notificaciones 
          WHERE tipo = 'ENTREGA_SEMANA' 
            AND id_usuario IS NULL
            AND mensaje LIKE '%' || num_orden || '%' 
            AND fecha_creacion::date = CURRENT_DATE
      );

    -- =========================================================================
    -- REGLA 3: ATRASOS DE LOTES (Dirigido al Trabajador - id_usuario = UUID)
    -- =========================================================================
    INSERT INTO public.notificaciones (id_usuario, tipo, titulo, mensaje, prioridad)
    SELECT 
        t.id_usuario, 
        'ATRASO_LOTE', 
        '⚠️ Retraso en Producción', 
        'Llevas más de 24 horas con el lote ' || al.id_lote || ' sin terminar.',
        'advertencia'
    FROM public.asignaciones_lote al
    JOIN public.trabajadores t ON al.id_trabajador = t.id_trabajador
    WHERE al.id_estado_asignacion::text NOT IN ('3', 'terminado', 'Terminado')
      AND al.fecha_inicio < NOW() - INTERVAL '24 hours' 
      AND NOT EXISTS (
          SELECT 1 FROM public.notificaciones 
          WHERE tipo = 'ATRASO_LOTE' 
            AND id_usuario = t.id_usuario 
            AND mensaje LIKE '%' || al.id_lote || '%' 
            AND fecha_creacion::date = CURRENT_DATE
      );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generar_lista_compra(p_num_orden uuid, p_margen_merma numeric)
 RETURNS TABLE(insumo character varying, unidad character varying, total_prendas bigint, cantidad_neta numeric, total_a_comprar numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    WITH orden_resumen AS (
        SELECT num_orden, SUM(cantidad) AS suma_prendas
        FROM desglose_tallas
        WHERE num_orden = p_num_orden
        GROUP BY num_orden
    )
    
    SELECT
        i.nombre::VARCHAR,      
        um.nom_unidad::VARCHAR, 
        or_res.suma_prendas::BIGINT,
        
        -- CÁLCULO NETO: Si es unidad, redondea hacia arriba. Si no, deja decimal.
        CASE 
            WHEN um.nom_unidad ILIKE '%Unidad%' OR um.nom_unidad ILIKE '%Pieza%' 
            THEN CEIL(or_res.suma_prendas * rm.cantidad_estandar)::DECIMAL
            ELSE (or_res.suma_prendas * rm.cantidad_estandar)::DECIMAL
        END AS cantidad_neta,
        
        -- TOTAL A COMPRAR (CON MERMA): Si es unidad, colchón redondeado entero.
        CASE 
            WHEN um.nom_unidad ILIKE '%Unidad%' OR um.nom_unidad ILIKE '%Pieza%' 
            THEN CEIL((or_res.suma_prendas * rm.cantidad_estandar) * (1 + (p_margen_merma / 100.0)))::DECIMAL
            ELSE ((or_res.suma_prendas * rm.cantidad_estandar) * (1 + (p_margen_merma / 100.0)))::DECIMAL
        END AS total_a_comprar
        
    FROM orden_resumen or_res
    JOIN ficha_tecnica ft ON ft.num_orden = or_res.num_orden
    JOIN receta_material rm ON rm.id_ficha = ft.id_ficha
    JOIN insumo i ON i.id_insumo = rm.id_insumo         
    JOIN unidad_medida um ON um.id_unidad = i.id_unidad;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.generar_lotes_produccion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_num_orden UUID;         -- 👇 CORREGIDO: Ahora es UUID (antes era VARCHAR)
    v_id_plantilla UUID;      
    v_id_conjunto UUID;       
    r_plantilla_hija RECORD;  
BEGIN
    -- PASO 1: Buscar a qué detalle pertenece esta talla insertada
    SELECT 
        num_orden, 
        id_plantilla, 
        id_conjunto
    INTO 
        v_num_orden, 
        v_id_plantilla, 
        v_id_conjunto
    FROM 
        detalle_orden
    WHERE 
        id_detalle = NEW.id_detalle;

    -- PASO 2: Lógica de bifurcación
    IF v_id_conjunto IS NOT NULL THEN
        -- Es un conjunto
        FOR r_plantilla_hija IN (
            SELECT id_plantilla 
            FROM conjunto_plantilla 
            WHERE id_conjunto = v_id_conjunto
        ) 
        LOOP
            INSERT INTO lote (
                num_orden, 
                id_desglose, 
                id_plantilla, 
                cantidad_asignada, 
                id_estado_lote, 
                id_area_actual
            ) VALUES (
                v_num_orden, 
                NEW.id_desglose,          
                r_plantilla_hija.id_plantilla, 
                NEW.cantidad,             
                1,                        
                1                         
            );
        END LOOP;

    ELSIF v_id_plantilla IS NOT NULL THEN
        -- Es una plantilla suelta
        INSERT INTO lote (
            num_orden, 
            id_desglose, 
            id_plantilla, 
            cantidad_asignada, 
            id_estado_lote, 
            id_area_actual
        ) VALUES (
            v_num_orden, 
            NEW.id_desglose, 
            v_id_plantilla, 
            NEW.cantidad, 
            1, 
            1
        );
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.generar_solicitud_materiales(p_num_orden text, p_margen_merma numeric, p_id_estado_uso integer, p_id_asignacion uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Insertamos el resultado del cálculo directo a la "Sala de Espera"
    INSERT INTO solicitud_material_pendiente (
        num_orden,
        id_asignacion,
        id_insumo,
        cantidad_calculada
    )
    WITH orden_resumen AS (
        SELECT num_orden, SUM(cantidad) AS suma_prendas
        FROM desglose_tallas
        WHERE num_orden = p_num_orden
        GROUP BY num_orden
    )
    SELECT
        or_res.num_orden,
        p_id_asignacion,
        i.id_insumo,
        
        -- TU CÁLCULO (TOTAL A COMPRAR CON MERMA) que se guardará como la cantidad solicitada
        CASE 
            WHEN um.nom_unidad ILIKE '%Unidad%' OR um.nom_unidad ILIKE '%Pieza%' 
            THEN CEIL((or_res.suma_prendas * rm.cantidad_estandar) * (1 + (p_margen_merma / 100.0)))::DECIMAL
            ELSE ((or_res.suma_prendas * rm.cantidad_estandar) * (1 + (p_margen_merma / 100.0)))::DECIMAL
        END AS cantidad_calculada
        
    FROM orden_resumen or_res
    JOIN ficha_tecnica ft ON ft.num_orden = or_res.num_orden
    JOIN receta_material rm ON rm.id_ficha = ft.id_ficha
    JOIN insumo i ON i.id_insumo = rm.id_insumo         
    JOIN unidad_medida um ON um.id_unidad = i.id_unidad
    -- ESTA ES LA CLAVE: Solo calculamos insumos que pertenezcan a esta etapa
    WHERE i.id_estado_uso = p_id_estado_uso;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.gestionar_stock_por_movimiento()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_stock_actual NUMERIC(10,2);
    v_costo_actual NUMERIC(10,2);
    v_nuevo_stock NUMERIC(10,2);
    v_nuevo_costo_promedio NUMERIC(10,2);
    v_valor_inventario_actual NUMERIC(10,2);
    v_valor_ingreso_nuevo NUMERIC(10,2);
BEGIN
    -- 1. Obtenemos el stock y el costo promedio actual del catálogo
    SELECT stock_actual, costo_unitario 
    INTO v_stock_actual, v_costo_actual
    FROM public.insumo
    WHERE id_insumo = NEW.id_insumo;

    -- Si por alguna razón el costo actual es NULL, lo tratamos como 0
    IF v_costo_actual IS NULL THEN
        v_costo_actual := 0;
    END IF;

    -- 2. Lógica dependiendo si es ENTRADA (1) o SALIDA (2)
    IF NEW.id_estado_mov = 1 THEN
        -- ==========================================
        -- ENTRADA (COMPRA): Calcular nuevo costo promedio
        -- ==========================================
        
        -- Validar que el frontend haya mandado el costo (si no, asumimos 0)
        IF NEW.costo_unitario_transaccional IS NULL THEN
            NEW.costo_unitario_transaccional := 0;
        END IF;

        v_nuevo_stock := v_stock_actual + NEW.cantidad;
        
        -- Matemática del Costo Promedio Ponderado:
        v_valor_inventario_actual := v_stock_actual * v_costo_actual;
        v_valor_ingreso_nuevo := NEW.cantidad * NEW.costo_unitario_transaccional;

        -- Evitar división por cero
        IF v_nuevo_stock > 0 THEN
            v_nuevo_costo_promedio := (v_valor_inventario_actual + v_valor_ingreso_nuevo) / v_nuevo_stock;
        ELSE
            v_nuevo_costo_promedio := NEW.costo_unitario_transaccional;
        END IF;

        -- Actualizamos el catálogo con el nuevo stock y el nuevo costo promedio
        UPDATE public.insumo 
        SET stock_actual = v_nuevo_stock, 
            costo_unitario = v_nuevo_costo_promedio 
        WHERE id_insumo = NEW.id_insumo;

    ELSIF NEW.id_estado_mov = 2 THEN
        -- ==========================================
        -- SALIDA (CONSUMO): Usar costo promedio actual
        -- ==========================================
        
        -- Forzamos que la salida use el costo promedio del sistema, sin importar qué mande el frontend
        NEW.costo_unitario_transaccional := v_costo_actual;
        
        v_nuevo_stock := v_stock_actual - NEW.cantidad;
        
        -- Validamos que no quede stock negativo
        IF v_nuevo_stock < 0 THEN
            RAISE EXCEPTION 'Operación cancelada: Stock insuficiente. Disponible: %, Solicitado: %', 
                v_stock_actual, NEW.cantidad;
        END IF;
        
        -- Actualizamos solo el stock (el costo promedio NO cambia al sacar material)
        UPDATE public.insumo
        SET stock_actual = v_nuevo_stock
        WHERE id_insumo = NEW.id_insumo;
        
    ELSE
        -- Otros movimientos (Ajustes neutros)
        v_nuevo_stock := v_stock_actual;
    END IF;

    -- 3. Calculamos el subtotal real de la transacción para guardar el historial
    NEW.subtotal_movimiento := NEW.cantidad * NEW.costo_unitario_transaccional;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_mi_rol()
 RETURNS integer
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  SELECT id_rol FROM public.profiles WHERE id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  full_name_meta text;
  first_name text;
  last_name text;
BEGIN
  -- Extraemos el nombre completo de los metadatos de Google
  full_name_meta := new.raw_user_meta_data->>'full_name';
  
  -- Lógica de separación: tomamos la primera palabra como nombre y el resto como apellido
  IF full_name_meta IS NOT NULL AND full_name_meta <> '' THEN
    -- split_part obtiene la parte 1 separada por espacio
    first_name := split_part(full_name_meta, ' ', 1);
    -- substring obtiene todo lo que sigue después del primer espacio
    last_name := trim(substring(full_name_meta from position(' ' in full_name_meta)));
  ELSE
    -- Valores por defecto si no viene nombre
    first_name := 'Usuario';
    last_name := '';
  END IF;

  -- Insertamos en tu tabla profiles 
  INSERT INTO public.profiles (id, nombre, apellido, id_rol, activo)
  VALUES (
    new.id, 
    first_name, 
    NULLIF(last_name, ''), -- Si no hay apellido, guarda NULL 
    4,                     -- Tu id_rol por defecto para nuevos usuarios
    TRUE
  );
  RETURN new;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_sync_last_access()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Solo hace la copia si la fecha de inicio de sesión realmente cambió
  IF NEW.last_sign_in_at IS DISTINCT FROM OLD.last_sign_in_at THEN
    UPDATE public.profiles
    SET ultimo_acceso = NEW.last_sign_in_at
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_sync_user_email()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- Cuando se cree o modifique un usuario en auth.users, actualizamos su perfil
  UPDATE public.profiles
  SET email = NEW.email
  WHERE id = NEW.id;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.registrar_cliente_seguro(p_ci_cliente character varying, p_nom_cliente character varying, p_telefono character varying, p_direccion text)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id_cliente UUID;
BEGIN
    -- Intentar insertar el cliente
    INSERT INTO cliente (ci_cliente, nom_cliente, telefono, direccion) -- Actualizado aquí
    VALUES (p_ci_cliente, p_nom_cliente, p_telefono, p_direccion)
    RETURNING id_cliente INTO v_id_cliente;

    -- Si tiene éxito, devolver JSON con el ID
    RETURN json_build_object(
        'success', true,
        'message', 'Cliente registrado exitosamente.',
        'id_cliente', v_id_cliente
    );
EXCEPTION
    -- Atrapar el error 23505 (Violación de restricción UNIQUE)
    WHEN unique_violation THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error: El cliente con este C.I. ya existe en el sistema.'
        );
    -- Atrapar intentos de mandar C.I. o nombres nulos
    WHEN not_null_violation THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Error: El C.I. y el nombre son campos obligatorios.'
        );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.registrar_pago_orden(p_id_orden uuid, p_id_cliente uuid, p_monto numeric, p_metodo_pago text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_costo_total numeric;
  v_total_pagado numeric;
  v_nuevo_estado int;
BEGIN
  -- 1. Insertar el nuevo pago en el historial
  INSERT INTO pago_cliente (id_orden, id_cliente, monto, metodo_pago)
  VALUES (p_id_orden, p_id_cliente, p_monto, p_metodo_pago);

  -- 2. Obtener el costo total de la orden
  SELECT costo_total INTO v_costo_total 
  FROM orden WHERE num_orden = p_id_orden;

  -- 3. Calcular el total pagado sumando el nuevo pago y los anteriores
  SELECT COALESCE(SUM(monto), 0) INTO v_total_pagado 
  FROM pago_cliente WHERE id_orden = p_id_orden;

  -- 4. Determinar el nuevo estado de pago (3=Pagado, 2=Abonado)
  IF v_total_pagado >= v_costo_total THEN
    v_nuevo_estado := 3; 
  ELSE
    v_nuevo_estado := 2; 
  END IF;

  -- 5. Actualizar la cabecera de la orden
  UPDATE orden 
  SET id_estado_pago = v_nuevo_estado 
  WHERE num_orden = p_id_orden;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sincronizar_acceso_usuario()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- Si el administrador apaga el switch (activo = false)
    IF NEW.activo = false THEN
        -- Baneamos al usuario en el sistema de Auth (hasta el año 3000)
        UPDATE auth.users 
        SET banned_until = '3000-01-01 00:00:00'::timestamp 
        WHERE id = NEW.id; -- Nota: Cambia "NEW.id" por "NEW.id_perfil" si tu PK se llama distinto
        
    -- Si el administrador vuelve a encender el switch (activo = true)
    ELSE
        -- Quitamos el baneo
        UPDATE auth.users 
        SET banned_until = null 
        WHERE id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.sincronizar_estado_lote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_estado_actual_lote INT;
BEGIN
    -- Obtenemos el estado actual del lote
    SELECT id_estado_lote INTO v_estado_actual_lote FROM lote WHERE id_lote = NEW.id_lote;

    -- =========================================================================
    -- ESCENARIO A: NUEVA ASIGNACIÓN (El lote empieza a ser trabajado)
    -- =========================================================================
    IF TG_OP = 'INSERT' THEN
        
        IF v_estado_actual_lote = 1 THEN       -- Si estaba Pendiente
            -- Entra a Corte (Estado 2) y se mueve al Área de Corte (Asumiendo que es área 1)
            UPDATE lote SET id_estado_lote = 2, id_area_actual = 1 WHERE id_lote = NEW.id_lote; 
            
        ELSIF v_estado_actual_lote = 3 THEN    -- Si estaba Listo para Sublimado
            -- Entra a Sublimado (Estado 4) y se mueve al Área de Sublimado (Asumiendo que es área 2)
            UPDATE lote SET id_estado_lote = 4, id_area_actual = 2 WHERE id_lote = NEW.id_lote; 
            
        ELSIF v_estado_actual_lote = 5 THEN    -- Si estaba Listo para Confección
            -- Entra a Confección (Estado 6) y se mueve al Área de Confección (Asumiendo que es área 3)
            UPDATE lote SET id_estado_lote = 6, id_area_actual = 3 WHERE id_lote = NEW.id_lote; 
        END IF;

    -- =========================================================================
    -- ESCENARIO B: EL TRABAJADOR ACTUALIZA Y TERMINA SU PARTE
    -- =========================================================================
    ELSIF TG_OP = 'UPDATE' THEN
        
        -- Si el trabajador marcó su tarea como "Terminada"
        IF NEW.id_estado_asignacion::text IN ('3', 'terminado', 'Terminado') 
           AND OLD.id_estado_asignacion IS DISTINCT FROM NEW.id_estado_asignacion THEN
            
            IF v_estado_actual_lote = 2 THEN       
                -- Terminó Corte -> Pasa a Listo Sublimado (3) y se mueve al área Sublimado (2)
                UPDATE lote SET id_estado_lote = 3, id_area_actual = 2 WHERE id_lote = NEW.id_lote; 
                
            ELSIF v_estado_actual_lote = 4 THEN    
                -- Terminó Sublimado -> Pasa a Listo Confección (5) y se mueve al área Confección (3)
                UPDATE lote SET id_estado_lote = 5, id_area_actual = 3 WHERE id_lote = NEW.id_lote; 
                
            ELSIF v_estado_actual_lote = 6 THEN    
                -- Terminó Confección -> Pasa a Terminado (7) y se mueve al área de Ventas/Cajas (4)
                UPDATE lote SET id_estado_lote = 7, id_area_actual = 4 WHERE id_lote = NEW.id_lote; 
            END IF;

        END IF;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.tg_notificar_nueva_asignacion()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_id_usuario UUID;
BEGIN
    -- Buscamos el id_usuario (UUID de la app) del trabajador que recibe el lote
    SELECT id_usuario INTO v_id_usuario
    FROM public.trabajadores
    WHERE id_trabajador = NEW.id_trabajador;

    -- Si el trabajador tiene una cuenta de usuario vinculada, creamos la alerta
    IF v_id_usuario IS NOT NULL THEN
        INSERT INTO public.notificaciones (id_usuario, tipo, titulo, mensaje, prioridad)
        VALUES (
            v_id_usuario,
            'NUEVA_ASIGNACION',
            '📋 Nuevo trabajo asignado',
            'Se te ha asignado el lote ' || NEW.id_lote || '. Por favor revisa tus tareas.',
            'informativa' -- Es un aviso, por eso prioridad informativa
        );
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.verificar_insumo_activo()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_activo BOOLEAN;
BEGIN
    -- Leemos el campo activo directamente
    SELECT activo INTO v_activo 
    FROM public.insumo 
    WHERE id_insumo = NEW.id_insumo;
    
    -- Si es false, bloqueamos
    IF v_activo = false THEN 
        RAISE EXCEPTION 'Operación rechazada: El insumo "%" está inactivo y no puede usarse en recetas.', NEW.id_insumo;
    END IF;

    RETURN NEW;
END;
$function$
;


