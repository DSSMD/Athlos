create extension if not exists "pg_cron" with schema "pg_catalog";

create schema if not exists "api";

create sequence "public"."area_produccion_id_area_seq";

create sequence "public"."cat_tipo_cliente_id_tipo_cliente_seq";

create sequence "public"."categoria_insumo_id_categoria_seq";

create sequence "public"."estado_asignacion_id_estado_asignacion_seq";

create sequence "public"."estado_lote_id_estado_lote_seq";

create sequence "public"."estado_movimiento_id_estado_mov_seq";

create sequence "public"."estado_orden_id_estado_seq";

create sequence "public"."estado_pago_id_estado_pago_seq";

create sequence "public"."flujo_estado_lote_id_flujo_seq";

create sequence "public"."historial_estado_lote_id_historial_seq";

create sequence "public"."receta_material_id_receta_seq";

create sequence "public"."roles_id_rol_seq";

create sequence "public"."tallas_id_talla_seq";

create sequence "public"."tipo_prenda_id_tipo_prenda_seq";

create sequence "public"."unidad_medida_id_unidad_seq";


  create table "public"."area_produccion" (
    "id_area" integer not null default nextval('public.area_produccion_id_area_seq'::regclass),
    "nombre_area" character varying(50) not null
      );


alter table "public"."area_produccion" enable row level security;


  create table "public"."asignaciones_lote" (
    "id_asignacion" uuid not null default gen_random_uuid(),
    "id_lote" uuid not null,
    "id_trabajador" uuid not null,
    "fecha_inicio" timestamp with time zone default now(),
    "id_estado_asignacion" integer not null,
    "fecha_fin" timestamp with time zone,
    "monto_acordado" numeric(10,2) not null default 0.00,
    "estado_pago" character varying(20) default 'Pendiente'::character varying
      );



  create table "public"."auditoria_ordenes" (
    "id_log" uuid not null default gen_random_uuid(),
    "num_orden" uuid,
    "id_usuario" uuid,
    "fecha_cambio" timestamp with time zone default now(),
    "descripcion_detalle" text,
    "estado_anterior_id" integer,
    "estado_nuevo_id" integer
      );


alter table "public"."auditoria_ordenes" enable row level security;


  create table "public"."cat_tipo_cliente" (
    "id_tipo_cliente" integer not null default nextval('public.cat_tipo_cliente_id_tipo_cliente_seq'::regclass),
    "nombre_tipo" text not null
      );


alter table "public"."cat_tipo_cliente" enable row level security;


  create table "public"."categoria_insumo" (
    "id_categoria" integer not null default nextval('public.categoria_insumo_id_categoria_seq'::regclass),
    "nombre_categoria" text not null
      );


alter table "public"."categoria_insumo" enable row level security;


  create table "public"."categoria_unidad" (
    "id_categoria" integer not null,
    "id_unidad" integer not null
      );


