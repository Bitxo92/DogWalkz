# REQUERIMIENTOS DEL SISTEMA
Este documento describe los requirimentos para la aplicación `DogWalkz` especificando que funcionalidad ofrecerá y de que forma.

## Descripción General

DogWalkz es una aplicación móvil que conecta propietarios de perros con paseadores de confianza, facilitando la organización, reserva y seguimiento de paseos caninos. Ofrece una solución práctica y segura para quienes necesitan apoyo en el cuidado diario de sus mascotas, especialmente en contextos urbanos y con estilos de vida ocupados.

La plataforma permite a los dueños reservar paseadores, gestionar perfiles de sus perros, realizar pagos de forma segura y seguir en tiempo real el recorrido del paseo. A su vez, los paseadores pueden recibir solicitudes, aceptar o rechazar servicios según sus preferencias, y construir una reputación mediante calificaciones de los clientes.

DogWalkz pone énfasis en la confianza, la comodidad y la transparencia, fomentando una comunidad segura donde cada paseo se convierte en una experiencia sencilla y positiva tanto para el dueño como para el paseador.

## Funcionalidades
Esta sección describe los requisitos funcionales necesarios para el correcto funcionamiento de la plataforma, garantizando interacciones fluidas entre clientes y paseadores.

| Categoría                   | Requisito Funcional                                                                                                   |
|----------------------------|------------------------------------------------------------------------------------------------------------------------|
| 📝 Registro e Inicio de Sesión | El sistema debe permitir a los usuarios registrarse de forma segura mediante varios métodos.                          |
|                            | Los usuarios deben poder registrarse con su correo electrónico o redes sociales.                                       |
|                            | El sistema debe permitir a los usuarios iniciar sesión de forma segura.                                               |
|                            | Autenticación mediante correo electrónico/contraseña o cuenta de redes sociales vinculada.                            |
|                            | Recuperación de contraseña por correo electrónico.                                                                    |
| 👤 Gestión de Perfil de Usuario | La plataforma debe proporcionar a los usuarios un perfil personal donde puedan gestionar su información.           |
|                            | Datos personales, dirección, número de teléfono y foto de perfil.                                                     |
|                            | *Cliente:* Lista de perros registrados con nombre, raza, edad, tamaño e indicación si es una raza peligrosa.           |
|                            | Indicación si el perro es sociable.                                                                                   |
|                            | Opción para que un cliente se registre como Paseador.                                                                 |
|                            | *Paseadores:* Definir qué tamaños de perro pueden pasear (por ejemplo, solo pequeños y medianos).                     |
|                            | Indicar si tienen certificación para pasear razas peligrosas (opcional).                                              |
|                            | Verificación de identidad para paseadores mediante NIE o pasaporte.                                                   |
|                            | *Restricción:* Paseadores menores de 18 años solo pueden pasear perros pequeños y medianos.                           |
| 💰 Monedero Virtual y Pagos | El sistema debe incluir un monedero virtual para transacciones seguras entre clientes y paseadores.                  |
|                            | Cargar saldo mediante tarjeta de crédito/débito, PayPal, transferencia bancaria, etc.                                 |
|                            | Historial de transacciones del monedero.                                                                              |
|                            | Pago del servicio desde el monedero antes de que comience el paseo.                                                   |
|                            | El pago se retiene hasta que se complete el paseo.                                                                    |
|                            | Comisión de la plataforma descontada del pago al paseador.                                                            |
|                            | Los usuarios podrán transferir el saldo a su cuenta bancaria.                                                         |
| 📅 Gestión y Agenda        | Los usuarios deben poder solicitar y gestionar paseos de perros de forma eficiente.                                   |
|                            | Los clientes seleccionan la fecha y hora del paseo.                                                                   |
|                            | Indicación del número de perros, tamaño, sociabilidad y si la raza es peligrosa (ya almacenado en el perfil del perro).|
|                            | Los paseadores reciben solicitudes y pueden aceptarlas o rechazarlas.                                                 |
|                            | Restricción automática para asegurar que los paseadores acepten solo perros dentro de su capacidad.                   |
|                            | Inclusión del paseo solicitado dentro de la agenda.                                                                    |
|                            | Seguimiento en tiempo real del paseador durante el paseo.                                                             |
|                            | Historial de rutas y horarios de paseos anteriores.                                                                   |
|                            | El paseador marca el paseo como completado.                                                                           |
|                            | El cliente recibe un prompt para calificar el servicio y se libera el pago al paseador.                               |
| ⭐ Calificaciones y Reseñas | Debe existir un sistema de calificación y reseñas para garantizar la confianza y el control de calidad.               |
|                            | Los clientes pueden calificar a los paseadores.                                                                       |
|                            | Calificaciones promedio visibles en los perfiles.                                                                     |
| 🔔 Notificaciones          | El sistema debe proporcionar notificaciones en tiempo real para eventos clave.                                        |
|                            | Aviso de solicitud de paseo.                                                                                           |
|                            | Notificación en tiempo real al cliente sobre la aceptación o rechazo.                                                 |
|                            | Notificación cuando comienza y termina el paseo.                                                                      |
| 🔒 Seguridad y Soporte     | Debe implementarse un sistema robusto de seguridad y soporte para garantizar la seguridad del usuario.                 |
|                            | Sistema de reporte y soporte para clientes y paseadores.                                                              |
|                            | Botón de emergencia durante el paseo.                                                                                 |
|                            | Verificación de identidad para prevenir problemas relacionados con menores.                                           |
|                            | Políticas de cancelación y reembolsos.                                                                                |
 
