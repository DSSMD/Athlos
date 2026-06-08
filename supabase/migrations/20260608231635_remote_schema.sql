alter table "public"."notificaciones" drop constraint "notificaciones_prioridad_check";


  create table "public"."config_produccion" (
    "id_config" integer not null default 1,
    "capacidad_horas_dia" numeric not null default 8.0,
    "updated_at" timestamp with time zone default now()
      );


alter table "public"."config_produccion" enable row level security;


  create table "public"."scheduling_resultado" (
    "id_resultado" uuid not null default gen_random_uuid(),
    "num_orden" uuid not null,
    "fecha_calculo" timestamp with time zone default now(),
    "posicion_secuencia" integer,
    "tiempo_inicio_estimado" numeric,
    "tiempo_fin_estimado" numeric,
    "fecha_fin_estimada" date,
    "en_tiempo" boolean not null default true,
    "tiempo_proceso_calculado" numeric
      );


alter table "public"."scheduling_resultado" enable row level security;

alter table "public"."plantilla_prenda" add column "tiempo_produccion_unitario" numeric not null default 0.0;

CREATE UNIQUE INDEX config_produccion_pkey ON public.config_produccion USING btree (id_config);

CREATE INDEX idx_scheduling_resultado_en_tiempo ON public.scheduling_resultado USING btree (en_tiempo);

CREATE INDEX idx_scheduling_resultado_num_orden ON public.scheduling_resultado USING btree (num_orden);

CREATE INDEX idx_scheduling_resultado_posicion ON public.scheduling_resultado USING btree (posicion_secuencia);

CREATE UNIQUE INDEX scheduling_resultado_pkey ON public.scheduling_resultado USING btree (id_resultado);

alter table "public"."config_produccion" add constraint "config_produccion_pkey" PRIMARY KEY using index "config_produccion_pkey";

alter table "public"."scheduling_resultado" add constraint "scheduling_resultado_pkey" PRIMARY KEY using index "scheduling_resultado_pkey";

alter table "public"."config_produccion" add constraint "config_produccion_capacidad_horas_dia_check" CHECK ((capacidad_horas_dia > (0)::numeric)) not valid;

alter table "public"."config_produccion" validate constraint "config_produccion_capacidad_horas_dia_check";

alter table "public"."config_produccion" add constraint "config_produccion_singleton" CHECK ((id_config = 1)) not valid;

alter table "public"."config_produccion" validate constraint "config_produccion_singleton";

alter table "public"."plantilla_prenda" add constraint "plantilla_prenda_tiempo_produccion_unitario_check" CHECK ((tiempo_produccion_unitario >= (0)::numeric)) not valid;

alter table "public"."plantilla_prenda" validate constraint "plantilla_prenda_tiempo_produccion_unitario_check";

alter table "public"."scheduling_resultado" add constraint "scheduling_resultado_num_orden_fkey" FOREIGN KEY (num_orden) REFERENCES public.orden(num_orden) ON DELETE CASCADE not valid;

alter table "public"."scheduling_resultado" validate constraint "scheduling_resultado_num_orden_fkey";

alter table "public"."notificaciones" add constraint "notificaciones_prioridad_check" CHECK (((prioridad)::text = ANY ((ARRAY['informativa'::character varying, 'advertencia'::character varying, 'critica'::character varying])::text[]))) not valid;

alter table "public"."notificaciones" validate constraint "notificaciones_prioridad_check";

grant delete on table "public"."config_produccion" to "anon";

grant insert on table "public"."config_produccion" to "anon";

grant references on table "public"."config_produccion" to "anon";

grant select on table "public"."config_produccion" to "anon";

grant trigger on table "public"."config_produccion" to "anon";

grant truncate on table "public"."config_produccion" to "anon";

grant update on table "public"."config_produccion" to "anon";

grant delete on table "public"."config_produccion" to "authenticated";

grant insert on table "public"."config_produccion" to "authenticated";

grant references on table "public"."config_produccion" to "authenticated";

grant select on table "public"."config_produccion" to "authenticated";

grant trigger on table "public"."config_produccion" to "authenticated";

grant truncate on table "public"."config_produccion" to "authenticated";

grant update on table "public"."config_produccion" to "authenticated";

grant delete on table "public"."config_produccion" to "service_role";

grant insert on table "public"."config_produccion" to "service_role";

grant references on table "public"."config_produccion" to "service_role";

grant select on table "public"."config_produccion" to "service_role";

grant trigger on table "public"."config_produccion" to "service_role";

grant truncate on table "public"."config_produccion" to "service_role";

grant update on table "public"."config_produccion" to "service_role";

grant delete on table "public"."scheduling_resultado" to "anon";

grant insert on table "public"."scheduling_resultado" to "anon";

grant references on table "public"."scheduling_resultado" to "anon";

grant select on table "public"."scheduling_resultado" to "anon";

grant trigger on table "public"."scheduling_resultado" to "anon";

grant truncate on table "public"."scheduling_resultado" to "anon";

grant update on table "public"."scheduling_resultado" to "anon";

grant delete on table "public"."scheduling_resultado" to "authenticated";

grant insert on table "public"."scheduling_resultado" to "authenticated";

grant references on table "public"."scheduling_resultado" to "authenticated";

grant select on table "public"."scheduling_resultado" to "authenticated";

grant trigger on table "public"."scheduling_resultado" to "authenticated";

grant truncate on table "public"."scheduling_resultado" to "authenticated";

grant update on table "public"."scheduling_resultado" to "authenticated";

grant delete on table "public"."scheduling_resultado" to "service_role";

grant insert on table "public"."scheduling_resultado" to "service_role";

grant references on table "public"."scheduling_resultado" to "service_role";

grant select on table "public"."scheduling_resultado" to "service_role";

grant trigger on table "public"."scheduling_resultado" to "service_role";

grant truncate on table "public"."scheduling_resultado" to "service_role";

grant update on table "public"."scheduling_resultado" to "service_role";


  create policy "config_produccion_select_authenticated"
  on "public"."config_produccion"
  as permissive
  for select
  to authenticated
using (true);



  create policy "config_produccion_update_admin_only"
  on "public"."config_produccion"
  as permissive
  for update
  to authenticated
using ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.id_rol = 1)))))
with check ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.id_rol = 1)))));



  create policy "scheduling_resultado_delete_authenticated"
  on "public"."scheduling_resultado"
  as permissive
  for delete
  to authenticated
using (true);



  create policy "scheduling_resultado_insert_authenticated"
  on "public"."scheduling_resultado"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "scheduling_resultado_select_authenticated"
  on "public"."scheduling_resultado"
  as permissive
  for select
  to authenticated
using (true);