alter table "public"."categoria_unidad" enable row level security;


  create table "public"."cliente" (
    "id_cliente" uuid not null default gen_random_uuid(),
    "ci_cliente" text not null,
    "nom_cliente" text not null,
    "apellido_cliente" text not null,
    "num_telefono" text,
    "created_at" timestamp with time zone default now(),
    "direccion" text,
    "id_tipo_cliente" integer default 1,
    "razon_social" text,
    "email" text,
    "num_telefono_2" text,
    "permite_credito" boolean default false,
    "limite_credito" numeric(10,2) default 0.00,
    "dias_plazo_pago" integer default 30,
    "es_prioritario" boolean default false,
    "notas" text,
    "activo" boolean default true,
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."cliente" enable row level security;


  create table "public"."conjunto" (
    "id_conjunto" uuid not null default gen_random_uuid(),
    "nombre" character varying(150) not null,
    "descripcion" text,
    "activo" boolean not null default true,
    "created_at" timestamp without time zone not null default now(),
    "precio_conjunto" numeric not null default 0.00
      );


alter table "public"."conjunto" enable row level security;


  create table "public"."conjunto_plantilla" (
    "id_cp" uuid not null default gen_random_uuid(),
    "id_conjunto" uuid not null,
    "id_plantilla" uuid not null,
    "cantidad_por_conjunto" integer not null default 1
      );


alter table "public"."conjunto_plantilla" enable row level security;


  create table "public"."detalle_orden" (
    "id_detalle" uuid not null default gen_random_uuid(),
    "num_orden" uuid not null,
    "id_conjunto" uuid,
    "id_plantilla" uuid,
    "cantidad_total" integer not null,
    "precio_unitario" numeric(10,2) not null,
    "subtotal" numeric(10,2) not null
      );


alter table "public"."detalle_orden" enable row level security;


  create table "public"."detalle_orden_talla" (
    "id_desglose" uuid not null default gen_random_uuid(),
    "id_detalle" uuid not null,
    "id_talla" integer not null,
    "cantidad" integer not null
      );


alter table "public"."detalle_orden_talla" enable row level security;


  create table "public"."estado_asignacion" (
    "id_estado_asignacion" integer not null default nextval('public.estado_asignacion_id_estado_asignacion_seq'::regclass),
    "nombre_estado" character varying(50) not null,
    "descripcion" text
      );


alter table "public"."estado_asignacion" enable row level security;


  create table "public"."estado_lote" (
    "id_estado_lote" integer not null default nextval('public.estado_lote_id_estado_lote_seq'::regclass),
    "nombre_estado" character varying(50) not null,
    "descripcion" text
      );


alter table "public"."estado_lote" enable row level security;


  create table "public"."estado_movimiento" (
    "id_estado_mov" integer not null default nextval('public.estado_movimiento_id_estado_mov_seq'::regclass),
    "nombre_movimiento" character varying(50) not null,
    "descripcion" text
      );


alter table "public"."estado_movimiento" enable row level security;


  create table "public"."estado_orden" (
    "id_estado" integer not null default nextval('public.estado_orden_id_estado_seq'::regclass),
    "nombre_estado" character varying(50) not null,
    "descripcion" text
      );



  create table "public"."estado_pago" (
    "id_estado_pago" integer not null default nextval('public.estado_pago_id_estado_pago_seq'::regclass),
    "nombre_estado" character varying(50) not null,
    "descripcion" text
      );



  create table "public"."flujo_estado_lote" (
    "id_flujo" integer not null default nextval('public.flujo_estado_lote_id_flujo_seq'::regclass),
    "id_estado_actual" integer not null,
    "id_estado_siguiente" integer not null
      );


alter table "public"."flujo_estado_lote" enable row level security;


  create table "public"."historial_estado_lote" (
    "id_historial" integer not null default nextval('public.historial_estado_lote_id_historial_seq'::regclass),
    "id_lote" uuid not null,
    "id_estado" integer not null,
    "fecha" timestamp without time zone default now()
      );


alter table "public"."historial_estado_lote" enable row level security;


  create table "public"."insumo" (
    "id_insumo" uuid not null default gen_random_uuid(),
    "nombre" text not null,
    "stock_actual" numeric(10,2) default 0,
    "stock_minimo" numeric(10,2) default 0,
    "costo_unitario" numeric(10,2) default 0.00,
    "id_unidad" integer not null,
    "atributos_tecnicos" jsonb,
    "activo" boolean not null default true,
    "id_categoria" integer,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."insumo" enable row level security;


  create table "public"."lote" (
    "id_lote" uuid not null default gen_random_uuid(),
    "num_orden" uuid,
    "id_estado_lote" integer,
    "cantidad_asignada" integer not null,
    "id_desglose" uuid,
    "id_area_actual" integer,
    "id_plantilla" uuid not null
      );


alter table "public"."lote" enable row level security;


  create table "public"."medida_ficha" (
    "id_medida" uuid not null default gen_random_uuid(),
    "id_plantilla" uuid not null,
    "id_talla" integer not null,
    "nombre_medida" text not null,
    "valor" numeric not null
      );



  create table "public"."movimiento_insumo" (
    "id_movimiento" uuid not null default gen_random_uuid(),
    "id_insumo" uuid not null,
    "id_estado_mov" integer not null,
    "id_usuario" uuid not null,
    "cantidad" numeric(10,2) not null,
    "fecha" timestamp with time zone default now(),
    "motivo" text,
    "costo_unitario_transaccional" numeric(10,2) not null,
    "subtotal_movimiento" numeric default 0
      );



  create table "public"."notificaciones" (
    "id_notificacion" uuid not null default gen_random_uuid(),
    "id_usuario" uuid,
    "tipo" character varying(50),
    "titulo" character varying(150),
    "mensaje" text,
    "leida" boolean default false,
    "fecha_creacion" timestamp with time zone default now(),
    "prioridad" character varying(20)
      );



  create table "public"."orden" (
    "num_orden" uuid not null default gen_random_uuid(),
    "id_cliente" uuid,
    "id_estado" integer not null default 1,
    "id_estado_pago" integer,
    "fecha_orden" timestamp with time zone default now(),
    "fecha_entrega" date not null,
    "tiempo_procesamiento_estimado" numeric(5,2),
    "costo_total" numeric(10,2) default 0.00,
    "notas_adicionales" text,
    "updated_at" timestamp with time zone default now(),
    "created_at" timestamp with time zone default now(),
    "imagen_modelo" text,
    "prioridad" text not null default 'normal'::text
      );


alter table "public"."orden" enable row level security;


  create table "public"."pago_cliente" (
    "id_pago" uuid not null default gen_random_uuid(),
    "id_cliente" uuid,
    "id_orden" uuid,
    "monto" numeric(10,2) not null,
    "fecha_pago" timestamp with time zone default now(),
    "metodo_pago" text
      );



  create table "public"."pagos_trabajador" (
    "id_pago" uuid not null default gen_random_uuid(),
    "id_trabajador" uuid not null,
    "id_asignacion" uuid,
    "monto" numeric(10,2) not null,
    "fecha_pago" timestamp with time zone default now(),
    "tipo_pago" character varying(30) default 'Adelanto'::character varying,
    "notas" text
      );


alter table "public"."pagos_trabajador" enable row level security;


  create table "public"."plantilla_prenda" (
    "id_plantilla" uuid not null default gen_random_uuid(),
    "id_tipo_prenda" integer not null,
    "especificaciones" text,
    "nombre" text not null,
    "version" integer not null default 1,
    "activo" boolean not null default true,
    "created_at" timestamp without time zone default now(),
    "precio_plantilla" numeric not null default 0.00
      );


alter table "public"."plantilla_prenda" enable row level security;


  create table "public"."profiles" (
    "id" uuid not null,
    "nombre" text not null,
    "apellido" text,
    "telefono" text,
    "ci" text,
    "id_rol" integer,
    "activo" boolean not null default true,
    "created_at" timestamp without time zone default now(),
    "updated_at" timestamp with time zone default now(),
    "email" text,
    "ultimo_acceso" timestamp with time zone
      );


alter table "public"."profiles" enable row level security;


  create table "public"."receta_material" (
    "id_receta" integer not null default nextval('public.receta_material_id_receta_seq'::regclass),
    "id_plantilla" uuid not null,
    "id_insumo" uuid not null,
    "cantidad_requerida" numeric not null
      );



  create table "public"."roles" (
    "id_rol" integer not null default nextval('public.roles_id_rol_seq'::regclass),
    "nombre_rol" text not null
      );


alter table "public"."roles" enable row level security;


  create table "public"."tallas" (
    "id_talla" integer not null default nextval('public.tallas_id_talla_seq'::regclass),
    "nombre_talla" character varying(10) not null,
    "descripcion" text
      );


alter table "public"."tallas" enable row level security;


  create table "public"."tipo_prenda" (
    "id_tipo_prenda" integer not null default nextval('public.tipo_prenda_id_tipo_prenda_seq'::regclass),
    "nombre_prenda" character varying(100) not null,
    "descripcion" text,
    "categoria_prenda" character varying(50) default 'General'::character varying
      );


alter table "public"."tipo_prenda" enable row level security;


  create table "public"."trabajadores" (
    "id_trabajador" uuid not null default gen_random_uuid(),
    "id_usuario" uuid,
    "fecha_contratacion" date default CURRENT_DATE,
    "tarifa_pago_base" numeric(10,2) default 0.00,
    "id_area" integer
      );


alter table "public"."trabajadores" enable row level security;


  create table "public"."unidad_medida" (
    "id_unidad" integer not null default nextval('public.unidad_medida_id_unidad_seq'::regclass),
    "nom_unidad" character varying(20) not null,
    "abreviatura" character varying(5)
      );


alter table "public"."unidad_medida" enable row level security;

alter sequence "public"."area_produccion_id_area_seq" owned by "public"."area_produccion"."id_area";

alter sequence "public"."cat_tipo_cliente_id_tipo_cliente_seq" owned by "public"."cat_tipo_cliente"."id_tipo_cliente";

alter sequence "public"."categoria_insumo_id_categoria_seq" owned by "public"."categoria_insumo"."id_categoria";

alter sequence "public"."estado_asignacion_id_estado_asignacion_seq" owned by "public"."estado_asignacion"."id_estado_asignacion";

alter sequence "public"."estado_lote_id_estado_lote_seq" owned by "public"."estado_lote"."id_estado_lote";

alter sequence "public"."estado_movimiento_id_estado_mov_seq" owned by "public"."estado_movimiento"."id_estado_mov";

alter sequence "public"."estado_orden_id_estado_seq" owned by "public"."estado_orden"."id_estado";

alter sequence "public"."estado_pago_id_estado_pago_seq" owned by "public"."estado_pago"."id_estado_pago";

alter sequence "public"."flujo_estado_lote_id_flujo_seq" owned by "public"."flujo_estado_lote"."id_flujo";

alter sequence "public"."historial_estado_lote_id_historial_seq" owned by "public"."historial_estado_lote"."id_historial";

alter sequence "public"."receta_material_id_receta_seq" owned by "public"."receta_material"."id_receta";

alter sequence "public"."roles_id_rol_seq" owned by "public"."roles"."id_rol";

alter sequence "public"."tallas_id_talla_seq" owned by "public"."tallas"."id_talla";

alter sequence "public"."tipo_prenda_id_tipo_prenda_seq" owned by "public"."tipo_prenda"."id_tipo_prenda";

alter sequence "public"."unidad_medida_id_unidad_seq" owned by "public"."unidad_medida"."id_unidad";

CREATE UNIQUE INDEX area_produccion_pkey ON public.area_produccion USING btree (id_area);

CREATE UNIQUE INDEX asignaciones_lote_pkey ON public.asignaciones_lote USING btree (id_asignacion);

CREATE UNIQUE INDEX auditoria_ordenes_pkey ON public.auditoria_ordenes USING btree (id_log);

CREATE UNIQUE INDEX cat_tipo_cliente_nombre_tipo_key ON public.cat_tipo_cliente USING btree (nombre_tipo);

CREATE UNIQUE INDEX cat_tipo_cliente_pkey ON public.cat_tipo_cliente USING btree (id_tipo_cliente);

CREATE UNIQUE INDEX categoria_insumo_nombre_categoria_key ON public.categoria_insumo USING btree (nombre_categoria);

CREATE UNIQUE INDEX categoria_insumo_pkey ON public.categoria_insumo USING btree (id_categoria);

CREATE UNIQUE INDEX categoria_unidad_pkey ON public.categoria_unidad USING btree (id_categoria, id_unidad);

CREATE UNIQUE INDEX cliente_ci_cliente_key ON public.cliente USING btree (ci_cliente);

CREATE UNIQUE INDEX cliente_pkey ON public.cliente USING btree (id_cliente);

CREATE UNIQUE INDEX conjunto_pkey ON public.conjunto USING btree (id_conjunto);

CREATE UNIQUE INDEX conjunto_plantilla_pkey ON public.conjunto_plantilla USING btree (id_cp);

CREATE UNIQUE INDEX detalle_orden_pkey ON public.detalle_orden USING btree (id_detalle);

CREATE UNIQUE INDEX detalle_orden_talla_pkey ON public.detalle_orden_talla USING btree (id_desglose);

CREATE UNIQUE INDEX estado_asignacion_pkey ON public.estado_asignacion USING btree (id_estado_asignacion);

CREATE UNIQUE INDEX estado_lote_pkey ON public.estado_lote USING btree (id_estado_lote);

CREATE UNIQUE INDEX estado_movimiento_pkey ON public.estado_movimiento USING btree (id_estado_mov);

CREATE UNIQUE INDEX estado_orden_pkey ON public.estado_orden USING btree (id_estado);

CREATE UNIQUE INDEX estado_pago_pkey ON public.estado_pago USING btree (id_estado_pago);

CREATE UNIQUE INDEX flujo_estado_lote_pkey ON public.flujo_estado_lote USING btree (id_flujo);

CREATE UNIQUE INDEX historial_estado_lote_pkey ON public.historial_estado_lote USING btree (id_historial);

CREATE INDEX idx_asignaciones_lote_activas ON public.asignaciones_lote USING btree (id_lote) WHERE (fecha_fin IS NULL);

CREATE INDEX idx_asignaciones_lote_lote_fechafin ON public.asignaciones_lote USING btree (id_lote, fecha_fin);

CREATE INDEX idx_busqueda_ci ON public.cliente USING btree (ci_cliente);

CREATE INDEX idx_historial_estado_lote_id_lote ON public.historial_estado_lote USING btree (id_lote);

CREATE INDEX idx_insumo_activo ON public.insumo USING btree (activo) WHERE (activo = true);

CREATE INDEX idx_insumo_atributos_jsonb ON public.insumo USING gin (atributos_tecnicos);

CREATE INDEX idx_insumo_bajo_stock ON public.insumo USING btree (stock_actual) WHERE (stock_actual <= stock_minimo);

CREATE INDEX idx_insumo_id_categoria ON public.insumo USING btree (id_categoria);

CREATE INDEX idx_insumo_id_unidad ON public.insumo USING btree (id_unidad);

CREATE INDEX idx_insumo_nombre ON public.insumo USING btree (nombre);

CREATE INDEX idx_lote_id_desglose ON public.lote USING btree (id_desglose);

CREATE INDEX idx_lote_id_estado_lote ON public.lote USING btree (id_estado_lote);

CREATE INDEX idx_medida_plantilla ON public.medida_ficha USING btree (id_plantilla);

CREATE INDEX idx_receta_plantilla ON public.receta_material USING btree (id_plantilla);

CREATE UNIQUE INDEX insumo_pkey ON public.insumo USING btree (id_insumo);

CREATE UNIQUE INDEX lote_pkey ON public.lote USING btree (id_lote);

CREATE UNIQUE INDEX medida_ficha_pkey ON public.medida_ficha USING btree (id_medida);

CREATE UNIQUE INDEX movimiento_insumo_pkey ON public.movimiento_insumo USING btree (id_movimiento);

CREATE UNIQUE INDEX notificaciones_pkey ON public.notificaciones USING btree (id_notificacion);

CREATE UNIQUE INDEX orden_pkey ON public.orden USING btree (num_orden);

CREATE UNIQUE INDEX pago_cliente_pkey ON public.pago_cliente USING btree (id_pago);

CREATE UNIQUE INDEX pagos_trabajador_pkey ON public.pagos_trabajador USING btree (id_pago);

CREATE UNIQUE INDEX plantilla_prenda_pkey ON public.plantilla_prenda USING btree (id_plantilla);

CREATE UNIQUE INDEX profiles_ci_key ON public.profiles USING btree (ci);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

CREATE UNIQUE INDEX receta_material_pkey ON public.receta_material USING btree (id_receta);

CREATE UNIQUE INDEX roles_nombre_key ON public.roles USING btree (nombre_rol);

CREATE UNIQUE INDEX roles_pkey ON public.roles USING btree (id_rol);

CREATE UNIQUE INDEX tallas_pkey ON public.tallas USING btree (id_talla);

CREATE UNIQUE INDEX tipo_prenda_pkey ON public.tipo_prenda USING btree (id_tipo_prenda);

CREATE UNIQUE INDEX trabajadores_pkey ON public.trabajadores USING btree (id_trabajador);

CREATE UNIQUE INDEX unidad_medida_nom_unidad_key ON public.unidad_medida USING btree (nom_unidad);

CREATE UNIQUE INDEX unidad_medida_pkey ON public.unidad_medida USING btree (id_unidad);

CREATE UNIQUE INDEX unique_medida_plantilla ON public.medida_ficha USING btree (id_plantilla, id_talla, nombre_medida);

CREATE UNIQUE INDEX unique_plantilla_en_conjunto ON public.conjunto_plantilla USING btree (id_conjunto, id_plantilla);

CREATE UNIQUE INDEX unique_plantilla_insumo ON public.receta_material USING btree (id_plantilla, id_insumo);

alter table "public"."area_produccion" add constraint "area_produccion_pkey" PRIMARY KEY using index "area_produccion_pkey";

alter table "public"."asignaciones_lote" add constraint "asignaciones_lote_pkey" PRIMARY KEY using index "asignaciones_lote_pkey";

alter table "public"."auditoria_ordenes" add constraint "auditoria_ordenes_pkey" PRIMARY KEY using index "auditoria_ordenes_pkey";

alter table "public"."cat_tipo_cliente" add constraint "cat_tipo_cliente_pkey" PRIMARY KEY using index "cat_tipo_cliente_pkey";

alter table "public"."categoria_insumo" add constraint "categoria_insumo_pkey" PRIMARY KEY using index "categoria_insumo_pkey";

alter table "public"."categoria_unidad" add constraint "categoria_unidad_pkey" PRIMARY KEY using index "categoria_unidad_pkey";

alter table "public"."cliente" add constraint "cliente_pkey" PRIMARY KEY using index "cliente_pkey";

alter table "public"."conjunto" add constraint "conjunto_pkey" PRIMARY KEY using index "conjunto_pkey";

alter table "public"."conjunto_plantilla" add constraint "conjunto_plantilla_pkey" PRIMARY KEY using index "conjunto_plantilla_pkey";

alter table "public"."detalle_orden" add constraint "detalle_orden_pkey" PRIMARY KEY using index "detalle_orden_pkey";

alter table "public"."detalle_orden_talla" add constraint "detalle_orden_talla_pkey" PRIMARY KEY using index "detalle_orden_talla_pkey";

alter table "public"."estado_asignacion" add constraint "estado_asignacion_pkey" PRIMARY KEY using index "estado_asignacion_pkey";

alter table "public"."estado_lote" add constraint "estado_lote_pkey" PRIMARY KEY using index "estado_lote_pkey";

alter table "public"."estado_movimiento" add constraint "estado_movimiento_pkey" PRIMARY KEY using index "estado_movimiento_pkey";

alter table "public"."estado_orden" add constraint "estado_orden_pkey" PRIMARY KEY using index "estado_orden_pkey";

alter table "public"."estado_pago" add constraint "estado_pago_pkey" PRIMARY KEY using index "estado_pago_pkey";

alter table "public"."flujo_estado_lote" add constraint "flujo_estado_lote_pkey" PRIMARY KEY using index "flujo_estado_lote_pkey";

alter table "public"."historial_estado_lote" add constraint "historial_estado_lote_pkey" PRIMARY KEY using index "historial_estado_lote_pkey";

alter table "public"."insumo" add constraint "insumo_pkey" PRIMARY KEY using index "insumo_pkey";

alter table "public"."lote" add constraint "lote_pkey" PRIMARY KEY using index "lote_pkey";

alter table "public"."medida_ficha" add constraint "medida_ficha_pkey" PRIMARY KEY using index "medida_ficha_pkey";

alter table "public"."movimiento_insumo" add constraint "movimiento_insumo_pkey" PRIMARY KEY using index "movimiento_insumo_pkey";

alter table "public"."notificaciones" add constraint "notificaciones_pkey" PRIMARY KEY using index "notificaciones_pkey";

alter table "public"."orden" add constraint "orden_pkey" PRIMARY KEY using index "orden_pkey";

alter table "public"."pago_cliente" add constraint "pago_cliente_pkey" PRIMARY KEY using index "pago_cliente_pkey";

alter table "public"."pagos_trabajador" add constraint "pagos_trabajador_pkey" PRIMARY KEY using index "pagos_trabajador_pkey";

alter table "public"."plantilla_prenda" add constraint "plantilla_prenda_pkey" PRIMARY KEY using index "plantilla_prenda_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."receta_material" add constraint "receta_material_pkey" PRIMARY KEY using index "receta_material_pkey";

alter table "public"."roles" add constraint "roles_pkey" PRIMARY KEY using index "roles_pkey";

alter table "public"."tallas" add constraint "tallas_pkey" PRIMARY KEY using index "tallas_pkey";

alter table "public"."tipo_prenda" add constraint "tipo_prenda_pkey" PRIMARY KEY using index "tipo_prenda_pkey";

alter table "public"."trabajadores" add constraint "trabajadores_pkey" PRIMARY KEY using index "trabajadores_pkey";

alter table "public"."unidad_medida" add constraint "unidad_medida_pkey" PRIMARY KEY using index "unidad_medida_pkey";

alter table "public"."asignaciones_lote" add constraint "asignaciones_lote_id_lote_fkey" FOREIGN KEY (id_lote) REFERENCES public.lote(id_lote) ON DELETE CASCADE not valid;

alter table "public"."asignaciones_lote" validate constraint "asignaciones_lote_id_lote_fkey";

alter table "public"."asignaciones_lote" add constraint "asignaciones_lote_id_trabajador_fkey" FOREIGN KEY (id_trabajador) REFERENCES public.trabajadores(id_trabajador) not valid;

alter table "public"."asignaciones_lote" validate constraint "asignaciones_lote_id_trabajador_fkey";

alter table "public"."asignaciones_lote" add constraint "fk_asignacion_estado" FOREIGN KEY (id_estado_asignacion) REFERENCES public.estado_asignacion(id_estado_asignacion) not valid;

alter table "public"."asignaciones_lote" validate constraint "fk_asignacion_estado";

alter table "public"."auditoria_ordenes" add constraint "auditoria_estado_anterior_fkey" FOREIGN KEY (estado_anterior_id) REFERENCES public.estado_orden(id_estado) not valid;

alter table "public"."auditoria_ordenes" validate constraint "auditoria_estado_anterior_fkey";

alter table "public"."auditoria_ordenes" add constraint "auditoria_estado_nuevo_fkey" FOREIGN KEY (estado_nuevo_id) REFERENCES public.estado_orden(id_estado) not valid;

alter table "public"."auditoria_ordenes" validate constraint "auditoria_estado_nuevo_fkey";

alter table "public"."auditoria_ordenes" add constraint "auditoria_ordenes_id_usuario_fkey" FOREIGN KEY (id_usuario) REFERENCES public.profiles(id) not valid;

alter table "public"."auditoria_ordenes" validate constraint "auditoria_ordenes_id_usuario_fkey";

alter table "public"."auditoria_ordenes" add constraint "auditoria_ordenes_num_orden_fkey" FOREIGN KEY (num_orden) REFERENCES public.orden(num_orden) ON DELETE CASCADE not valid;

alter table "public"."auditoria_ordenes" validate constraint "auditoria_ordenes_num_orden_fkey";

alter table "public"."cat_tipo_cliente" add constraint "cat_tipo_cliente_nombre_tipo_key" UNIQUE using index "cat_tipo_cliente_nombre_tipo_key";

alter table "public"."categoria_insumo" add constraint "categoria_insumo_nombre_categoria_key" UNIQUE using index "categoria_insumo_nombre_categoria_key";

alter table "public"."categoria_unidad" add constraint "categoria_unidad_id_categoria_fkey" FOREIGN KEY (id_categoria) REFERENCES public.categoria_insumo(id_categoria) ON DELETE CASCADE not valid;

alter table "public"."categoria_unidad" validate constraint "categoria_unidad_id_categoria_fkey";

alter table "public"."categoria_unidad" add constraint "categoria_unidad_id_unidad_fkey" FOREIGN KEY (id_unidad) REFERENCES public.unidad_medida(id_unidad) ON DELETE CASCADE not valid;

alter table "public"."categoria_unidad" validate constraint "categoria_unidad_id_unidad_fkey";

alter table "public"."cliente" add constraint "chk_ci_length" CHECK ((length(TRIM(BOTH FROM ci_cliente)) >= 5)) not valid;

alter table "public"."cliente" validate constraint "chk_ci_length";

alter table "public"."cliente" add constraint "chk_email_format" CHECK (((email IS NULL) OR (email = ''::text) OR (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text))) not valid;

alter table "public"."cliente" validate constraint "chk_email_format";

alter table "public"."cliente" add constraint "chk_limite_credito_max" CHECK (((permite_credito = false) OR ((permite_credito = true) AND (limite_credito >= (0)::numeric) AND (limite_credito <= (500000)::numeric)))) not valid;

alter table "public"."cliente" validate constraint "chk_limite_credito_max";

alter table "public"."cliente" add constraint "chk_telefono_internacional" CHECK (((num_telefono IS NULL) OR (num_telefono = ''::text) OR (num_telefono ~ '^\+[1-9][0-9]{7,14}$'::text))) not valid;

alter table "public"."cliente" validate constraint "chk_telefono_internacional";

alter table "public"."cliente" add constraint "cliente_ci_cliente_key" UNIQUE using index "cliente_ci_cliente_key";

alter table "public"."cliente" add constraint "cliente_id_tipo_cliente_fkey" FOREIGN KEY (id_tipo_cliente) REFERENCES public.cat_tipo_cliente(id_tipo_cliente) not valid;

alter table "public"."cliente" validate constraint "cliente_id_tipo_cliente_fkey";

alter table "public"."conjunto_plantilla" add constraint "fk_cp_conjunto" FOREIGN KEY (id_conjunto) REFERENCES public.conjunto(id_conjunto) ON DELETE CASCADE not valid;

alter table "public"."conjunto_plantilla" validate constraint "fk_cp_conjunto";

alter table "public"."conjunto_plantilla" add constraint "fk_cp_plantilla" FOREIGN KEY (id_plantilla) REFERENCES public.plantilla_prenda(id_plantilla) ON DELETE RESTRICT not valid;

alter table "public"."conjunto_plantilla" validate constraint "fk_cp_plantilla";

alter table "public"."conjunto_plantilla" add constraint "unique_plantilla_en_conjunto" UNIQUE using index "unique_plantilla_en_conjunto";

alter table "public"."detalle_orden" add constraint "chk_do_tipo_exclusivo" CHECK ((((id_conjunto IS NOT NULL) AND (id_plantilla IS NULL)) OR ((id_conjunto IS NULL) AND (id_plantilla IS NOT NULL)))) not valid;

alter table "public"."detalle_orden" validate constraint "chk_do_tipo_exclusivo";

alter table "public"."detalle_orden" add constraint "chk_item_exclusivo" CHECK ((((id_conjunto IS NOT NULL) AND (id_plantilla IS NULL)) OR ((id_conjunto IS NULL) AND (id_plantilla IS NOT NULL)))) not valid;

alter table "public"."detalle_orden" validate constraint "chk_item_exclusivo";

alter table "public"."detalle_orden" add constraint "fk_do_conjunto" FOREIGN KEY (id_conjunto) REFERENCES public.conjunto(id_conjunto) ON DELETE RESTRICT not valid;

alter table "public"."detalle_orden" validate constraint "fk_do_conjunto";

alter table "public"."detalle_orden" add constraint "fk_do_orden" FOREIGN KEY (num_orden) REFERENCES public.orden(num_orden) ON DELETE CASCADE not valid;

alter table "public"."detalle_orden" validate constraint "fk_do_orden";

alter table "public"."detalle_orden" add constraint "fk_do_plantilla" FOREIGN KEY (id_plantilla) REFERENCES public.plantilla_prenda(id_plantilla) ON DELETE RESTRICT not valid;

alter table "public"."detalle_orden" validate constraint "fk_do_plantilla";

alter table "public"."detalle_orden_talla" add constraint "fk_dot_detalle" FOREIGN KEY (id_detalle) REFERENCES public.detalle_orden(id_detalle) ON DELETE CASCADE not valid;

alter table "public"."detalle_orden_talla" validate constraint "fk_dot_detalle";

alter table "public"."detalle_orden_talla" add constraint "fk_dot_talla" FOREIGN KEY (id_talla) REFERENCES public.tallas(id_talla) ON DELETE RESTRICT not valid;

alter table "public"."detalle_orden_talla" validate constraint "fk_dot_talla";

alter table "public"."flujo_estado_lote" add constraint "fk_flujo_actual" FOREIGN KEY (id_estado_actual) REFERENCES public.estado_lote(id_estado_lote) not valid;

alter table "public"."flujo_estado_lote" validate constraint "fk_flujo_actual";

alter table "public"."flujo_estado_lote" add constraint "fk_flujo_siguiente" FOREIGN KEY (id_estado_siguiente) REFERENCES public.estado_lote(id_estado_lote) not valid;

alter table "public"."flujo_estado_lote" validate constraint "fk_flujo_siguiente";

alter table "public"."historial_estado_lote" add constraint "historial_estado_lote_id_estado_fkey" FOREIGN KEY (id_estado) REFERENCES public.estado_lote(id_estado_lote) not valid;

alter table "public"."historial_estado_lote" validate constraint "historial_estado_lote_id_estado_fkey";

alter table "public"."historial_estado_lote" add constraint "historial_estado_lote_id_lote_fkey" FOREIGN KEY (id_lote) REFERENCES public.lote(id_lote) ON DELETE CASCADE not valid;

alter table "public"."historial_estado_lote" validate constraint "historial_estado_lote_id_lote_fkey";

alter table "public"."insumo" add constraint "chk_stock_no_negativo" CHECK ((stock_actual >= (0)::numeric)) not valid;

alter table "public"."insumo" validate constraint "chk_stock_no_negativo";

alter table "public"."insumo" add constraint "insumo_id_categoria_fkey" FOREIGN KEY (id_categoria) REFERENCES public.categoria_insumo(id_categoria) not valid;

alter table "public"."insumo" validate constraint "insumo_id_categoria_fkey";

alter table "public"."insumo" add constraint "insumo_id_unidad_fkey" FOREIGN KEY (id_unidad) REFERENCES public.unidad_medida(id_unidad) not valid;

alter table "public"."insumo" validate constraint "insumo_id_unidad_fkey";

alter table "public"."lote" add constraint "fk_lote_area" FOREIGN KEY (id_area_actual) REFERENCES public.area_produccion(id_area) not valid;

alter table "public"."lote" validate constraint "fk_lote_area";

alter table "public"."lote" add constraint "lote_id_desglose_fkey" FOREIGN KEY (id_desglose) REFERENCES public.detalle_orden_talla(id_desglose) ON DELETE CASCADE not valid;

alter table "public"."lote" validate constraint "lote_id_desglose_fkey";

alter table "public"."lote" add constraint "lote_id_estado_lote_fkey" FOREIGN KEY (id_estado_lote) REFERENCES public.estado_lote(id_estado_lote) not valid;

alter table "public"."lote" validate constraint "lote_id_estado_lote_fkey";

alter table "public"."lote" add constraint "lote_id_plantilla_fkey" FOREIGN KEY (id_plantilla) REFERENCES public.plantilla_prenda(id_plantilla) not valid;

alter table "public"."lote" validate constraint "lote_id_plantilla_fkey";

alter table "public"."lote" add constraint "lote_num_orden_fkey" FOREIGN KEY (num_orden) REFERENCES public.orden(num_orden) ON DELETE CASCADE not valid;

alter table "public"."lote" validate constraint "lote_num_orden_fkey";

alter table "public"."medida_ficha" add constraint "fk_talla" FOREIGN KEY (id_talla) REFERENCES public.tallas(id_talla) not valid;

alter table "public"."medida_ficha" validate constraint "fk_talla";

alter table "public"."medida_ficha" add constraint "medida_ficha_id_plantilla_fkey" FOREIGN KEY (id_plantilla) REFERENCES public.plantilla_prenda(id_plantilla) ON DELETE CASCADE not valid;

alter table "public"."medida_ficha" validate constraint "medida_ficha_id_plantilla_fkey";

alter table "public"."medida_ficha" add constraint "unique_medida_plantilla" UNIQUE using index "unique_medida_plantilla";

alter table "public"."movimiento_insumo" add constraint "movimiento_insumo_id_estado_mov_fkey" FOREIGN KEY (id_estado_mov) REFERENCES public.estado_movimiento(id_estado_mov) not valid;

alter table "public"."movimiento_insumo" validate constraint "movimiento_insumo_id_estado_mov_fkey";

alter table "public"."movimiento_insumo" add constraint "movimiento_insumo_id_insumo_fkey" FOREIGN KEY (id_insumo) REFERENCES public.insumo(id_insumo) not valid;

alter table "public"."movimiento_insumo" validate constraint "movimiento_insumo_id_insumo_fkey";

alter table "public"."movimiento_insumo" add constraint "movimiento_insumo_id_usuario_fkey" FOREIGN KEY (id_usuario) REFERENCES public.profiles(id) not valid;

alter table "public"."movimiento_insumo" validate constraint "movimiento_insumo_id_usuario_fkey";

alter table "public"."notificaciones" add constraint "fk_notificaciones_usuario" FOREIGN KEY (id_usuario) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."notificaciones" validate constraint "fk_notificaciones_usuario";

alter table "public"."notificaciones" add constraint "notificaciones_prioridad_check" CHECK (((prioridad)::text = ANY ((ARRAY['informativa'::character varying, 'advertencia'::character varying, 'critica'::character varying])::text[]))) not valid;

alter table "public"."notificaciones" validate constraint "notificaciones_prioridad_check";

alter table "public"."orden" add constraint "chk_orden_prioridad" CHECK ((prioridad = ANY (ARRAY['normal'::text, 'alta'::text, 'urgente'::text]))) not valid;

alter table "public"."orden" validate constraint "chk_orden_prioridad";

alter table "public"."orden" add constraint "orden_id_cliente_fkey" FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente) ON DELETE RESTRICT not valid;

alter table "public"."orden" validate constraint "orden_id_cliente_fkey";

alter table "public"."orden" add constraint "orden_id_estado_fkey" FOREIGN KEY (id_estado) REFERENCES public.estado_orden(id_estado) not valid;

alter table "public"."orden" validate constraint "orden_id_estado_fkey";

alter table "public"."orden" add constraint "orden_id_estado_pago_fkey" FOREIGN KEY (id_estado_pago) REFERENCES public.estado_pago(id_estado_pago) not valid;

alter table "public"."orden" validate constraint "orden_id_estado_pago_fkey";

alter table "public"."pago_cliente" add constraint "pago_cliente_id_cliente_fkey" FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente) not valid;

