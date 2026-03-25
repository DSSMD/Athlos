# .devcontainer/Dockerfile
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias base, Java (para Android) y librerías para Linux Desktop
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    openjdk-17-jdk wget \
    clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

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
    && sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 5. Instalar Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# 6. Pre-descargar binarios y habilitar escritorio
RUN flutter config --no-analytics \
    && flutter config --enable-linux-desktop \
    && flutter precache