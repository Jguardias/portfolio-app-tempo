# Tempo 📱

**Tempo** es una aplicación de bienestar digital y productividad diseñada para profesionales que buscan optimizar su relación con la tecnología. A diferencia de las aplicaciones tradicionales de bloqueo, Tempo actúa como un "mentor de atención" que utiliza intervenciones inteligentes para fomentar la autogestión en lugar de la restricción pasiva.

## 🚀 Propósito

El objetivo de Tempo es romper el ciclo de consumo inconsciente de aplicaciones móviles. Mediante el uso de `UsageStatsManager` de Android, la aplicación detecta patrones de uso y presenta "nudge" (pequeños empujones) que invitan al usuario a reflexionar sobre su intención antes de continuar navegando.

## 🛠 Stack Tecnológico

- **Framework**: Flutter
- **Arquitectura**: Clean Architecture (Domain, Infrastructure, Presentation)
- **Gestión de Estado**: Riverpod
- **Persistencia**:
- **Plataforma**: Android (Android-First)

## 🔑 Características Diferenciales

- **Enfoque en Intención**: No bloqueamos aplicaciones; intervenimos con una capa de reflexión que devuelve el control al usuario.
- **Intervención no Invasiva**: Uso estratégico de capas de interfaz para no interrumpir el flujo de trabajo innecesariamente.
- **Arquitectura Escalable**: Código modular diseñado para facilitar el mantenimiento y la escalabilidad de nuevas funcionalidades de comportamiento.

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