alter table "public"."pago_cliente" validate constraint "pago_cliente_id_cliente_fkey";

alter table "public"."pago_cliente" add constraint "pago_cliente_id_orden_fkey" FOREIGN KEY (id_orden) REFERENCES public.orden(num_orden) not valid;

alter table "public"."pago_cliente" validate constraint "pago_cliente_id_orden_fkey";

alter table "public"."pagos_trabajador" add constraint "fk_pago_asignacion" FOREIGN KEY (id_asignacion) REFERENCES public.asignaciones_lote(id_asignacion) ON DELETE SET NULL not valid;

alter table "public"."pagos_trabajador" validate constraint "fk_pago_asignacion";

alter table "public"."pagos_trabajador" add constraint "fk_pago_trabajador" FOREIGN KEY (id_trabajador) REFERENCES public.trabajadores(id_trabajador) ON DELETE CASCADE not valid;

alter table "public"."pagos_trabajador" validate constraint "fk_pago_trabajador";

alter table "public"."plantilla_prenda" add constraint "plantilla_prenda_id_tipo_prenda_fkey" FOREIGN KEY (id_tipo_prenda) REFERENCES public.tipo_prenda(id_tipo_prenda) not valid;

alter table "public"."plantilla_prenda" validate constraint "plantilla_prenda_id_tipo_prenda_fkey";

