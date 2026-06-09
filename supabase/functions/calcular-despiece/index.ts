// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.
// Setup type definitions for built-in Supabase Runtime APIs
/*import "@supabase/functions-js/edge-runtime.d.ts"

console.log("Hello from Functions!")

Deno.serve(async (req) => {
  const { name } = await req.json()
  const data = {
    message: `Hello ${name}!`,
  }

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  )
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/calcular-despiece' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/ import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
// 1. Cabeceras CORS (Obligatorio para que Flutter no tenga errores de conexión)
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
};
serve(async (req)=>{
  // Manejo de petición pre-vuelo (CORS)
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: corsHeaders
    });
  }
  try {
    // 2. Extraer los datos que envía Flutter
    const body = await req.json();
    const { tipo_prenda, cantidad } = body;
    // 3. Manejo de Errores (Si falta un dato, devolvemos HTTP 400)
    if (!tipo_prenda || !cantidad) {
      return new Response(JSON.stringify({
        error: 'Bad Request',
        mensaje: 'Faltan parámetros requeridos: tipo_prenda o cantidad.'
      }), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        },
        status: 400
      });
    }
    // 4. Lógica de Negocio Simulada (El cliente dará la fórmula real en 3 días)
    const calculo_simulado = cantidad * 1.5;
    // 5. Armar la respuesta JSON exitosa
    const resultado = {
      success: true,
      mensaje: "Infraestructura de cálculo funcionando",
      data_simulada: {
        prenda_solicitada: tipo_prenda,
        metros_tela_estimados: calculo_simulado
      }
    };
    // Devolver HTTP 200 OK
    return new Response(JSON.stringify(resultado), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 200
    });
  } catch (error) {
    // Si envían un JSON mal formado, devuelve HTTP 500
    return new Response(JSON.stringify({
      error: 'Internal Server Error',
      detalle: error.message
    }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      },
      status: 500
    });
  }
});
