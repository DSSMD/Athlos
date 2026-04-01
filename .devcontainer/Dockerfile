# .devcontainer/Dockerfile
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias base, Java (para Android) y librerías para Linux Desktop
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa mesa-utils \
    openjdk-17-jdk wget \
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# 1.5 Instalar Google Chrome y definir variable de entorno (Como root)
RUN apt-get update \
    && wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y ./google-chrome-stable_current_amd64.deb \
    && rm google-chrome-stable_current_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV CHROME_EXECUTABLE=/usr/bin/google-chrome

# Crear usuario desarrollador
RUN useradd -ms /bin/bash developer
USER developer
WORKDIR /home/developer

# 2. Configurar variables de entorno para Android SDK y Flutter
ENV ANDROID_HOME="/home/developer/android-sdk"
ENV FLUTTER_HOME="/home/developer/flutter"
ENV PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$FLUTTER_HOME/bin:$PATH"

# 3. Descargar e instalar Android Command Line Tools
RUN mkdir -p $ANDROID_HOME/cmdline-tools \
    && cd $ANDROID_HOME/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip \
    && unzip -q cmdline-tools.zip \
    && rm cmdline-tools.zip \
    && mv cmdline-tools latest

# 4. Aceptar licencias de Android e instalar plataformas y build-tools
RUN yes | sdkmanager --licenses \
    && sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0" "build-tools;28.0.3"

# 5. Instalar Flutter (Fijando la versión 3.41.6 sin romper el canal stable)
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME \
    && cd $FLUTTER_HOME \
    && git reset --hard 3.41.6

# 6. Pre-descargar binarios y habilitar escritorio
RUN flutter config --no-analytics \
    && flutter config --enable-linux-desktop \
    && flutter config --enable-web \
    && flutter precache