alter table "public"."profiles" add constraint "profiles_ci_check" CHECK ((ci ~ '^[0-9]+$'::text)) not valid;

alter table "public"."profiles" validate constraint "profiles_ci_check";

alter table "public"."profiles" add constraint "profiles_ci_key" UNIQUE using index "profiles_ci_key";

alter table "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."profiles" validate constraint "profiles_id_fkey";

alter table "public"."profiles" add constraint "profiles_id_rol_fkey" FOREIGN KEY (id_rol) REFERENCES public.roles(id_rol) not valid;

alter table "public"."profiles" validate constraint "profiles_id_rol_fkey";

alter table "public"."receta_material" add constraint "receta_material_id_insumo_fkey" FOREIGN KEY (id_insumo) REFERENCES public.insumo(id_insumo) ON DELETE RESTRICT not valid;

alter table "public"."receta_material" validate constraint "receta_material_id_insumo_fkey";

alter table "public"."receta_material" add constraint "receta_material_id_plantilla_fkey" FOREIGN KEY (id_plantilla) REFERENCES public.plantilla_prenda(id_plantilla) ON DELETE CASCADE not valid;

alter table "public"."receta_material" validate constraint "receta_material_id_plantilla_fkey";

alter table "public"."receta_material" add constraint "unique_plantilla_insumo" UNIQUE using index "unique_plantilla_insumo";

alter table "public"."roles" add constraint "roles_nombre_key" UNIQUE using index "roles_nombre_key";

alter table "public"."trabajadores" add constraint "trabajadores_id_area_fkey" FOREIGN KEY (id_area) REFERENCES public.area_produccion(id_area) not valid;

alter table "public"."trabajadores" validate constraint "trabajadores_id_area_fkey";

alter table "public"."trabajadores" add constraint "trabajadores_id_usuario_fkey" FOREIGN KEY (id_usuario) REFERENCES public.profiles(id) ON DELETE CASCADE not valid;

alter table "public"."trabajadores" validate constraint "trabajadores_id_usuario_fkey";

alter table "public"."unidad_medida" add constraint "unidad_medida_nom_unidad_key" UNIQUE using index "unidad_medida_nom_unidad_key";

set check_function_bodies = off;

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

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
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

create or replace view "public"."vista_kardex_insumos" as  SELECT m.fecha AS fecha_movimiento,
    i.nombre AS material,
    em.nombre_movimiento AS tipo_movimiento,
    concat(p.nombre, ' ', p.apellido) AS responsable,
    m.cantidad,
    u.nom_unidad AS unidad,
    m.motivo,
    m.costo_unitario_transaccional AS costo_unidad,
    m.subtotal_movimiento AS costo_total_movimiento,
    i.stock_actual AS saldo_final_momento
   FROM ((((public.movimiento_insumo m
     JOIN public.insumo i ON ((m.id_insumo = i.id_insumo)))
     JOIN public.unidad_medida u ON ((i.id_unidad = u.id_unidad)))
     JOIN public.estado_movimiento em ON ((m.id_estado_mov = em.id_estado_mov)))
     LEFT JOIN public.profiles p ON ((m.id_usuario = p.id)))
  ORDER BY m.fecha DESC;


create or replace view "public"."vista_pagos_produccion_por_orden" as  SELECT l.num_orden,
    t.id_trabajador,
    ((prof.nombre || ' '::text) || prof.apellido) AS trabajador_nombre,
    ap.nombre_area AS area,
    count(al.id_asignacion) AS lotes_asignados,
    sum(al.monto_acordado) AS total_pactado,
    COALESCE(sum(pt.monto), (0)::numeric) AS total_adelantos,
    (sum(al.monto_acordado) - COALESCE(sum(pt.monto), (0)::numeric)) AS saldo_pendiente,
        CASE
            WHEN (sum(al.monto_acordado) = COALESCE(sum(pt.monto), (0)::numeric)) THEN 'Liquidado'::text
            WHEN (COALESCE(sum(pt.monto), (0)::numeric) > (0)::numeric) THEN 'Con Adelantos'::text
            ELSE 'Pendiente'::text
        END AS estado_pago_global
   FROM (((((public.asignaciones_lote al
     JOIN public.lote l ON ((al.id_lote = l.id_lote)))
     JOIN public.trabajadores t ON ((al.id_trabajador = t.id_trabajador)))
     JOIN public.profiles prof ON ((t.id_usuario = prof.id)))
     JOIN public.area_produccion ap ON ((t.id_area = ap.id_area)))
     LEFT JOIN public.pagos_trabajador pt ON ((pt.id_asignacion = al.id_asignacion)))
  GROUP BY l.num_orden, t.id_trabajador, prof.nombre, prof.apellido, ap.nombre_area;


create or replace view "public"."vista_trabajos_asignados" as  SELECT t_tab.id_usuario,
    (al.id_asignacion)::text AS ids_asignaciones,
    (al.id_lote)::text AS lote_id,
    (o.num_orden)::text AS orden_id,
    COALESCE(c.nom_cliente, 'Varios'::text) AS cliente,
    ea.nombre_estado AS estado,
    al.fecha_inicio AS fecha_asignacion,
    l.cantidad_asignada AS cantidad,
    el.nombre_estado AS actividad,
    string_agg(DISTINCT (t.nombre_talla)::text, ', '::text) AS tallas,
    COALESCE(o.notas_adicionales, 'Sin instrucciones'::text) AS instrucciones
   FROM ((((((((public.asignaciones_lote al
     JOIN public.trabajadores t_tab ON ((al.id_trabajador = t_tab.id_trabajador)))
     JOIN public.lote l ON ((al.id_lote = l.id_lote)))
     JOIN public.orden o ON ((l.num_orden = o.num_orden)))
     LEFT JOIN public.cliente c ON ((o.id_cliente = c.id_cliente)))
     JOIN public.estado_asignacion ea ON ((al.id_estado_asignacion = ea.id_estado_asignacion)))
     LEFT JOIN public.estado_lote el ON ((l.id_estado_lote = el.id_estado_lote)))
     LEFT JOIN public.detalle_orden_talla dot ON ((l.id_desglose = dot.id_desglose)))
     LEFT JOIN public.tallas t ON ((dot.id_talla = t.id_talla)))
  GROUP BY t_tab.id_usuario, al.id_asignacion, al.id_lote, o.num_orden, c.nom_cliente, ea.nombre_estado, al.fecha_inicio, l.cantidad_asignada, el.nombre_estado, o.notas_adicionales;


grant delete on table "public"."area_produccion" to "anon";

grant insert on table "public"."area_produccion" to "anon";

grant references on table "public"."area_produccion" to "anon";

grant select on table "public"."area_produccion" to "anon";

grant trigger on table "public"."area_produccion" to "anon";

grant truncate on table "public"."area_produccion" to "anon";

grant update on table "public"."area_produccion" to "anon";

grant delete on table "public"."area_produccion" to "authenticated";

grant insert on table "public"."area_produccion" to "authenticated";

grant references on table "public"."area_produccion" to "authenticated";

grant select on table "public"."area_produccion" to "authenticated";

grant trigger on table "public"."area_produccion" to "authenticated";

grant truncate on table "public"."area_produccion" to "authenticated";

grant update on table "public"."area_produccion" to "authenticated";

grant delete on table "public"."area_produccion" to "service_role";

grant insert on table "public"."area_produccion" to "service_role";

grant references on table "public"."area_produccion" to "service_role";

grant select on table "public"."area_produccion" to "service_role";

grant trigger on table "public"."area_produccion" to "service_role";

grant truncate on table "public"."area_produccion" to "service_role";

grant update on table "public"."area_produccion" to "service_role";

grant delete on table "public"."asignaciones_lote" to "anon";

grant insert on table "public"."asignaciones_lote" to "anon";

grant references on table "public"."asignaciones_lote" to "anon";

grant select on table "public"."asignaciones_lote" to "anon";

grant trigger on table "public"."asignaciones_lote" to "anon";

grant truncate on table "public"."asignaciones_lote" to "anon";

grant update on table "public"."asignaciones_lote" to "anon";

grant delete on table "public"."asignaciones_lote" to "authenticated";

grant insert on table "public"."asignaciones_lote" to "authenticated";

grant references on table "public"."asignaciones_lote" to "authenticated";

grant select on table "public"."asignaciones_lote" to "authenticated";

grant trigger on table "public"."asignaciones_lote" to "authenticated";

grant truncate on table "public"."asignaciones_lote" to "authenticated";

grant update on table "public"."asignaciones_lote" to "authenticated";

grant delete on table "public"."asignaciones_lote" to "service_role";

grant insert on table "public"."asignaciones_lote" to "service_role";

grant references on table "public"."asignaciones_lote" to "service_role";

grant select on table "public"."asignaciones_lote" to "service_role";

grant trigger on table "public"."asignaciones_lote" to "service_role";

grant truncate on table "public"."asignaciones_lote" to "service_role";

grant update on table "public"."asignaciones_lote" to "service_role";

grant delete on table "public"."auditoria_ordenes" to "anon";

grant insert on table "public"."auditoria_ordenes" to "anon";