## Requerimentos no funcionales
Esta sección describe los requisitos no funcionales para garantizar que la plataforma opere de manera eficiente, segura y confiable.

| Categoría                     | Requisito No Funcional                                                                                       |
|--------------------------------|-------------------------------------------------------------------------------------------------------------|
| 🚀 **Rendimiento y Escalabilidad** | La plataforma debe ser capaz de manejar una alta demanda de usuarios sin degradación del rendimiento.        |
|                                |  La aplicación debe soportar al menos 1,000 usuarios concurrentes sin degradación del rendimiento.         |
|                                |  El tiempo de respuesta debe ser inferior a 3 segundos para operaciones críticas (inicio de sesión, solicitud de caminata, pago, etc.). |
|                                |  Capacidad de escalar horizontalmente a medida que aumenta la demanda.                                       |
| 🔒 **Seguridad**               | Se deben implementar medidas de seguridad para proteger los datos de los usuarios y las transacciones.        |
|                                |  Cifrado de datos sensibles, como contraseñas, utilizando estándares actuales.           |
|                                |  Implementación de mecanismos de autenticación y autorización fuertes para proteger los datos de los usuarios. |
|                                |  Cumplimiento con las regulaciones de protección de datos (GDPR).                                          |
|                                |  Protección contra ataques de inicio de sesión por fuerza bruta o inyección SQL con bloqueo temporal de la cuenta tras intentos fallidos. |
| 🎨 **Usabilidad y Accesibilidad** | La aplicación debe ser fácil de usar y accesible para una amplia gama de usuarios.                           |
|                                |  Diseño responsiva para los diferentes dispositivos móviles.                                                     |
|                                |  Soporte para múltiples idiomas (al menos español e inglés).                                               |
| ⚖️ **Legal y Cumplimiento**    | La plataforma debe cumplir con los requisitos legales en cuanto a protección de datos y acuerdos de usuario.  |
|                                |  Términos de uso y políticas de privacidad claras y accesibles desde la aplicación.                         |
|                                |  Implementación de contratos digitales para la aceptación de servicios.                                    |
| 🛠️ **Mantenimiento y Actualizaciones** | El sistema debe permitir un fácil mantenimiento y actualizaciones futuras.                                     |
|                                |  Registro de errores y monitoreo en tiempo real de la aplicación.                                           |
|                                |  Despliegue continuo (CI/CD) sin interrupción del servicio, mediante Github Actions.                                                |
|                                |  Código fuente bien documentado y estructurado para facilitar actualizaciones futuras y corrección de errores. |
| 📲 **Compatibilidad**          | Compatible con Android (API 31+) y iOS (versión 15+).                                                       |
| 🔄 **Fiabilidad**              | La aplicación debe recuperarse automáticamente de fallos menores y seguir funcionando sin pérdida de datos.   |
| ⚡ **Eficiencia Energética**    | Optimización del uso de recursos para minimizar el consumo de batería en dispositivos móviles.               |

