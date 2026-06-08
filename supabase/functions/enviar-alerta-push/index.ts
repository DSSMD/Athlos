// supabase/functions/enviar-alerta-push/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { JWT } from "npm:google-auth-library@9";
serve(async (req)=>{
  try {
    // 1. Sacamos la Llave Secreta de Firebase que guardaste en Supabase
    const serviceAccountString = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');
    if (!serviceAccountString) throw new Error('Falta el secreto FIREBASE_SERVICE_ACCOUNT');
    const serviceAccount = JSON.parse(serviceAccountString);
    // 2. Capturamos el nuevo registro de la tabla 'notificaciones'
    const payload = await req.json();
    const notificacion = payload.record;
    // 3. Autenticación con Google (FCM API v1)
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: [
        'https://www.googleapis.com/auth/firebase.messaging'
      ]
    });
    const tokens = await jwtClient.getAccessToken();
    // 4. Armamos el mensaje Push para el canal
    const pushMessage = {
      message: {
        topic: 'jefes_produccion',
        notification: {
          title: notificacion.titulo,
          body: notificacion.mensaje
        },
        data: {
          tipo: notificacion.tipo || 'general',
          prioridad: notificacion.prioridad || 'informativa'
        }
      }
    };
    // 5. Enviamos a Firebase
    const projectId = serviceAccount.project_id;
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokens.token}`
      },
      body: JSON.stringify(pushMessage)
    });
    const resData = await response.json();
    return new Response(JSON.stringify({
      success: true,
      firebaseResponse: resData
    }), {
      headers: {
        'Content-Type': 'application/json'
      }
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
});
