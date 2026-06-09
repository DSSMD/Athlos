import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    const { email, password, nombre, apellido, telefono, id_rol, id_area, tarifa_pago_base } = await req.json();
    const { data: userData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true
    });
    if (authError) throw authError;
    const nuevoId = userData.user.id;
    const { error: profileError } = await supabaseAdmin.from('profiles').upsert({
      id: nuevoId,
      nombre,
      apellido,
      email,
      telefono,
      id_rol,
      activo: true
    });
    if (profileError) {
      await supabaseAdmin.auth.admin.deleteUser(nuevoId);
      throw profileError;
    }
    if (id_area !== undefined && id_area !== null) {
      const { error: trabajadorError } = await supabaseAdmin.from('trabajadores').insert({
        id_usuario: nuevoId,
        id_area: id_area,
        tarifa_pago_base: tarifa_pago_base || 0.00
      });
      if (trabajadorError) {
        await supabaseAdmin.auth.admin.deleteUser(nuevoId);
        throw trabajadorError;
      }
    }
    return new Response(JSON.stringify({
      message: "Usuario creado con éxito"
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      },
      status: 200
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      },
      status: 400
    });
  }
});
