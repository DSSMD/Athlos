CREATE OR REPLACE FUNCTION public.tiene_administrador()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id_rol = 1 LIMIT 1
  );
$$;

-- Permitir que usuarios no autenticados (anon) puedan llamar a esta función
GRANT EXECUTE ON FUNCTION public.tiene_administrador() TO anon;