grant references on table "public"."auditoria_ordenes" to "anon";

grant select on table "public"."auditoria_ordenes" to "anon";

grant trigger on table "public"."auditoria_ordenes" to "anon";

grant truncate on table "public"."auditoria_ordenes" to "anon";

grant update on table "public"."auditoria_ordenes" to "anon";

grant delete on table "public"."auditoria_ordenes" to "authenticated";

grant insert on table "public"."auditoria_ordenes" to "authenticated";

grant references on table "public"."auditoria_ordenes" to "authenticated";

grant select on table "public"."auditoria_ordenes" to "authenticated";

grant trigger on table "public"."auditoria_ordenes" to "authenticated";

grant truncate on table "public"."auditoria_ordenes" to "authenticated";

grant update on table "public"."auditoria_ordenes" to "authenticated";

grant delete on table "public"."auditoria_ordenes" to "service_role";

grant insert on table "public"."auditoria_ordenes" to "service_role";

grant references on table "public"."auditoria_ordenes" to "service_role";

grant select on table "public"."auditoria_ordenes" to "service_role";

grant trigger on table "public"."auditoria_ordenes" to "service_role";

grant truncate on table "public"."auditoria_ordenes" to "service_role";

grant update on table "public"."auditoria_ordenes" to "service_role";

grant delete on table "public"."cat_tipo_cliente" to "anon";

grant insert on table "public"."cat_tipo_cliente" to "anon";

grant references on table "public"."cat_tipo_cliente" to "anon";

grant select on table "public"."cat_tipo_cliente" to "anon";

grant trigger on table "public"."cat_tipo_cliente" to "anon";

grant truncate on table "public"."cat_tipo_cliente" to "anon";

grant update on table "public"."cat_tipo_cliente" to "anon";

grant delete on table "public"."cat_tipo_cliente" to "authenticated";

grant insert on table "public"."cat_tipo_cliente" to "authenticated";

grant references on table "public"."cat_tipo_cliente" to "authenticated";

grant select on table "public"."cat_tipo_cliente" to "authenticated";

grant trigger on table "public"."cat_tipo_cliente" to "authenticated";

grant truncate on table "public"."cat_tipo_cliente" to "authenticated";

grant update on table "public"."cat_tipo_cliente" to "authenticated";

grant delete on table "public"."cat_tipo_cliente" to "service_role";

grant insert on table "public"."cat_tipo_cliente" to "service_role";

grant references on table "public"."cat_tipo_cliente" to "service_role";

grant select on table "public"."cat_tipo_cliente" to "service_role";

grant trigger on table "public"."cat_tipo_cliente" to "service_role";

grant truncate on table "public"."cat_tipo_cliente" to "service_role";

grant update on table "public"."cat_tipo_cliente" to "service_role";

grant delete on table "public"."categoria_insumo" to "anon";

grant insert on table "public"."categoria_insumo" to "anon";

grant references on table "public"."categoria_insumo" to "anon";

grant select on table "public"."categoria_insumo" to "anon";

grant trigger on table "public"."categoria_insumo" to "anon";

grant truncate on table "public"."categoria_insumo" to "anon";

grant update on table "public"."categoria_insumo" to "anon";

grant delete on table "public"."categoria_insumo" to "authenticated";

grant insert on table "public"."categoria_insumo" to "authenticated";

grant references on table "public"."categoria_insumo" to "authenticated";

grant select on table "public"."categoria_insumo" to "authenticated";

grant trigger on table "public"."categoria_insumo" to "authenticated";

grant truncate on table "public"."categoria_insumo" to "authenticated";

grant update on table "public"."categoria_insumo" to "authenticated";

grant delete on table "public"."categoria_insumo" to "service_role";

grant insert on table "public"."categoria_insumo" to "service_role";

grant references on table "public"."categoria_insumo" to "service_role";

grant select on table "public"."categoria_insumo" to "service_role";

grant trigger on table "public"."categoria_insumo" to "service_role";

grant truncate on table "public"."categoria_insumo" to "service_role";

grant update on table "public"."categoria_insumo" to "service_role";

grant delete on table "public"."categoria_unidad" to "anon";

grant insert on table "public"."categoria_unidad" to "anon";

grant references on table "public"."categoria_unidad" to "anon";

grant select on table "public"."categoria_unidad" to "anon";

grant trigger on table "public"."categoria_unidad" to "anon";

grant truncate on table "public"."categoria_unidad" to "anon";

grant update on table "public"."categoria_unidad" to "anon";

grant delete on table "public"."categoria_unidad" to "authenticated";

grant insert on table "public"."categoria_unidad" to "authenticated";

grant references on table "public"."categoria_unidad" to "authenticated";

grant select on table "public"."categoria_unidad" to "authenticated";

grant trigger on table "public"."categoria_unidad" to "authenticated";

grant truncate on table "public"."categoria_unidad" to "authenticated";

grant update on table "public"."categoria_unidad" to "authenticated";

grant delete on table "public"."categoria_unidad" to "service_role";

grant insert on table "public"."categoria_unidad" to "service_role";

grant references on table "public"."categoria_unidad" to "service_role";

grant select on table "public"."categoria_unidad" to "service_role";

grant trigger on table "public"."categoria_unidad" to "service_role";

grant truncate on table "public"."categoria_unidad" to "service_role";

grant update on table "public"."categoria_unidad" to "service_role";

grant delete on table "public"."cliente" to "anon";

grant insert on table "public"."cliente" to "anon";

grant references on table "public"."cliente" to "anon";

grant select on table "public"."cliente" to "anon";

grant trigger on table "public"."cliente" to "anon";

grant truncate on table "public"."cliente" to "anon";

grant update on table "public"."cliente" to "anon";

grant delete on table "public"."cliente" to "authenticated";

grant insert on table "public"."cliente" to "authenticated";

grant references on table "public"."cliente" to "authenticated";

grant select on table "public"."cliente" to "authenticated";

grant trigger on table "public"."cliente" to "authenticated";

grant truncate on table "public"."cliente" to "authenticated";

grant update on table "public"."cliente" to "authenticated";

grant delete on table "public"."cliente" to "service_role";

grant insert on table "public"."cliente" to "service_role";

grant references on table "public"."cliente" to "service_role";

grant select on table "public"."cliente" to "service_role";

grant trigger on table "public"."cliente" to "service_role";

grant truncate on table "public"."cliente" to "service_role";

grant update on table "public"."cliente" to "service_role";

grant delete on table "public"."conjunto" to "anon";

grant insert on table "public"."conjunto" to "anon";

grant references on table "public"."conjunto" to "anon";

grant select on table "public"."conjunto" to "anon";

grant trigger on table "public"."conjunto" to "anon";

grant truncate on table "public"."conjunto" to "anon";

grant update on table "public"."conjunto" to "anon";

grant delete on table "public"."conjunto" to "authenticated";

grant insert on table "public"."conjunto" to "authenticated";

grant references on table "public"."conjunto" to "authenticated";

grant select on table "public"."conjunto" to "authenticated";

grant trigger on table "public"."conjunto" to "authenticated";

grant truncate on table "public"."conjunto" to "authenticated";

grant update on table "public"."conjunto" to "authenticated";

grant delete on table "public"."conjunto" to "service_role";

grant insert on table "public"."conjunto" to "service_role";

grant references on table "public"."conjunto" to "service_role";

grant select on table "public"."conjunto" to "service_role";

grant trigger on table "public"."conjunto" to "service_role";

grant truncate on table "public"."conjunto" to "service_role";

grant update on table "public"."conjunto" to "service_role";

grant delete on table "public"."conjunto_plantilla" to "anon";

grant insert on table "public"."conjunto_plantilla" to "anon";

grant references on table "public"."conjunto_plantilla" to "anon";

grant select on table "public"."conjunto_plantilla" to "anon";

grant trigger on table "public"."conjunto_plantilla" to "anon";

grant truncate on table "public"."conjunto_plantilla" to "anon";

grant update on table "public"."conjunto_plantilla" to "anon";

grant delete on table "public"."conjunto_plantilla" to "authenticated";

grant insert on table "public"."conjunto_plantilla" to "authenticated";

grant references on table "public"."conjunto_plantilla" to "authenticated";

grant select on table "public"."conjunto_plantilla" to "authenticated";

grant trigger on table "public"."conjunto_plantilla" to "authenticated";

grant truncate on table "public"."conjunto_plantilla" to "authenticated";

grant update on table "public"."conjunto_plantilla" to "authenticated";

grant delete on table "public"."conjunto_plantilla" to "service_role";

grant insert on table "public"."conjunto_plantilla" to "service_role";

grant references on table "public"."conjunto_plantilla" to "service_role";

grant select on table "public"."conjunto_plantilla" to "service_role";

grant trigger on table "public"."conjunto_plantilla" to "service_role";

grant truncate on table "public"."conjunto_plantilla" to "service_role";

grant update on table "public"."conjunto_plantilla" to "service_role";

grant delete on table "public"."detalle_orden" to "anon";

grant insert on table "public"."detalle_orden" to "anon";

grant references on table "public"."detalle_orden" to "anon";

grant select on table "public"."detalle_orden" to "anon";

grant trigger on table "public"."detalle_orden" to "anon";

grant truncate on table "public"."detalle_orden" to "anon";

grant update on table "public"."detalle_orden" to "anon";

grant delete on table "public"."detalle_orden" to "authenticated";

grant insert on table "public"."detalle_orden" to "authenticated";

grant references on table "public"."detalle_orden" to "authenticated";

grant select on table "public"."detalle_orden" to "authenticated";

grant trigger on table "public"."detalle_orden" to "authenticated";

grant truncate on table "public"."detalle_orden" to "authenticated";

grant update on table "public"."detalle_orden" to "authenticated";

grant delete on table "public"."detalle_orden" to "service_role";

grant insert on table "public"."detalle_orden" to "service_role";

grant references on table "public"."detalle_orden" to "service_role";

grant select on table "public"."detalle_orden" to "service_role";

grant trigger on table "public"."detalle_orden" to "service_role";

grant truncate on table "public"."detalle_orden" to "service_role";

grant update on table "public"."detalle_orden" to "service_role";

grant delete on table "public"."detalle_orden_talla" to "anon";

grant insert on table "public"."detalle_orden_talla" to "anon";

grant references on table "public"."detalle_orden_talla" to "anon";

grant select on table "public"."detalle_orden_talla" to "anon";

grant trigger on table "public"."detalle_orden_talla" to "anon";

grant truncate on table "public"."detalle_orden_talla" to "anon";

grant update on table "public"."detalle_orden_talla" to "anon";

grant delete on table "public"."detalle_orden_talla" to "authenticated";

grant insert on table "public"."detalle_orden_talla" to "authenticated";

grant references on table "public"."detalle_orden_talla" to "authenticated";

grant select on table "public"."detalle_orden_talla" to "authenticated";

grant trigger on table "public"."detalle_orden_talla" to "authenticated";

grant truncate on table "public"."detalle_orden_talla" to "authenticated";

grant update on table "public"."detalle_orden_talla" to "authenticated";

grant delete on table "public"."detalle_orden_talla" to "service_role";

grant insert on table "public"."detalle_orden_talla" to "service_role";

grant references on table "public"."detalle_orden_talla" to "service_role";

grant select on table "public"."detalle_orden_talla" to "service_role";

grant trigger on table "public"."detalle_orden_talla" to "service_role";

grant truncate on table "public"."detalle_orden_talla" to "service_role";

grant update on table "public"."detalle_orden_talla" to "service_role";

grant delete on table "public"."estado_asignacion" to "anon";

grant insert on table "public"."estado_asignacion" to "anon";

grant references on table "public"."estado_asignacion" to "anon";

grant select on table "public"."estado_asignacion" to "anon";

grant trigger on table "public"."estado_asignacion" to "anon";

grant truncate on table "public"."estado_asignacion" to "anon";

grant update on table "public"."estado_asignacion" to "anon";

grant delete on table "public"."estado_asignacion" to "authenticated";

grant insert on table "public"."estado_asignacion" to "authenticated";

grant references on table "public"."estado_asignacion" to "authenticated";

grant select on table "public"."estado_asignacion" to "authenticated";

grant trigger on table "public"."estado_asignacion" to "authenticated";

grant truncate on table "public"."estado_asignacion" to "authenticated";

grant update on table "public"."estado_asignacion" to "authenticated";

