# Tempo 📱

**Tempo** es una herramienta de bienestar digital diseñada para quienes buscan optimizar su relación con la tecnología y retomar el control de su tiempo frente a la pantalla. A diferencia de las aplicaciones de bloqueo tradicionales, Tempo actúa como un asistente de atención que fomenta la autogestión, sustituyendo las restricciones rígidas por alertas que invitan a la reflexión.

## 🚀 Propósito

El objetivo es ayudar al usuario a gestionar su consumo digital mediante una experiencia menos impulsiva. Mediante la integración con el API `UsageStatsManager` de Android, la aplicación monitorea el tiempo de uso en tiempo real y despliega alertas cuando se superan umbrales predefinidos. Esta pausa contextual permite al usuario decidir si desea continuar navegando o retomar sus actividades, promoviendo un uso intencional del dispositivo sin recurrir a bloqueos invasivos.

## 🛠 Stack Tecnológico

- **Framework**: Flutter
- **Arquitectura**: Clean Architecture (Domain, Infrastructure, Presentation)
- **Gestión de Estado**: Riverpod
- **Persistencia**:
- **Plataforma**: Android (Android-First)

## 🔑 Características Diferenciales

- **Enfoque en la Intención**: No bloqueamos aplicaciones; intervenimos mediante una capa de reflexión que devuelve el control de la decisión al usuario.
- **Intervención no Invasiva**: Uso estratégico de capas de interfaz para interactuar solo cuando es necesario, sin interrumpir el flujo de trabajo del usuario innecesariamente.
- **Arquitectura Escalable**: Código modular diseñado para facilitar el mantenimiento y la integración de futuras funcionalidades de análisis de comportamiento.portamiento.

## 🏗 Estructura del Proyecto

```text
lib/
├── config/             # Configuración, temas y rutas
├── domain/             # Reglas de negocio y entidades
├── infrastructure/     # Implementación técnica, mappers y modelos
├── presentation/       # UI, Widgets y Providers (Riverpod)
```

## 👨‍💻 Autor

**Camilo Guardias**  
[GitHub: @Jguardias](https://github.com/Jguardias) | [LinkedIn: Camilo Guardias](https://www.linkedin.com/in/jguardias/)

_Ingeniero de Software | Flutter & Clean Architecture_
