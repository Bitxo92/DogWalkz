# Fase de producción

# Manual técnico e de administración

## Información relativa a la instalación o despliegue

Este apartado describe el proceso necesario para desplegar la aplicación móvil **DogWalkz**, en las dos principales plataformas: **Google Play Store** y **Apple App Store**.

---

### Publicación en Google Play Store (Android)

#### 1. Preparación del proyecto

- Configurar correctamente el archivo `android/app/build.gradle`:
  - `applicationId`
  - `versionCode`
  - `versionName`
  - `minSdkVersion` (mínimo 21)
- Añadir íconos y pantalla de inicio con [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) y [flutter_native_splash](https://pub.dev/packages/flutter_native_splash).

#### 2. Generar APK o AAB

- Generar un **Android App Bundle (.aab)** para la Play Store con el comando:
  ```bash
  flutter build appbundle
  ```
- El archivo generado se encontrará en `build/app/outputs/bundle/release/app-release.aab`

#### 3.Crear cuenta de Google Play

- Registrar una cuenta de desarrollador en: https://play.google.com/console 

> [!CAUTION]
> Se requiere un pago único de **$25 USD** para el registro de la cuenta de desarrollador.

#### 4. Crear la aplicación en Google Play Console:

- Añadir nombre de la app, idioma principal y tipo.
- Completar la ficha de la aplicación (descripción corta, larga, capturas, icono, etc.).
- Rellenar el cuestionario de clasificación de contenido y política de privacidad.
- Subir el archivo .aab en **"Releases" --> "Production"**.

#### 5. Publicación
- mandar a revisión de Google (1-7 días aprox).
- Una vez aprobada, la app estará disponible en Google Play Store.

### Publicación en Apple App Store (iOS)

#### 1. Requisitos previos

- Tener una cuenta de desarrollador Apple activa:  
  [Apple Developer Program](https://developer.apple.com/programs/)  
> [!CAUTION]
> El programa de desarrolladores de Apple exige un pago anual de **$99 USD**

- Mac con Xcode instalado 
- Certificados y perfiles de aprovisionamiento configurados:
  - Certificado de distribución iOS
  - Perfil de aprovisionamiento para producción

#### 2. Preparación del proyecto Flutter

- Configurar `ios/Runner.xcodeproj`:
  - Establecer `Bundle Identifier` único (ejemplo: `com.tuempresa.dogwalkz`)
  - Ajustar versión (`CFBundleShortVersionString`) y build (`CFBundleVersion`)
- Añadir iconos y splash screen para iOS (puedes usar paquetes como `flutter_launcher_icons` y `flutter_native_splash`).

#### 3. Generar archivo IPA

- Desde la terminal, dentro del proyecto Flutter:
  ```bash
  flutter build ios --release --no-codesign
  ```
- Abre el proyecto en Xcode (ios/Runner.xcworkspace):
   - Selecciona el target Runner
   - Firma el proyecto con tu equipo de desarrollo y certificado de distribución
   - Archiva el proyecto(Menú: Product --> Archive)
- Desde el *Organizer* de Xcode, exporta el archivo `.ipa` para App Store.

#### 4. Subir a App Store Connect

- Ingresa a [AppStore Connect](https://appstoreconnect.apple.com/login)
- Crea una nueva aplicación y rellena su ficha (Nombre, idioma, bundle ID, categoría, etc.).
- Sube el archivo `.ipa`, existen 2 formas de realizar este paso:
   - En Xcode desplazate a **Organizer --> Upload**
   - La herramienta **Transporter** (disponible en Mac App Store)

#### 5. Configurar la aplicación en App Store Connect

- Introduce los metadatos(descripción, capturas de pantalla, clasificación de contenido y políticas de privacidad).
- Configura precios y disponibilidad.

#### 6. Enviar para revisión y publicación.

- Enviar a apple para revisión(tarda entre 1-7 días aprox.).
- Una vez aprobada, ya estará disponible en la tienda de App Store.

> [!NOTE]
> Apple recomienda automatizar la generación y despliegue con herramientas como **Fastlane** para facilitar actualizaciones y gestionar certificados, builds y publicaciones de forma segura y repetible.








## Información relativa a la administración del sistema

Una vez que el sistema está en funcionamiento, se establece una estrategia clara de administración para garantizar su estabilidad y continuidad operativa. 
Se realizan respaldos manuales periódicos de la configuración crítica del proyecto, incluyendo el esquema de la base de datos, funciones (SQL y Edge Functions), políticas de seguridad (RLS) y configuración de autenticación. 
Estas exportaciones se llevan a cabo desde el panel de Supabase o mediante herramientas como `pg_dump` para asegurar una copia actualizada del estado del sistema.

Las copias de seguridad de la base de datos se gestionarán mediante los backups automáticos diarios proporcionados por Supabase Pro(*Plan de Pago*). Adicionalmente, se realizarán copias manuales utilizando una conexión directa a PostgreSQL, mediante comandos `pg_dump` o desde el panel de administración en la sección  **Database > Backups**. Este proceso también estará automatizado con scripts externos e integraciones CI/CD que mantienen versiones periódicas de los datos críticos.

La gestión de usuarios se realizará a través del panel administrador de supabase. Desde este panel, en la sección **Authentication --> Users** podemos: crear, supervisar o eliminar usuarios según sea necesario. También nos permite configurar los métodos de autenticación que deseamos incorporar como son: email/password, OAuth o magic links, además de aplicar políticas como la verificación obligatoria de correo electrónico y/o expiración de sesiones.Por último, mencionar que se realizará una revisión periódica de cuentas inactivas o sospechosas para mantener la integridad del sistema.

En cuánto a la gestión de la seguridad, se asegura activando y configurando políticas RLS(*Row Level Security*) en todas las tablas, con especial atención en aquellas que contienen datos sensibles, restringiendo el acceso según los roles de usuario. Las claves API se mantienen protegidas limitando el uso de la `anon key` exclusivamente al frontend(protegido en el .env) y reservando la `service_role` key para procesos seguros en backend. Se revisarán regularmente las políticas de seguridad, se aplicará autenticación robusta y se utilizarán herramientas de monitoreo(**Sentry**) para detectar y responder a posibles amenazas.



## Información relativa al matenimiento del sistema
El mantenimiento de la aplicación se sustentará en un sistema automatizado orientado a la detección proactiva de errores, su análisis en tiempo real y la ejecución controlada de despliegues correctivos. 
Se utilizarán herramientas como Sentry para el monitoreo continuo y la trazabilidad de fallos, junto con GitHub Actions para la automatización de flujos CI/CD.

Sentry estará integrado de forma nativa en nuestra aplicación, permitiendo la captura automática(*en tiempo real*) de errores y excepciones que ocurren durante la ejecución. Esta integración registra de manera precisa toda la información relevante asociada a cada incidencia, incluyendo: 

- la traza completa de la pila (stack trace)
- la versión exacta de la aplicación en la que ocurrió el error
- detalles específicos del dispositivo afectado (modelo, sistema operativo, configuración)
- métricas sobre la frecuencia del error (p.ej:número de usuarios impactados).

Una vez identificado un error, se abre una incidencia (issue) en el repositorio de GitHub. Desde allí, el equipo de desarrollo puede gestionar su corrección creando una rama específica donde se realiza la solución. 
Estas ramas se integran posteriormente a la rama principal mediante una solicitud de extracción (pull request), que activa automáticamente los flujos de trabajo (*pipelines*) definidos en GitHub Actions.

GitHub Actions se encarga de ejecutar automáticamente una serie de tareas definidas en un archivo de configuración YAML. Estas tareas incluyen: 
- análisis estático del código (*linting*) 
- ejecución de pruebas automatizadas 
- generación de builds para Android e iOS. 

En el caso de Android, se genera un archivo `.aab` (Android App Bundle) que está listo para ser subido a Google Play. 

En iOS, se genera un archivo `.ipa` firmado, utilizando certificados previamente configurados, que se sube mediante la herramienta fastlane.

El proceso de actualización para Android se realiza a través de la Google Play Console, utilizando la API de publicación. Según la configuración, se puede automatizar la subida a canales específicos (*Alfa, Beta o Producción*). 

Para iOS, el despliegue se realiza mediante App Store Connect, con fastlane gestionando el envío automático de builds a TestFlight. Tras una validación manual, se aprueba su publicación en la App Store.

``` mermaid
%%{init: { 'theme': 'base', 'themeVariables': { 'primaryColor': '#ffdfd3', 'primaryBorderColor': '#d291bc', 'primaryTextColor': '#000000'}}}%%
timeline
   
    
    section Gestión de Incidencias
    Issue creada en GitHub : Error detectado por Sentry
    Asignación a desarrollador : Creación de rama (fix/error-id)
    
    section Desarrollo
    Implementación de solución : Commit en rama específica
    Pull Request (PR) : Revisión de código
    
    section CI/CD Automatizado
    GitHub Actions triggered : Linting Pruebas unitarias : Build Android (.aab) : Build iOS (.ipa)
    Validación exitosa : Merge a rama principal
    
    section Despliegue
    Android :  Subida automática a Google Play : Distribución en canal Beta
    iOS : Fastlane sube a TestFlight : Validación manual requerida
    Publicación : Android(Rollout progresivo): iOS(Release en App Store)
```

# Manual de usuario

## Formación de Usuarios

Nuestra aplicación ha sido **diseñada y desarrollada con enfoque UI/UX**, garantizando una experiencia fluida, accesible e intuitiva para todo tipo de usuarios. Se han rediseñado cuidadosamente todas las pantallas y flujos presentes en este apartado, con el objetivo de eliminar cualquier fricción en la navegación.

Además, al acceder por primera vez desde un dispositivo, se activará un **tutorial interactivo (Coach)** que guiará paso a paso por las principales secciones de la app, facilitando la comprensión de cada funcionalidad.
Gracias a esta experiencia guiada, no se requiere formación adicional para comenzar a usar la aplicación con soltura.


## Instrucións iniciais
A continuación, te guiamos paso a paso para comenzar a utilizar la app según tu tipo de usuario:


### 1. Descarga e Instalación

1. Abre la tienda de aplicaciones de tu móvil:
   - Android: Google Play Store
   - iOS: App Store

2. Busca "DogWalkz".

3. Pulsa "Instalar" y espera a que se descargue e instale la aplicación.

4. Abre la app desde el ícono que aparecerá en tu pantalla de inicio.

---

### 2. Registro de Usuario

1. En la pantalla de inicio, pulsa la opción **"¿No tienes cuenta?,registrate"**.

2. Elige uno de los métodos disponibles:
   - Correo electrónico y contraseña.
   - Cuenta de Google o redes sociales (Facebook o Instagram).

3. Introduce los datos solicitados(solo para opción correo electrónico):
   - Nombre de Usuario
   - Correo electrónico
   - Contraseña segura

4. Verifica tu cuenta:
   - Se enviará un enlace a tu correo electrónico.
   - Pulsa el enlace para completar el proceso de verificación.

---

### 3. Creación y Configuración del Perfil

Después del registro, completa tu perfil según tu rol:

#### Clientes:

1. Accede a la sección **"Perfil"** desde el menú inferior.

2. Completa tu información personal:
   - Nombre completo
   - Dirección
   - Número de teléfono
   - Foto de perfil

3. Una vez creado tu perfil, dirígete a la sección **"Perros"** en el menú inferior.

4. Para agregar un perro:
   - Pulsa el botón con forma de pata ubicado en la esquina inferior izquierda de la pantalla.
   - Completa el formulario con los siguientes datos:
     - **Nombre**
     - **Raza**
     - **Edad**
     - **Tamaño**: selecciona entre pequeño, mediano o grande
     - **¿Es sociable?** (Sí/No)
     - **¿Pertenece a una raza potencialmente peligrosa?** (Sí/No)
     - **Instrucciones especiales**: aquí puedes detallar necesidades específicas del perro, como alergias, comportamiento con otros animales, medicamentos, etc.



#### Paseadores:
1. Tras completar tu perfil básico, selecciona la opción **"Modo Paseador"**.
2. Rellena información adicional:
   - Tamaños de perro que aceptas (pequeño/mediano/grande)
   - Certificación para razas peligrosas (opcional)
   - Documento de identidad (NIE o pasaporte, obligatorio)



---

### 4. Uso del Monedero Virtual

#### Clientes:

1. Accede a la sección **"Monedero"** desde el menú inferior de la aplicación.
2. Pulsa el botón **"Depositar"** para añadir fondos a tu cuenta.
3. Introduce la **cantidad** deseada.
4. Selecciona el **método de pago** (*No disponible durante la fase beta cerrada*):
   - Tarjeta de crédito o débito
   - PayPal
   - Stripe
   - Transferencia bancaria
5. Una vez finalizado el proceso, tu saldo se actualizará y estará disponible para poder solicitar un paseo.

##### Historial de Transacciones:
- Puedes consultar todos tus movimientos desde la pestaña **"Historial"** dentro del Monedero.
- Cada transacción incluye:
  - **Fecha**
  - **Cantidad**
  - **Tipo de transacción**
  - **ID de transacción** (puede copiarse al portapapeles para enviarlo a Soporte en caso de incidencias)

##### Filtro de historial:
- Puedes filtrar tus transacciones por:
  - **Esta semana**
  - **Este mes**
  - **Últimos 6 meses**
  - **Todo**


#### Paseadores:

1. Dirígete a la sección **"Monedero"** desde el menú inferior.
2. Consulta tu **saldo disponible**, correspondiente a los servicios ya completados y validados.
3. Para transferir fondos a tu cuenta bancaria:
   - Pulsa **"Retirar"**
   - Introduce los datos bancarios
   - Confirma la operación

##### Historial de ingresos:
- Desde la pestaña **"Historial"** puedes ver todos los pagos recibidos.
- Cada entrada incluye:
  - **Fecha del servicio**
  - **Monto abonado**
  - **ID de transacción** (puede copiarse al portapapeles)

##### Filtro de historial:
- Usa los filtros para revisar movimientos por:
  - **Semana actual**
  - **Mes actual**
  - **Últimos 6 meses**
  - **Todos los registros**

> [!TIP] 
> la copia del ID de transacción puede ser útil en caso de reclamos o soporte técnico.
---

### 5. Solicitar un Paseo (Clientes)

1. En el menú inferior, pulsa el botón central **"+"** para iniciar una nueva solicitud.
2. Completa los siguientes campos:
   - **Ciudad** donde se realizará el paseo.
   - **Fecha y hora de inicio y fin**, determinando así la duración del paseo.
   - **Perros que participarán en el paseo** (puedes seleccionar uno o varios de los registrados).
   - **Selecciona el paseador** que más de convenzca. 

3. Revisa cuidadosamente el **costo total del servicio**, visible antes de confirmar la solicitud.
4. Pulsa **"Enviar Solicitud"** para iniciar el proceso.
5. Una vez enviada, solo debes **esperar la confirmación** del paseador.

> [!NOTE]
> El dinero del paseo será **retenido temporalmente por DogWalkz** hasta que el servicio haya sido completado.  
> En caso de cancelación del paseo, el dinero será reembolsado a tu monedero.
> Esta medida garantiza la **seguridad, transparencia y confianza** para todos los usuarios.

---

### 6. Aceptar un Paseo (Paseadores)

1. Accede a tus **notificaciones** pulsando el icono de la **campanita** ubicado en la parte superior derecha de la pantalla principal.
   - Si tienes **solicitudes nuevas**, aparecerá un aviso visual en la campanita indicando el número de notificaciones pendientes.

2. Consulta la información de cada solicitud:
   - Fecha y hora
   - Ubicación del paseo
   - Detalles de los perros (nombre, raza, sociabilidad, tamaño)
   - Duración estimada

3. Evalúa si puedes realizar el paseo según tu disponibilidad y capacidad.
4. Pulsa **"Aceptar"** para confirmar el servicio o **"Rechazar"** si no puedes realizarlo.

> [!TIP]
> Al aceptar un paseo, este se añadirá automáticamente a tu **agenda** y el cliente será notificado inmediatamente.

---

### 7. Durante el Paseo

#### Cliente:
- Recibirás una notificación automática cuando el paseador inicie el paseo.
- Podrás seguir el recorrido en tiempo real:
  1. Entra a la sección **"Mis Paseos"** y selecciona el paseo activo.
  2. Pulsa sobre la **barra de estado** en la parte superior de la pantalla de detalles.
     - Esta barra mostrará un **indicador visual dinámico** (ícono GPS animado) para señalar que el paseo está en curso y que el seguimiento está disponible.
  3. Se abrirá un **mapa interactivo** con la ruta que sigue el paseador.

#### Paseador:
- Una vez estés listo para comenzar, accede al detalle del paseo y pulsa el botón **"Iniciar Paseo"**.
- La aplicación activará automáticamente el **seguimiento por GPS** y registrará la ruta en segundo plano.


> [!NOTE]
> Asegúrate de tener la **geolocalización activada** y permisos concedidos para que el seguimiento funcione correctamente.
> Se desactivará la geolocalización al finalizar el paseo.
> Esto asegura transparencia y confianza en nuestra plataforma, brindando al dueño la tranquilidad de saber que su mascota está en buenas manos.
---

### 8. Finalización y Calificación

#### Cliente:
1. Al finalizar el paseo, recibirás un mensaje para **calificar al paseador**.
2. Puedes dejar una reseña.
3. El pago se libera automáticamente al paseador.

#### Paseador:
- Recibirás una notificación de paseo completado.
- Verás reflejado en tu monedero el importe del paseo liberado y disponible.

> [!NOTE]
> La calificación del paseador se actualiza tras este paso y es visible públicamente.
> La reseña, en cambio, solo estará accesible para las partes implicadas, para evitar abusos y ofrecer al paseador una oportunidad de mejorar sin afectar negativamente su cuenta.

---

### 9. Soporte y Seguridad

En la sección **Detalles del Paseo** encontrarás la opción **Soporte**, donde podrás contactar con nuestro equipo a través de varios medios:  
- WhatsApp  
- Telegram  
- Correo electrónico  
- Teléfono 

Esta sección está diseñada para ayudarte a resolver cualquier incidencia, ofrecer asistencia o mediar en disputas entre cliente y paseador.

---


### 10. Consejos Finales

- Mantén actualizados los datos de tu perfil y los de tus perros.
- Habilita la geolocalización y las notificaciones para mejorar la experiencia.
- Usa siempre la app para pagos y gestión de servicios: es más seguro y transparente para ambas partes.

---




## FAQ

- **¿La app está disponible para iPhone?**  
  Sí, DogWalkz está disponible tanto para iOS como para Android.

- **¿Cómo me doy de alta como paseador?**  
  Desde tu perfil de usuario, activa la opción **"Activar modo paseador"** y completa los campos requeridos, incluyendo la verificación de identidad si es necesario.

- **¿Cómo recupero mi contraseña?**  
  En la pantalla de inicio de sesión, selecciona "*¿Olvidaste tu contraseña?*" y sigue las instrucciones para restablecerla por correo electrónico.

- **¿Puedo usar la app en más de un dispositivo?**  
  Sí, puedes acceder desde varios dispositivos siempre que utilices las mismas credenciales de inicio de sesión.

- **¿Qué pasa si el paseador no se presenta?**  
  Puedes cancelar el paseo desde la app. Si ya realizaste el pago, el saldo se reembolsa automáticamente a tu monedero virtual.

- **¿Puedo pasear perros considerados potencialmente peligrosos?**  
  Solo si has indicado en tu perfil que cuentas con la certificación oficial para ello.

- **¿Cómo califico un paseo?**  
  Al finalizar el paseo, se te mostrará un cuadro para valorar el servicio de 1 a 5 estrellas y dejar una reseña. Esta será visible solo para las partes involucradas.

- **¿Qué hago si ocurre un incidente durante el paseo?**  
    Desde la sección *Detalles del paseo* puedes:

    - **Contactar con soporte** usando la opción "*Llámanos*", para asistencia inmediata en casos urgentes.  
    - **Llamar directamente al dueño del perro**, si la situación lo requiere.




# Protección de datos de carácter personal

En DogWalkz gestionamos datos personales y sensibles cumpliendo con el Reglamento General de Protección de Datos (GDPR). 

- **Almacenamiento y seguridad:**

   - Los datos se almacenan de forma segura en **Supabase**, usando base de datos cifrada.
   - La comunicación con el backend se realiza siempre por conexiones **HTTPS** seguras.
   - Las contraseñas y datos sensibles están protegidos mediante cifrado AES-256.

- **Autenticación y control de acceso:**

   - Usamos **OAuth** para autenticar usuarios con proveedores externos.
   - Aplicamos **Row Level Security (RLS)** con **JWT** para que cada usuario solo pueda acceder a sus propios datos, garantizando un control estricto y personalizado de acceso.

- **Derechos y transparencia:**

   - Informamos a los usuarios sobre el tratamiento de sus datos en nuestra Política de Privacidad.
   - Los usuarios pueden acceder, modificar o eliminar sus datos en cualquier momento.
   - Conservamos los datos solo mientras la cuenta esté activa, garantizando su eliminación al cierre.

> [!NOTE]
> Con esta implementación aseguramos el cumplimiento efectivo del GDPR, protegiendo la privacidad y seguridad de los datos personales de todos los usuarios.
