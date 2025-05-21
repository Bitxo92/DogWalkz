# Fase de produción

# Manual técnico e de administración

### Información relativa á instalación ou despregamento:

* Se precisas dun servicio, como unha base de datos, servidor, servicios na nube... indica os pasos a seguir para poder despregar/instalar o teu sistema.
* Especifica o software necesario e a súa posta a punto (SO, servidores, etc).
* Configuración inicial seguridade: devasa, control usuarios, rede.
* Se fora o caso, explica o proceso de carga inicial de datos na base de datos ou migración de datos xa existentes noutros formatos.
* Alta de usuarios dos sistemas necesarios.

### Información relativa á administración do sistema, é dicir, tarefas que se deberán realizar unha vez que o sistema estea funcionando, como por exemplo

* Copias de seguridade do sistema.
* Copias de seguridade da base de datos.
* Xestión de usuarios.
* Xestión seguridade.

### Información relativa ó matemento do sistema

* Especifica o sistema para mellorar e corrixir os erros detectados.
* Xestión de incidencias: como se atenderán e resolverán. Indica como poderán os usuarios comunicar as incidencias.

# Manual de usuario

### Formación de usuarios 
* Indicar se será necesario formar ós usuarios. En caso afirmativo planificar e xustificar.

### Instrucións iniciais
* Elabora un manual breve coa información necesaria para o uso da aplicación.

### FAQ

**¿El app está disponible para iphone?**  
Si, tenemos tanto una versión ios como android.

**¿Cómo me doy de alta como paseador?**  
Desde tu pantalla de perfil de usuario, activa la opción **activar modo paseador** y rellena los campos necesarios.

**¿Cómo recupero mi contraseña?**  
Desde la pantalla de inicio de sesión, selecciona "*Forgot Password?*" y sigue los pasos para restablecerla vía email.

**¿Puedo usar la app en más de un dispositivo?**  
Sí, solo asegúrate de iniciar sesión con las mismas credenciales.

**¿Qué pasa si el paseador no llega?**  
Puedes cancelar el paseo desde la app. Si ya pagaste, el saldo se reembolsa automáticamente.

**¿Puedo pasear perros peligrosos?**  
Solo si has indicado en tu perfil que posees la certificación correspondiente.

**¿Cómo califico un paseo?**  
Después de completarlo, saldrá una dialogo para puntuar el paseo 1-5 y escribir una reseña. Esta reseña solo es visible para los integrantes del paseo

**¿Qué hago si hay un incidente durante el paseo?**  
En la sección detalles del paseo puedes optar por 2 opciones:
    - contactarnos a través de soporte por la opción "*llamanos*" al tratarse de una urgencia, para ser atendido de forma inmediata.
    - llamar directamente al dueño del perro.

---

# Protección de datos de carácter personal

En DogWalkz gestionamos datos personales y sensibles cumpliendo con el Reglamento General de Protección de Datos (GDPR). 

## Almacenamiento y seguridad

- Los datos se almacenan de forma segura en **Supabase**, usando base de datos cifrada.
- La comunicación con el backend se realiza siempre por conexiones **HTTPS** seguras.
- Las contraseñas y datos sensibles están protegidos mediante cifrado AES-256.

## Autenticación y control de acceso

- Usamos **OAuth** para autenticar usuarios con proveedores externos.
- Aplicamos **Row Level Security (RLS)** con **JWT** para que cada usuario solo pueda acceder a sus propios datos, garantizando un control estricto y personalizado de acceso.

## Derechos y transparencia

- Informamos a los usuarios sobre el tratamiento de sus datos en nuestra Política de Privacidad.
- Los usuarios pueden acceder, modificar o eliminar sus datos en cualquier momento.
- Conservamos los datos solo mientras la cuenta esté activa, garantizando su eliminación al cierre.

Con esta implementación aseguramos el cumplimiento efectivo del GDPR, protegiendo la privacidad y seguridad de los datos personales de todos los usuarios.