## Tipos de usuarios

En nuestra aplicación existen dos tipos de usuarios: **cliente** y **paseador**. Aunque ambos comparten la mayoría de las pantallas, sus funcionalidades y vistas pueden diferir: El paseador tiene más funcionalidades y acceso a ciertas opciones adicionales que el cliente.

* **Cliente**: El cliente podrá crear solicitudes de paseo, gestionar su perfil, ver el historial de paseos realizados y realizar pagos. La vista de los detalles del paseo estará centrada en la solicitud y en el seguimiento. 

* **Paseador**: El paseador, además de las funcionalidades que tiene el cliente, podrá aceptar o rechazar solicitudes de paseo, gestionar sus paseos, ver detalles adicionales sobre el paseo y marcar el paseo como realizado. La vista de los detalles del paseo incluirá opciones para gestionar el paseo, como cambiar el estado o actualizar información relevante.

> [!NOTE]
> Ambos tipos de usuarios comparten pantallas clave, como la vista de perfil y las solicitudes de paseo, pero las vistas y las opciones se ajustan de acuerdo con el rol del usuario.


## Evaluación de la Viabilidad Técnica del Proyecto

El proyecto será desarrollado utilizando Flutter para el frontend y Supabase como solución backend. Esta arquitectura permite un desarrollo ágil, multiplataforma y escalable, lo cual contribuye positivamente a la viabilidad técnica del sistema.

### Hardware Requerido

Dado que se trata de una aplicación móvil con backend en la nube, el requerimiento de hardware local es mínimo:

- **Dispositivos de desarrollo**: ordenador de sobremesa con procesador moderno (Intel i5/Ryzen 5 o superior),con al menos 16 GB de RAM.
- **Dispositivos móviles para pruebas**: smartphones Android (API 31+) e iOS (versión 15+) para validar el correcto funcionamiento en ambos entornos.
- **Infraestructura backend**: al estar basada en Supabase, el servidor, base de datos y servicios de autenticación corren en la nube, eliminando la necesidad de hardware dedicado propio.

### Software

Se han analizado diversas tecnologías para el desarrollo del sistema y se han seleccionado las siguientes:

- **Flutter**: Framework de código abierto para el desarrollo de aplicaciones móviles, con soporte multiplataforma (Android/iOS), gran comunidad, alta productividad y rendimiento nativo.
- **Supabase**: Plataforma backend como servicio (BaaS) que incluye base de datos PostgreSQL, autenticación, almacenamiento de archivos y funciones serverless, lo que reduce drásticamente la necesidad de configurar y mantener una infraestructura compleja.
- **Herramientas de integración continua (CI/CD)**: GitHub Actions para automatizar pruebas y despliegues.

### Interfaces Externos

Dado que el proyecto se orienta al desarrollo de software, las interfaces externas se clasifican de la siguiente forma:

#### Interfaces de Usuario

- Aplicación móvil desarrollada en Flutter, con pantallas diferenciadas según el tipo de usuario (cliente o paseador).
- Navegación estructurada por rutas y estados, con uso de controladores reactivos.
- Experiencia de usuario optimizada para los diversos tamaños de pantalla móviles mediante diseño responsiva.

#### Interfaces Hardware

- No se requieren interfaces hardware externas específicas.
- Se prevé el uso de funciones nativas del dispositivo como geolocalización, notificaciones push y cámara, mediante paquetes de Flutter (como `geolocator`, `firebase_messaging` y `image_picker`).

#### Interfaces Software