grant delete on table "public"."estado_asignacion" to "service_role";

grant insert on table "public"."estado_asignacion" to "service_role";

grant references on table "public"."estado_asignacion" to "service_role";

grant select on table "public"."estado_asignacion" to "service_role";

grant trigger on table "public"."estado_asignacion" to "service_role";

grant truncate on table "public"."estado_asignacion" to "service_role";

grant update on table "public"."estado_asignacion" to "service_role";

grant delete on table "public"."estado_lote" to "anon";

grant insert on table "public"."estado_lote" to "anon";

grant references on table "public"."estado_lote" to "anon";

grant select on table "public"."estado_lote" to "anon";

grant trigger on table "public"."estado_lote" to "anon";

grant truncate on table "public"."estado_lote" to "anon";

grant update on table "public"."estado_lote" to "anon";

grant delete on table "public"."estado_lote" to "authenticated";

grant insert on table "public"."estado_lote" to "authenticated";

grant references on table "public"."estado_lote" to "authenticated";

grant select on table "public"."estado_lote" to "authenticated";

grant trigger on table "public"."estado_lote" to "authenticated";

grant truncate on table "public"."estado_lote" to "authenticated";

grant update on table "public"."estado_lote" to "authenticated";

grant delete on table "public"."estado_lote" to "service_role";

grant insert on table "public"."estado_lote" to "service_role";

grant references on table "public"."estado_lote" to "service_role";

grant select on table "public"."estado_lote" to "service_role";

grant trigger on table "public"."estado_lote" to "service_role";

grant truncate on table "public"."estado_lote" to "service_role";

grant update on table "public"."estado_lote" to "service_role";

grant delete on table "public"."estado_movimiento" to "anon";

grant insert on table "public"."estado_movimiento" to "anon";

grant references on table "public"."estado_movimiento" to "anon";

grant select on table "public"."estado_movimiento" to "anon";

grant trigger on table "public"."estado_movimiento" to "anon";

grant truncate on table "public"."estado_movimiento" to "anon";

grant update on table "public"."estado_movimiento" to "anon";

grant delete on table "public"."estado_movimiento" to "authenticated";

grant insert on table "public"."estado_movimiento" to "authenticated";

grant references on table "public"."estado_movimiento" to "authenticated";

grant select on table "public"."estado_movimiento" to "authenticated";

grant trigger on table "public"."estado_movimiento" to "authenticated";

grant truncate on table "public"."estado_movimiento" to "authenticated";

grant update on table "public"."estado_movimiento" to "authenticated";

grant delete on table "public"."estado_movimiento" to "service_role";

grant insert on table "public"."estado_movimiento" to "service_role";

grant references on table "public"."estado_movimiento" to "service_role";

grant select on table "public"."estado_movimiento" to "service_role";

grant trigger on table "public"."estado_movimiento" to "service_role";

grant truncate on table "public"."estado_movimiento" to "service_role";

grant update on table "public"."estado_movimiento" to "service_role";

grant delete on table "public"."estado_orden" to "anon";

grant insert on table "public"."estado_orden" to "anon";

grant references on table "public"."estado_orden" to "anon";

grant select on table "public"."estado_orden" to "anon";

grant trigger on table "public"."estado_orden" to "anon";

grant truncate on table "public"."estado_orden" to "anon";

grant update on table "public"."estado_orden" to "anon";

grant delete on table "public"."estado_orden" to "authenticated";

grant insert on table "public"."estado_orden" to "authenticated";

grant references on table "public"."estado_orden" to "authenticated";

grant select on table "public"."estado_orden" to "authenticated";

grant trigger on table "public"."estado_orden" to "authenticated";

grant truncate on table "public"."estado_orden" to "authenticated";

grant update on table "public"."estado_orden" to "authenticated";

grant delete on table "public"."estado_orden" to "service_role";

grant insert on table "public"."estado_orden" to "service_role";

grant references on table "public"."estado_orden" to "service_role";

grant select on table "public"."estado_orden" to "service_role";

grant trigger on table "public"."estado_orden" to "service_role";

grant truncate on table "public"."estado_orden" to "service_role";

grant update on table "public"."estado_orden" to "service_role";

grant delete on table "public"."estado_pago" to "anon";

grant insert on table "public"."estado_pago" to "anon";

grant references on table "public"."estado_pago" to "anon";

grant select on table "public"."estado_pago" to "anon";

grant trigger on table "public"."estado_pago" to "anon";

grant truncate on table "public"."estado_pago" to "anon";

grant update on table "public"."estado_pago" to "anon";

grant delete on table "public"."estado_pago" to "authenticated";

grant insert on table "public"."estado_pago" to "authenticated";

grant references on table "public"."estado_pago" to "authenticated";

grant select on table "public"."estado_pago" to "authenticated";

grant trigger on table "public"."estado_pago" to "authenticated";

grant truncate on table "public"."estado_pago" to "authenticated";

grant update on table "public"."estado_pago" to "authenticated";

grant delete on table "public"."estado_pago" to "service_role";

grant insert on table "public"."estado_pago" to "service_role";

grant references on table "public"."estado_pago" to "service_role";

grant select on table "public"."estado_pago" to "service_role";

grant trigger on table "public"."estado_pago" to "service_role";

grant truncate on table "public"."estado_pago" to "service_role";

grant update on table "public"."estado_pago" to "service_role";

grant delete on table "public"."flujo_estado_lote" to "anon";

grant insert on table "public"."flujo_estado_lote" to "anon";

grant references on table "public"."flujo_estado_lote" to "anon";

grant select on table "public"."flujo_estado_lote" to "anon";

grant trigger on table "public"."flujo_estado_lote" to "anon";

grant truncate on table "public"."flujo_estado_lote" to "anon";

grant update on table "public"."flujo_estado_lote" to "anon";

grant delete on table "public"."flujo_estado_lote" to "authenticated";

grant insert on table "public"."flujo_estado_lote" to "authenticated";

grant references on table "public"."flujo_estado_lote" to "authenticated";

grant select on table "public"."flujo_estado_lote" to "authenticated";

grant trigger on table "public"."flujo_estado_lote" to "authenticated";

grant truncate on table "public"."flujo_estado_lote" to "authenticated";

grant update on table "public"."flujo_estado_lote" to "authenticated";

grant delete on table "public"."flujo_estado_lote" to "service_role";

grant insert on table "public"."flujo_estado_lote" to "service_role";

grant references on table "public"."flujo_estado_lote" to "service_role";

grant select on table "public"."flujo_estado_lote" to "service_role";

grant trigger on table "public"."flujo_estado_lote" to "service_role";

grant truncate on table "public"."flujo_estado_lote" to "service_role";

grant update on table "public"."flujo_estado_lote" to "service_role";

grant delete on table "public"."historial_estado_lote" to "anon";

grant insert on table "public"."historial_estado_lote" to "anon";

grant references on table "public"."historial_estado_lote" to "anon";

grant select on table "public"."historial_estado_lote" to "anon";

grant trigger on table "public"."historial_estado_lote" to "anon";

grant truncate on table "public"."historial_estado_lote" to "anon";

grant update on table "public"."historial_estado_lote" to "anon";

grant delete on table "public"."historial_estado_lote" to "authenticated";

grant insert on table "public"."historial_estado_lote" to "authenticated";

grant references on table "public"."historial_estado_lote" to "authenticated";

grant select on table "public"."historial_estado_lote" to "authenticated";

grant trigger on table "public"."historial_estado_lote" to "authenticated";

grant truncate on table "public"."historial_estado_lote" to "authenticated";

grant update on table "public"."historial_estado_lote" to "authenticated";

grant delete on table "public"."historial_estado_lote" to "service_role";

grant insert on table "public"."historial_estado_lote" to "service_role";

grant references on table "public"."historial_estado_lote" to "service_role";

grant select on table "public"."historial_estado_lote" to "service_role";

grant trigger on table "public"."historial_estado_lote" to "service_role";

grant truncate on table "public"."historial_estado_lote" to "service_role";

grant update on table "public"."historial_estado_lote" to "service_role";

grant delete on table "public"."insumo" to "anon";

grant insert on table "public"."insumo" to "anon";

grant references on table "public"."insumo" to "anon";

grant select on table "public"."insumo" to "anon";

grant trigger on table "public"."insumo" to "anon";

grant truncate on table "public"."insumo" to "anon";

grant update on table "public"."insumo" to "anon";

grant delete on table "public"."insumo" to "authenticated";

grant insert on table "public"."insumo" to "authenticated";

grant references on table "public"."insumo" to "authenticated";

grant select on table "public"."insumo" to "authenticated";

grant trigger on table "public"."insumo" to "authenticated";

grant truncate on table "public"."insumo" to "authenticated";

grant update on table "public"."insumo" to "authenticated";

grant delete on table "public"."insumo" to "service_role";

grant insert on table "public"."insumo" to "service_role";

grant references on table "public"."insumo" to "service_role";

grant select on table "public"."insumo" to "service_role";

grant trigger on table "public"."insumo" to "service_role";

grant truncate on table "public"."insumo" to "service_role";

grant update on table "public"."insumo" to "service_role";

grant delete on table "public"."lote" to "anon";

grant insert on table "public"."lote" to "anon";

grant references on table "public"."lote" to "anon";

grant select on table "public"."lote" to "anon";

grant trigger on table "public"."lote" to "anon";

grant truncate on table "public"."lote" to "anon";

grant update on table "public"."lote" to "anon";

grant delete on table "public"."lote" to "authenticated";

grant insert on table "public"."lote" to "authenticated";

grant references on table "public"."lote" to "authenticated";

grant select on table "public"."lote" to "authenticated";

grant trigger on table "public"."lote" to "authenticated";

grant truncate on table "public"."lote" to "authenticated";

grant update on table "public"."lote" to "authenticated";

grant delete on table "public"."lote" to "service_role";

grant insert on table "public"."lote" to "service_role";

grant references on table "public"."lote" to "service_role";

grant select on table "public"."lote" to "service_role";

grant trigger on table "public"."lote" to "service_role";

grant truncate on table "public"."lote" to "service_role";

grant update on table "public"."lote" to "service_role";

grant delete on table "public"."medida_ficha" to "anon";

grant insert on table "public"."medida_ficha" to "anon";

grant references on table "public"."medida_ficha" to "anon";

grant select on table "public"."medida_ficha" to "anon";

grant trigger on table "public"."medida_ficha" to "anon";

grant truncate on table "public"."medida_ficha" to "anon";

grant update on table "public"."medida_ficha" to "anon";

grant delete on table "public"."medida_ficha" to "authenticated";

grant insert on table "public"."medida_ficha" to "authenticated";

grant references on table "public"."medida_ficha" to "authenticated";

grant select on table "public"."medida_ficha" to "authenticated";

grant trigger on table "public"."medida_ficha" to "authenticated";

grant truncate on table "public"."medida_ficha" to "authenticated";

grant update on table "public"."medida_ficha" to "authenticated";

grant delete on table "public"."medida_ficha" to "service_role";

grant insert on table "public"."medida_ficha" to "service_role";

grant references on table "public"."medida_ficha" to "service_role";

grant select on table "public"."medida_ficha" to "service_role";

grant trigger on table "public"."medida_ficha" to "service_role";

grant truncate on table "public"."medida_ficha" to "service_role";

grant update on table "public"."medida_ficha" to "service_role";

grant delete on table "public"."movimiento_insumo" to "anon";

grant insert on table "public"."movimiento_insumo" to "anon";

grant references on table "public"."movimiento_insumo" to "anon";

grant select on table "public"."movimiento_insumo" to "anon";

grant trigger on table "public"."movimiento_insumo" to "anon";

grant truncate on table "public"."movimiento_insumo" to "anon";

grant update on table "public"."movimiento_insumo" to "anon";

grant delete on table "public"."movimiento_insumo" to "authenticated";

grant insert on table "public"."movimiento_insumo" to "authenticated";

grant references on table "public"."movimiento_insumo" to "authenticated";

grant select on table "public"."movimiento_insumo" to "authenticated";

grant trigger on table "public"."movimiento_insumo" to "authenticated";

grant truncate on table "public"."movimiento_insumo" to "authenticated";

grant update on table "public"."movimiento_insumo" to "authenticated";

grant delete on table "public"."movimiento_insumo" to "service_role";

grant insert on table "public"."movimiento_insumo" to "service_role";

