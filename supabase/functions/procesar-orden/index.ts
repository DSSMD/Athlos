// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.
// Setup type definitions for built-in Supabase Runtime APIs
import "@supabase/functions-js/edge-runtime.d.ts";
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
serve(async (req)=>{
  try {
    // 1. Recibimos el número de ORDEN completa, no solo un desglose
    const { num_orden, tope_maximo } = await req.json();
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '');
    // 2. BUSCAR TODOS LOS DESGLOSES DE LA ORDEN
    // Traemos un arreglo con todas las tallas que pidió el cliente
    const { data: desgloses, error: fetchError } = await supabaseClient.from('desglose_tallas').select('id_desglose, cantidad').eq('num_orden', num_orden);
    if (fetchError || !desgloses || desgloses.length === 0) {
      throw new Error('No se encontraron desgloses para esta orden');
    }
    // Aquí guardaremos todos los lotes de todas las tallas
    const lotesAInsertar = [];
    // 3. BUCLE PRINCIPAL (Recorremos cada talla)
    for (const desglose of desgloses){
      const cantidadTotal = desglose.cantidad;
      // Calculamos los paquetes enteros y el sobrante para ESTA talla
      const lotesCompletos = Math.floor(cantidadTotal / tope_maximo);
      const residuo = cantidadTotal % tope_maximo;
      // 4. BUCLE SECUNDARIO (Creamos los paquetes de 10)
      for(let i = 0; i < lotesCompletos; i++){
        lotesAInsertar.push({
          num_orden: num_orden,
          id_desglose: desglose.id_desglose,
          cantidad_asignada: tope_maximo,
          id_estado_lote: 1
        });
      }
      // Agregamos el paquete del sobrante (Ej: las 5 prendas que quedaron)
      if (residuo > 0) {
        lotesAInsertar.push({
          num_orden: num_orden,
          id_desglose: desglose.id_desglose,
          cantidad_asignada: residuo,
          id_estado_lote: 1
        });
      }
    }
    // 5. INSERCIÓN MASIVA MAGISTRAL
    // Si la orden tenía 100 prendas de 4 tallas distintas, este array puede
    // tener 10 filas. Supabase las inserta TODAS de un solo golpe.
    const { data: lotesCreados, error: insertError } = await supabaseClient.from('lote').insert(lotesAInsertar).select();
    if (insertError) throw insertError;
    // 6. Respuesta limpia al celular
    return new Response(JSON.stringify({
      mensaje: "Orden completa dividida y enviada a producción",
      total_lotes_generados: lotesCreados.length,
      lotes: lotesCreados
    }), {
      headers: {
        "Content-Type": "application/json"
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 400
    });
  }
}) /* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/procesar-orden' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/ ;