- Comunicación con Supabase a través de APIs REST y WebSocket (en tiempo real).
- Uso de la biblioteca oficial de Supabase para Dart, que permite autenticación de usuarios, lectura/escritura en la base de datos y gestión de archivos.
- Posible integración futura con pasarelas de pago (como Stripe o Redys) mediante SDKs y APIs externas.


## Análisis de Riesgos e Interesados

 ### 1. Interesados del Proyecto

| Interesado               | Interés en el proyecto                          | Nivel de influencia | Estrategia de gestión                             |
|--------------------------|--------------------------------------------------|----------------------|--------------------------------------------------|
| Clientes                 | Usuarios finales del producto o servicio        | Alta                 | Escuchar su feedback, encuestas de satisfacción, dar buen soporte  |
| Inversores/Financiadores| Aportan los recursos económicos                      | Alta                 | Informes regulares, enfoque en rentabilidad      |
| Competencia              | Puede afectar la posición en el mercado         | Media                | Análisis competitivo constante                   |




 ### 2. Análisis de Riesgos

| Riesgo identificado                         | Tipo                               | Probabilidad | Impacto | Medidas de mitigación o respuesta                        |
|---------------------------------------------|-------------------------------------|--------------|---------|----------------------------------------------------------|
| Falta de financiación                       | Económico                           | Media        | Alta    | Diversificar fuentes de ingreso |
| Rechazo de nuestra aplicación en el mercado          | Comercial                           | Media        | Alta    | Estudios de mercado, versión beta abierta y cerrada para usuarios     |
| Incumplimiento legal o normativo            | Legal                               | Baja         | Alta    | Asesoría legal continua, cumplimiento estricto de las regulaciones          |
| Fallos técnicos en el desarrollo            | Técnico                             | Media        | Media   | Realización de pruebas de forma periodica, además de un código limpio y bien documentado facilitando su mantenimiento             |


---

## Actividades

1. **Análisis de Requisitos**  
   - Reunións con dueños de mascotas, además de paseadores profesionales para definir necesidades y expectativas.  
   - Redacción de requisitos funcionales y no funcionales.

2. **Diseño de la Aplicación**  
   - Diseño de la arquitectura general del sistema.  
   - Creación de wireframes y prototipos de interfaz de usuario.  
   - Definir el esquema de la base de datos en Supabase.

3. **Desarrollo del Backend**  
   - Configuración del entorno en Supabase.  
   - Implementación de autenticación, estructura y funciones de la base de datos.

4. **Desarrollo del Frontend**  
   - Construcción de la aplicación móvil en Flutter.  
   - Integración con los servicios backend.  
   - Implementación de funcionalidades clave según el tipo de usuario.

5. **Pruebas y Validación**  
   - Pruebas unitarias y de integración.  
   - Testeo de usabilidad y experiencia de usuario.  
   - Validación funcional con usuarios reales (beta cerrada).

6. **Despliegue y Publicación**  
   - Configuración de pipelines CI/CD con GitHub Actions.  
   - Publicación de la app en Google Play y App Store.

7. **Mantenimiento y Soporte**  
   - Corrección de errores.  
   - Soporte técnico a usuarios.  
   - Monitoreo de rendimiento y análisis de uso.

---

## Mejoras futuras

- Integración con pasarelas de pago externas como Stripe,Bizum o Redsys.  
- Sistema de fidelización y recompensas para clientes frecuentes y paseadores con excelente valoración.  
- Panel web administrador para gestionar usuarios, transacciones y estadísticas además de reportes.  
- Algoritmo de recomendación de paseadores basado en cercanía, historial y calificaciones.  
- Soporte para paseos grupales y eventos comunitarios relacionados con mascotas.  
- Sistema de chat en tiempo real entre cliente y paseador.  
- Notificaciones push inteligentes basadas en geolocalización y hábitos del usuario.  
- Integración con dispositivos IoT para seguimiento avanzado (como collares inteligentes).  
- Expansión internacional con soporte para nuevos idiomas y normativas locales.