grant references on table "public"."movimiento_insumo" to "service_role";

grant select on table "public"."movimiento_insumo" to "service_role";

grant trigger on table "public"."movimiento_insumo" to "service_role";

grant truncate on table "public"."movimiento_insumo" to "service_role";

grant update on table "public"."movimiento_insumo" to "service_role";

grant delete on table "public"."notificaciones" to "anon";

grant insert on table "public"."notificaciones" to "anon";

grant references on table "public"."notificaciones" to "anon";

grant select on table "public"."notificaciones" to "anon";

grant trigger on table "public"."notificaciones" to "anon";

grant truncate on table "public"."notificaciones" to "anon";

grant update on table "public"."notificaciones" to "anon";

grant delete on table "public"."notificaciones" to "authenticated";

grant insert on table "public"."notificaciones" to "authenticated";

grant references on table "public"."notificaciones" to "authenticated";

grant select on table "public"."notificaciones" to "authenticated";

grant trigger on table "public"."notificaciones" to "authenticated";

grant truncate on table "public"."notificaciones" to "authenticated";

grant update on table "public"."notificaciones" to "authenticated";

grant delete on table "public"."notificaciones" to "service_role";

grant insert on table "public"."notificaciones" to "service_role";

grant references on table "public"."notificaciones" to "service_role";

grant select on table "public"."notificaciones" to "service_role";

grant trigger on table "public"."notificaciones" to "service_role";

grant truncate on table "public"."notificaciones" to "service_role";

grant update on table "public"."notificaciones" to "service_role";

grant delete on table "public"."orden" to "anon";

grant insert on table "public"."orden" to "anon";

grant references on table "public"."orden" to "anon";

grant select on table "public"."orden" to "anon";

grant trigger on table "public"."orden" to "anon";

grant truncate on table "public"."orden" to "anon";

grant update on table "public"."orden" to "anon";

grant delete on table "public"."orden" to "authenticated";

grant insert on table "public"."orden" to "authenticated";

grant references on table "public"."orden" to "authenticated";

grant select on table "public"."orden" to "authenticated";

grant trigger on table "public"."orden" to "authenticated";

grant truncate on table "public"."orden" to "authenticated";

grant update on table "public"."orden" to "authenticated";

grant delete on table "public"."orden" to "service_role";

grant insert on table "public"."orden" to "service_role";

grant references on table "public"."orden" to "service_role";

grant select on table "public"."orden" to "service_role";

grant trigger on table "public"."orden" to "service_role";

grant truncate on table "public"."orden" to "service_role";

grant update on table "public"."orden" to "service_role";

grant delete on table "public"."pago_cliente" to "anon";

grant insert on table "public"."pago_cliente" to "anon";

grant references on table "public"."pago_cliente" to "anon";

grant select on table "public"."pago_cliente" to "anon";

grant trigger on table "public"."pago_cliente" to "anon";

grant truncate on table "public"."pago_cliente" to "anon";

grant update on table "public"."pago_cliente" to "anon";

grant delete on table "public"."pago_cliente" to "authenticated";

grant insert on table "public"."pago_cliente" to "authenticated";

grant references on table "public"."pago_cliente" to "authenticated";

grant select on table "public"."pago_cliente" to "authenticated";

grant trigger on table "public"."pago_cliente" to "authenticated";

grant truncate on table "public"."pago_cliente" to "authenticated";

grant update on table "public"."pago_cliente" to "authenticated";

grant delete on table "public"."pago_cliente" to "service_role";

grant insert on table "public"."pago_cliente" to "service_role";

grant references on table "public"."pago_cliente" to "service_role";

grant select on table "public"."pago_cliente" to "service_role";

grant trigger on table "public"."pago_cliente" to "service_role";

grant truncate on table "public"."pago_cliente" to "service_role";

grant update on table "public"."pago_cliente" to "service_role";

grant delete on table "public"."pagos_trabajador" to "anon";

grant insert on table "public"."pagos_trabajador" to "anon";

grant references on table "public"."pagos_trabajador" to "anon";

grant select on table "public"."pagos_trabajador" to "anon";

grant trigger on table "public"."pagos_trabajador" to "anon";

grant truncate on table "public"."pagos_trabajador" to "anon";

grant update on table "public"."pagos_trabajador" to "anon";

grant delete on table "public"."pagos_trabajador" to "authenticated";

grant insert on table "public"."pagos_trabajador" to "authenticated";

grant references on table "public"."pagos_trabajador" to "authenticated";

grant select on table "public"."pagos_trabajador" to "authenticated";

grant trigger on table "public"."pagos_trabajador" to "authenticated";

grant truncate on table "public"."pagos_trabajador" to "authenticated";

grant update on table "public"."pagos_trabajador" to "authenticated";

grant delete on table "public"."pagos_trabajador" to "service_role";

grant insert on table "public"."pagos_trabajador" to "service_role";

grant references on table "public"."pagos_trabajador" to "service_role";

grant select on table "public"."pagos_trabajador" to "service_role";

grant trigger on table "public"."pagos_trabajador" to "service_role";

grant truncate on table "public"."pagos_trabajador" to "service_role";

grant update on table "public"."pagos_trabajador" to "service_role";

grant delete on table "public"."plantilla_prenda" to "anon";

grant insert on table "public"."plantilla_prenda" to "anon";

grant references on table "public"."plantilla_prenda" to "anon";

grant select on table "public"."plantilla_prenda" to "anon";

grant trigger on table "public"."plantilla_prenda" to "anon";

grant truncate on table "public"."plantilla_prenda" to "anon";

grant update on table "public"."plantilla_prenda" to "anon";

grant delete on table "public"."plantilla_prenda" to "authenticated";

grant insert on table "public"."plantilla_prenda" to "authenticated";

grant references on table "public"."plantilla_prenda" to "authenticated";

grant select on table "public"."plantilla_prenda" to "authenticated";

grant trigger on table "public"."plantilla_prenda" to "authenticated";

grant truncate on table "public"."plantilla_prenda" to "authenticated";

grant update on table "public"."plantilla_prenda" to "authenticated";

grant delete on table "public"."plantilla_prenda" to "service_role";

grant insert on table "public"."plantilla_prenda" to "service_role";

grant references on table "public"."plantilla_prenda" to "service_role";

grant select on table "public"."plantilla_prenda" to "service_role";

grant trigger on table "public"."plantilla_prenda" to "service_role";

grant truncate on table "public"."plantilla_prenda" to "service_role";

grant update on table "public"."plantilla_prenda" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant references on table "public"."profiles" to "anon";

grant select on table "public"."profiles" to "anon";

grant trigger on table "public"."profiles" to "anon";

grant truncate on table "public"."profiles" to "anon";

grant update on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant references on table "public"."profiles" to "authenticated";

grant select on table "public"."profiles" to "authenticated";

grant trigger on table "public"."profiles" to "authenticated";

grant truncate on table "public"."profiles" to "authenticated";

grant update on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant references on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant trigger on table "public"."profiles" to "service_role";

grant truncate on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";

grant delete on table "public"."receta_material" to "anon";

grant insert on table "public"."receta_material" to "anon";

grant references on table "public"."receta_material" to "anon";

grant select on table "public"."receta_material" to "anon";

grant trigger on table "public"."receta_material" to "anon";

grant truncate on table "public"."receta_material" to "anon";

grant update on table "public"."receta_material" to "anon";

grant delete on table "public"."receta_material" to "authenticated";

grant insert on table "public"."receta_material" to "authenticated";

grant references on table "public"."receta_material" to "authenticated";

grant select on table "public"."receta_material" to "authenticated";

grant trigger on table "public"."receta_material" to "authenticated";

grant truncate on table "public"."receta_material" to "authenticated";

grant update on table "public"."receta_material" to "authenticated";

grant delete on table "public"."receta_material" to "service_role";

grant insert on table "public"."receta_material" to "service_role";

grant references on table "public"."receta_material" to "service_role";

grant select on table "public"."receta_material" to "service_role";

grant trigger on table "public"."receta_material" to "service_role";

grant truncate on table "public"."receta_material" to "service_role";

grant update on table "public"."receta_material" to "service_role";

grant delete on table "public"."roles" to "anon";

grant insert on table "public"."roles" to "anon";

grant references on table "public"."roles" to "anon";

grant select on table "public"."roles" to "anon";

grant trigger on table "public"."roles" to "anon";

grant truncate on table "public"."roles" to "anon";

grant update on table "public"."roles" to "anon";

grant delete on table "public"."roles" to "authenticated";

grant insert on table "public"."roles" to "authenticated";

grant references on table "public"."roles" to "authenticated";

grant select on table "public"."roles" to "authenticated";

grant trigger on table "public"."roles" to "authenticated";

grant truncate on table "public"."roles" to "authenticated";

grant update on table "public"."roles" to "authenticated";

grant delete on table "public"."roles" to "service_role";

grant insert on table "public"."roles" to "service_role";

grant references on table "public"."roles" to "service_role";

grant select on table "public"."roles" to "service_role";

grant trigger on table "public"."roles" to "service_role";

grant truncate on table "public"."roles" to "service_role";

grant update on table "public"."roles" to "service_role";

grant delete on table "public"."tallas" to "anon";

grant insert on table "public"."tallas" to "anon";

grant references on table "public"."tallas" to "anon";

grant select on table "public"."tallas" to "anon";

grant trigger on table "public"."tallas" to "anon";

grant truncate on table "public"."tallas" to "anon";

grant update on table "public"."tallas" to "anon";

grant delete on table "public"."tallas" to "authenticated";

grant insert on table "public"."tallas" to "authenticated";

grant references on table "public"."tallas" to "authenticated";

grant select on table "public"."tallas" to "authenticated";

grant trigger on table "public"."tallas" to "authenticated";

grant truncate on table "public"."tallas" to "authenticated";

grant update on table "public"."tallas" to "authenticated";

grant delete on table "public"."tallas" to "service_role";

grant insert on table "public"."tallas" to "service_role";

grant references on table "public"."tallas" to "service_role";

grant select on table "public"."tallas" to "service_role";

grant trigger on table "public"."tallas" to "service_role";

grant truncate on table "public"."tallas" to "service_role";

grant update on table "public"."tallas" to "service_role";

grant delete on table "public"."tipo_prenda" to "anon";

grant insert on table "public"."tipo_prenda" to "anon";

grant references on table "public"."tipo_prenda" to "anon";

grant select on table "public"."tipo_prenda" to "anon";

grant trigger on table "public"."tipo_prenda" to "anon";

grant truncate on table "public"."tipo_prenda" to "anon";

grant update on table "public"."tipo_prenda" to "anon";

grant delete on table "public"."tipo_prenda" to "authenticated";

grant insert on table "public"."tipo_prenda" to "authenticated";

grant references on table "public"."tipo_prenda" to "authenticated";

grant select on table "public"."tipo_prenda" to "authenticated";

grant trigger on table "public"."tipo_prenda" to "authenticated";

grant truncate on table "public"."tipo_prenda" to "authenticated";

grant update on table "public"."tipo_prenda" to "authenticated";

grant delete on table "public"."tipo_prenda" to "service_role";

grant insert on table "public"."tipo_prenda" to "service_role";

grant references on table "public"."tipo_prenda" to "service_role";

grant select on table "public"."tipo_prenda" to "service_role";

grant trigger on table "public"."tipo_prenda" to "service_role";

grant truncate on table "public"."tipo_prenda" to "service_role";

grant update on table "public"."tipo_prenda" to "service_role";

grant delete on table "public"."trabajadores" to "anon";

grant insert on table "public"."trabajadores" to "anon";

grant references on table "public"."trabajadores" to "anon";

grant select on table "public"."trabajadores" to "anon";

grant trigger on table "public"."trabajadores" to "anon";

grant truncate on table "public"."trabajadores" to "anon";

grant update on table "public"."trabajadores" to "anon";

grant delete on table "public"."trabajadores" to "authenticated";

grant insert on table "public"."trabajadores" to "authenticated";

grant references on table "public"."trabajadores" to "authenticated";

grant select on table "public"."trabajadores" to "authenticated";

grant trigger on table "public"."trabajadores" to "authenticated";

grant truncate on table "public"."trabajadores" to "authenticated";

grant update on table "public"."trabajadores" to "authenticated";

grant delete on table "public"."trabajadores" to "service_role";

