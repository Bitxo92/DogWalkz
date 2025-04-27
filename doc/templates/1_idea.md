# DogWalkz 🐾: ¡Aplicación para programar paseos de perros sin esfuerzo!

## Resumen

DogWalkz conecta a los propietarios de perros con paseadores, ofreciendo un servicio confiable e intuitivo para reservar, rastrear y gestionar los paseos de perros. La plataforma garantiza seguridad, comodidad y facilidad de uso, lo que la convierte en ideal para los dueños de mascotas que necesitan ayuda para cuidar a sus perros. El proyecto no solo se enfocará en las etapas de planificación y diseño, sino que también entregará una aplicación móvil completamente funcional y multiplataforma.

El objetivo principal de DogWalkz es proporcionar una solución confiable y fácil de usar para los propietarios de perros que necesitan asistencia para pasear a sus mascotas. Está dirigida a dos grupos principales de usuarios: dueños de perros ocupados que pueden tener dificultades para encontrar tiempo para los paseos diarios y paseadores profesionales que buscan conectarse con nuevos clientes. Este servicio encaja perfectamente en contextos urbanos y suburbanos, donde la tenencia de mascotas es alta y la demanda de servicios de cuidado de mascotas continúa creciendo.

DogWalkz aborda varias necesidades clave, incluyendo la provisión de una forma segura de reservar paseadores de perros, habilitar el rastreo en tiempo real de los paseos para los propietarios y facilitar pagos seguros. Además de resolver un problema clave, la aplicación abre grandes oportunidades de negocio a través de un modelo basado en comisiones, suscripciones premium opcionales para beneficios adicionales y posibles asociaciones con empresas de productos para mascotas. Estas vías comerciales hacen que la plataforma sea escalable y sostenible.

Aunque existen aplicaciones como Rover y Wag!, muchos usuarios las encuentran complejas o limitadas a áreas metropolitanas más grandes. DogWalkz tiene como objetivo mejorar esto ofreciendo una experiencia más intuitiva, asegurando la transparencia de los pagos, apoyando varios idiomas y fomentando una comunidad confiable a través de reseñas de usuarios y un sistema de reputación confiable.

Los objetivos principales son desarrollar una plataforma móvil segura y fácil de usar, gestionar perfiles de usuarios tanto para propietarios como para paseadores, ofrecer rastreo en tiempo real mediante GPS durante los paseos y proporcionar un sistema de monedero protegido para manejar pagos. Los requisitos esenciales incluyen autenticación segura (OAuth), gestión robusta del backend (Supabase), desarrollo intuitivo del frontend móvil (Flutter), servicios de localización en tiempo real y soporte multilingüe para llegar a una audiencia internacional más amplia.

## Características principales

### 📝 **Registro e inicio de sesión de usuario**
- **Registro sencillo**: Los usuarios (propietarios y paseadores) pueden registrarse fácilmente usando correo electrónico, teléfono o cuentas de redes sociales.
- **Autenticación segura**: Ingreso mediante correo electrónico/contraseña o redes sociales vinculadas, con opciones de recuperación de contraseña.

### 👤 **Perfiles de usuario**
- **Perfiles de propietarios de perros**: Almacenan información personal de los usuarios
- **Perfiles de paseadores**: Incluyen detalles personales, experiencia y calificaciones según el tamaño del perro (pequeño/medio/grande) para asegurar compatibilidad con los tipos de perros.

### 💰 **Monedero virtual y pagos**
- **Métodos de pago flexibles**: Los clientes pueden cargar fondos mediante tarjetas de crédito/débito, PayPal y transferencias bancarias.
- **Retención de pagos**: Los pagos se mantienen de forma segura hasta que el paseo se complete, con los paseadores pudiendo transferir los fondos a sus cuentas bancarias.

### 📍 **Rastreo en tiempo real de los paseos**
- **Rastreo de ubicación**: Los clientes pueden rastrear la ubicación en tiempo real del paseador durante el paseo para tranquilidad y transparencia.
- **Finalización del paseo**: Después de cada paseo, los clientes reciben una notificación para calificar el servicio y los pagos se procesan de manera segura.

### ⭐ **Calificaciones y reseñas**
- **Sistema de reputación**: Los clientes y paseadores pueden calificarse mutuamente, lo que contribuye a una comunidad confiable.
- **Retroalimentación y calificaciones**: Las reseñas ayudan a mantener un servicio de alta calidad y brindan retroalimentación valiosa para mejorar.

## Tecnologías

### **Desarrollo Frontend**
- **Flutter** </> : Un marco poderoso para construir aplicaciones móviles multiplataforma tanto para iOS como para Android. Garantiza interfaces de usuario rápidas y receptivas, proporcionando una experiencia fluida para todos los usuarios.

<img src="https://storage.googleapis.com/cms-storage-bucket/4fd0db61df0567c0f352.png" alt="Flutter Logo" height="100"/>

### **Desarrollo Backend**
- **Supabase** ⛃ : Un servicio de backend de código abierto (BaaS) que proporciona almacenamiento de bases de datos, autenticación y capacidades en tiempo real. Simplifica la gestión del backend, el escalado y la seguridad sin la necesidad de construir desde cero.

<img src="https://raw.githubusercontent.com/supabase/supabase/master/packages/common/assets/images/supabase-logo-wordmark--dark.png" alt="Supabase Logo" height="100"/>

### **Autenticación y seguridad**
- **OAuth** 🔐 : Autenticación segura y escalable, que permite inicios de sesión en redes sociales y gestión de sesiones basada en tokens.
- **JWT Tokens** 🔑 : Los JSON Web Tokens se usarán para gestionar sesiones de forma segura, permitiendo autenticación sin estado en múltiples plataformas y mejorando la escalabilidad.

<img src="https://oauth.net/images/oauth-logo-square.png" alt="OAuth Logo" height="100"/>

---

### Beneficios de este enfoque

1. **Facilidad de uso**: La plataforma proporcionará una experiencia fácil de usar y fácil de navegar, asegurando que tanto los propietarios de perros como los paseadores puedan gestionar rápidamente sus cuentas y solicitudes.
2. **Seguridad**: Con OAuth y gestión de sesiones basada en JWT, la plataforma asegura la privacidad del usuario y la protección de los datos.
3. **Escalabilidad**: Al utilizar **Flutter** y **Supabase**, la plataforma puede escalar fácilmente para acomodar a más usuarios a medida que el servicio crece.
