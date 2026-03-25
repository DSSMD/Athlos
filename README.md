# Sistema de Gestión - Taller de Costura

Este proyecto está desarrollado con Flutter y conectado a Supabase. Utiliza **Docker y DevContainers** para unificar el entorno de desarrollo. Esto significa que todo el equipo trabaja exactamente con las mismas versiones de herramientas y dependencias.

**⚠️ IMPORTANTE: No es necesario instalar el SDK de Flutter ni Android Studio en tu computadora local.**

## 🛠️ Requisitos Previos

Cada miembro del equipo solo necesita tener instalado lo siguiente en su máquina física:
1. **Git:** Para clonar el repositorio y gestionar versiones.
2. **Docker Desktop:** (Asegúrate de que esté abierto y ejecutándose en segundo plano).
3. **Visual Studio Code:** Con la extensión oficial **"Dev Containers"** de Microsoft.

---

## 🚀 Guía de Inicio Rápido (Setup)

Sigue estos pasos para levantar el entorno de desarrollo por primera vez:

1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/TU-USUARIO/TU-REPOSITORIO.git](https://github.com/TU-USUARIO/TU-REPOSITORIO.git)
   cd TU-REPOSITORIO
   ```

2. **Configurar las variables de entorno:**
   * Busca el archivo llamado `.env.example` en la raíz del proyecto.
   * Haz una copia de ese archivo y renómbrala a `.env`.
   * Solicita al administrador las credenciales de desarrollo de Supabase y pégalas en ese archivo `.env`.

3. **Iniciar el contenedor de desarrollo:**
   * Abre la carpeta del proyecto en Visual Studio Code.
   * VS Code detectará la configuración y mostrará una notificación en la esquina inferior derecha. Haz clic en **"Reopen in Container"** (Reabrir en contenedor).
   * *Nota: La primera vez que hagas esto, Docker descargará y configurará todo el entorno (SDK de Flutter, dependencias nativas, etc.). Puede tardar unos minutos.*

---

## 💻 Comandos Útiles para el Desarrollo

Una vez dentro del contenedor, la terminal integrada de VS Code ejecutará todo dentro del entorno aislado. Puedes usar los comandos estándar de Flutter:

### Probar la interfaz rápidamente (Web)
Ideal para el día a día y ver cambios de UI al instante.
```bash
flutter run -d web-server --web-port 8080
```
*(Luego abre http://localhost:8080 en tu navegador).*

### Compilar la versión nativa de Android (.apk)
```bash
flutter build apk
```
*(El archivo instalable aparecerá en tu computadora física en la ruta: `build/app/outputs/flutter-apk/app-release.apk`).*

### Depurar en un dispositivo físico (Por Wi-Fi)
Si necesitas probar funciones nativas conectando tu celular a la misma red de tu PC:
```bash
adb connect IP_DE_TU_CELULAR:PUERTO
flutter devices
flutter run
```