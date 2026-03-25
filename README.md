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

## 🛑 Apagar y Encender el Entorno (Docker)

Para no consumir recursos de tu computadora física cuando no estés programando en el sistema del taller:

**Para apagar el entorno:**
* Simplemente cierra la ventana de Visual Studio Code. Docker pausará el contenedor automáticamente.
* *(Alternativa formal):* Presiona `F1` en VS Code, escribe **Dev Containers: Stop Container** y presiona Enter.

**Para volver a trabajar (Encender):**
1. Asegúrate de abrir **Docker Desktop** primero en tu computadora.
2. Abre la carpeta del proyecto en VS Code.
3. Haz clic en el botón de la esquina inferior derecha que dice **"Reopen in Container"**. En un par de segundos estarás de vuelta en la terminal de desarrollo.

---

## 🌿 Flujo de Trabajo (Git y Ramas)

Para mantener el código ordenado y evitar conflictos en el equipo, utilizamos el modelo de GitFlow. **Nadie hace commits directos a la rama `main` ni a `develop`.**

**Pasos para programar una nueva característica:**

1. **Actualiza tu entorno local:**
   Asegúrate de estar en la rama de desarrollo y descargar los últimos cambios de tus compañeros.
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. **Crea tu rama de trabajo:**
   Crea una rama nueva específica para la tarea que vas a hacer (ej. inventario, login).
   ```bash
   git checkout -b feature/nombre-de-tu-tarea
   ```

3. **Trabaja y guarda tus cambios:**
   Escribe tu código y haz tus commits regularmente.
   ```bash
   git add .
   git commit -m "feat: descripción clara de lo que hiciste"
   ```

4. **Sube tu rama a GitHub:**
   ```bash
   git push -u origin feature/nombre-de-tu-tarea
   ```

5. **Integra tu código:**
   Ve a la página de GitHub del repositorio y crea un **Pull Request** para fusionar tu rama `feature/...` hacia la rama `develop`.