grant insert on table "public"."trabajadores" to "service_role";

grant references on table "public"."trabajadores" to "service_role";

grant select on table "public"."trabajadores" to "service_role";

grant trigger on table "public"."trabajadores" to "service_role";

grant truncate on table "public"."trabajadores" to "service_role";

grant update on table "public"."trabajadores" to "service_role";

grant delete on table "public"."unidad_medida" to "anon";

grant insert on table "public"."unidad_medida" to "anon";

grant references on table "public"."unidad_medida" to "anon";

grant select on table "public"."unidad_medida" to "anon";

grant trigger on table "public"."unidad_medida" to "anon";

grant truncate on table "public"."unidad_medida" to "anon";

grant update on table "public"."unidad_medida" to "anon";

grant delete on table "public"."unidad_medida" to "authenticated";

grant insert on table "public"."unidad_medida" to "authenticated";

grant references on table "public"."unidad_medida" to "authenticated";

grant select on table "public"."unidad_medida" to "authenticated";

grant trigger on table "public"."unidad_medida" to "authenticated";

grant truncate on table "public"."unidad_medida" to "authenticated";

grant update on table "public"."unidad_medida" to "authenticated";

grant delete on table "public"."unidad_medida" to "service_role";

grant insert on table "public"."unidad_medida" to "service_role";

grant references on table "public"."unidad_medida" to "service_role";

grant select on table "public"."unidad_medida" to "service_role";

grant trigger on table "public"."unidad_medida" to "service_role";

grant truncate on table "public"."unidad_medida" to "service_role";

grant update on table "public"."unidad_medida" to "service_role";


  create policy "Permitir lectura de áreas a todos los autenticados"
  on "public"."area_produccion"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir actualizacion a autenticados"
  on "public"."asignaciones_lote"
  as permissive
  for update
  to authenticated
using (true)
with check (true);



  create policy "Permitir insercion a autenticados"
  on "public"."asignaciones_lote"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "Permitir inserción de historial a usuarios autenticados"
  on "public"."auditoria_ordenes"
  as permissive
  for insert
  to authenticated
with check (((auth.uid() = id_usuario) OR (id_usuario IS NULL)));



  create policy "Permitir lectura de historial a usuarios autenticados"
  on "public"."auditoria_ordenes"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir lectura de categorias"
  on "public"."categoria_insumo"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir lectura de relaciones categoria_unidad"
  on "public"."categoria_unidad"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Admin y Cajas pueden editar clientes"
  on "public"."cliente"
  as permissive
  for update
  to authenticated
using ((public.get_mi_rol() = ANY (ARRAY[1, 3])))
with check ((public.get_mi_rol() = ANY (ARRAY[1, 3])));



  create policy "Admin y Cajas pueden registrar clientes"
  on "public"."cliente"
  as permissive
  for insert
  to authenticated
with check ((public.get_mi_rol() = ANY (ARRAY[1, 3])));



  create policy "Admin y Cajas pueden ver clientes"
  on "public"."cliente"
  as permissive
  for select
  to authenticated
using ((public.get_mi_rol() = ANY (ARRAY[1, 3])));



  create policy "Admin y Cajeros pueden gestionar clientes"
  on "public"."cliente"
  as permissive
  for all
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.id_rol = ANY (ARRAY[1, 3]))))))
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.id_rol = ANY (ARRAY[1, 3]))))));



  create policy "Permitir crear conjuntos a usuarios autenticados"
  on "public"."conjunto"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "Permitir editar conjuntos a usuarios autenticados"
  on "public"."conjunto"
  as permissive
  for update
  to authenticated
using (true);



  create policy "Permitir eliminar conjuntos a usuarios autenticados"
  on "public"."conjunto"
  as permissive
  for delete
  to authenticated
using (true);



  create policy "Permitir ver conjuntos a usuarios autenticados"
  on "public"."conjunto"
  as permissive
  for select
  to authenticated
using (true);



  create policy "conjunto_auth_select"
  on "public"."conjunto"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir editar vinculación de piezas a usuarios autenticados"
  on "public"."conjunto_plantilla"
  as permissive
  for update
  to authenticated
using (true);



  create policy "Permitir eliminar piezas del conjunto a usuarios autenticados"
  on "public"."conjunto_plantilla"
  as permissive
  for delete
  to authenticated
using (true);



  create policy "Permitir ver piezas del conjunto a usuarios autenticados"
  on "public"."conjunto_plantilla"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir vincular piezas al conjunto a usuarios autenticados"
  on "public"."conjunto_plantilla"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "detalle_orden_auth_delete"
  on "public"."detalle_orden"
  as permissive
  for delete
  to authenticated
using (true);



  create policy "detalle_orden_auth_insert"
  on "public"."detalle_orden"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "detalle_orden_auth_select"
  on "public"."detalle_orden"
  as permissive
  for select
  to authenticated
using (true);



  create policy "detalle_orden_auth_update"
  on "public"."detalle_orden"
  as permissive
  for update
  to authenticated
using (true)
with check (true);



  create policy "detalle_orden_talla_auth_delete"
  on "public"."detalle_orden_talla"
  as permissive
  for delete
  to authenticated
using (true);



  create policy "detalle_orden_talla_auth_insert"
  on "public"."detalle_orden_talla"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "detalle_orden_talla_auth_select"
  on "public"."detalle_orden_talla"
  as permissive
  for select
  to authenticated
using (true);



  create policy "detalle_orden_talla_auth_update"
  on "public"."detalle_orden_talla"
  as permissive
  for update
  to authenticated
using (true)
with check (true);



  create policy "Actualización de inventario"
  on "public"."insumo"
  as permissive
  for update
  to public
using ((public.get_mi_rol() = ANY (ARRAY[1, 3])));



  create policy "Lectura de inventario"
  on "public"."insumo"
  as permissive
  for select
  to public
using ((public.get_mi_rol() = ANY (ARRAY[1, 3])));



  create policy "Permitir actualizacion de insumos"
  on "public"."insumo"
  as permissive
  for update
  to authenticated
using (true);



  create policy "Permitir eliminacion de insumos"
  on "public"."insumo"
  as permissive
  for delete
  to authenticated
using (true);



  create policy "Permitir insercion de insumos"
  on "public"."insumo"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "Permitir lectura de insumos"
  on "public"."insumo"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Stock: Solo Almacén y Admin gestionan"
  on "public"."insumo"
  as permissive
  for all
  to public
using ((public.get_mi_rol() = ANY (ARRAY[1, 3])));



  create policy "Stock: Todos ven inventario"
  on "public"."insumo"
  as permissive
  for select
  to public
using (true);



  create policy "Permitir todo en lote a autenticados"
  on "public"."lote"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "Permitir todo en orden a autenticados"
  on "public"."orden"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "orden_auth_delete"
  on "public"."orden"
  as permissive
  for delete
  to authenticated
using (true);



  create policy "orden_auth_insert"
  on "public"."orden"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "orden_auth_select"
  on "public"."orden"
  as permissive
  for select
  to authenticated
using (true);



  create policy "orden_auth_update"
  on "public"."orden"
  as permissive
  for update
  to authenticated
using (true)
with check (true);



  create policy "Órdenes: Cajas y Admin insertan"
  on "public"."orden"
  as permissive
  for insert
  to public
with check ((public.get_mi_rol() = ANY (ARRAY[1, 3])));



  create policy "Órdenes: Personal autorizado puede actualizar"
  on "public"."orden"
  as permissive
  for update
  to public
using ((public.get_mi_rol() = ANY (ARRAY[1, 2, 3])));



  create policy "Órdenes: Todo el personal puede ver"
  on "public"."orden"
  as permissive
  for select
  to public
using (true);



  create policy "Permitir insercion a autenticados"
  on "public"."pagos_trabajador"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "Permitir lectura a autenticados"
  on "public"."pagos_trabajador"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir todo en ficha_tecnica a autenticados"
  on "public"."plantilla_prenda"
  as permissive
  for all
  to authenticated
using (true)
with check (true);



  create policy "editar propio perfil"
  on "public"."profiles"
  as permissive
  for update
  to authenticated
using ((auth.uid() = id))
with check ((auth.uid() = id));



  create policy "editar_usuario_admin"
  on "public"."profiles"
  as permissive
  for update
  to authenticated
using (((auth.uid() = id) OR (public.get_mi_rol() = 1)));



  create policy "eliminar usuario(Admin)"
  on "public"."profiles"
  as permissive
  for delete
  to authenticated
using ((public.get_mi_rol() = 1));



  create policy "usuario crea su perfil"
  on "public"."profiles"
  as permissive
  for insert
  to authenticated
with check ((auth.uid() = id));



  create policy "usuarios ven perfiles"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using (((auth.uid() = id) OR (public.get_mi_rol() = 1)));



  create policy "ver propio perfil"
  on "public"."profiles"
  as permissive
  for select
  to authenticated
using ((auth.uid() = id));



  create policy "Permiso para leer roles"
  on "public"."roles"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir lectura de catálogo tallas"
  on "public"."tallas"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir lectura de catálogo tipo_prenda"
  on "public"."tipo_prenda"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir gestión de trabajadores a administradores"
  on "public"."trabajadores"
  as permissive
  for all
  to authenticated
using ((( SELECT profiles.id_rol
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 1))
with check ((( SELECT profiles.id_rol
   FROM public.profiles
  WHERE (profiles.id = auth.uid())) = 1));



  create policy "Permitir lectura de trabajadores a autenticados"
  on "public"."trabajadores"
  as permissive
  for select
  to authenticated
using (true);



  create policy "Permitir lectura de unidades"
  on "public"."unidad_medida"
  as permissive
  for select
  to authenticated
using (true);


CREATE TRIGGER tr_nueva_asignacion_lote AFTER INSERT ON public.asignaciones_lote FOR EACH ROW EXECUTE FUNCTION public.tg_notificar_nueva_asignacion();

CREATE TRIGGER trg_sincronizar_lote AFTER INSERT OR UPDATE ON public.asignaciones_lote FOR EACH ROW EXECUTE FUNCTION public.sincronizar_estado_lote();

CREATE TRIGGER set_updated_at_cliente BEFORE UPDATE ON public.cliente FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER trg_crear_lotes_desde_tallas AFTER INSERT ON public.detalle_orden_talla FOR EACH ROW EXECUTE FUNCTION public.generar_lotes_produccion();

CREATE TRIGGER trigger_movimiento_insumo_stock BEFORE INSERT ON public.movimiento_insumo FOR EACH ROW EXECUTE FUNCTION public.gestionar_stock_por_movimiento();

CREATE TRIGGER "Webhook Alertas Push" AFTER INSERT ON public.notificaciones FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request('https://txnmhtoczfgjdwdptrfl.supabase.co/functions/v1/enviar-alerta-push', 'POST', '{"Content-type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4bm1odG9jemZnamR3ZHB0cmZsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTIzOTYxMSwiZXhwIjoyMDkwODE1NjExfQ.IW6ltvRuc_5WfvHqlWaxNAveVvKpOrgg9Aa9zN7xAhI"}', '{}', '5000');

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER tr_vigilar_estado_perfil AFTER UPDATE OF activo ON public.profiles FOR EACH ROW WHEN ((old.activo IS DISTINCT FROM new.activo)) EXECUTE FUNCTION public.sincronizar_acceso_usuario();

CREATE TRIGGER tr_bloquear_insumo_inactivo BEFORE INSERT OR UPDATE ON public.receta_material FOR EACH ROW EXECUTE FUNCTION public.verificar_insumo_activo();

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER on_auth_user_login AFTER UPDATE OF last_sign_in_at ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_sync_last_access();

CREATE TRIGGER on_auth_user_updated AFTER INSERT OR UPDATE OF email ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_sync_user_email();


  create policy "Permitir lectura de fichas_tecnicas"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using ((bucket_id = 'fichas_tecnicas'::text));



  create policy "Permitir subida a fichas_tecnicas"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'fichas_tecnicas'::text));



  create policy "Permitir subida y lectura pública 173gmzx_0"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check (((bucket_id = 'fichas_tecnicas'::text) AND (auth.role() = 'anon'::text)));



  create policy "Permitir subida y lectura pública 173gmzx_1"
  on "storage"."objects"
  as permissive
  for select
  to public
using (((bucket_id = 'fichas_tecnicas'::text) AND (auth.role() = 'anon'::text)));



