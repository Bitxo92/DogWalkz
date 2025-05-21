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

**¿La app está disponible para iPhone?**  
Sí, DogWalkz está disponible tanto para iOS como para Android.

**¿Cómo me doy de alta como paseador?**  
Desde tu perfil de usuario, activa la opción **"Activar modo paseador"** y completa los campos requeridos, incluyendo la verificación de identidad si es necesario.

**¿Cómo recupero mi contraseña?**  
En la pantalla de inicio de sesión, selecciona "*¿Olvidaste tu contraseña?*" y sigue las instrucciones para restablecerla por correo electrónico.

**¿Puedo usar la app en más de un dispositivo?**  
Sí, puedes acceder desde varios dispositivos siempre que utilices las mismas credenciales de inicio de sesión.

**¿Qué pasa si el paseador no se presenta?**  
Puedes cancelar el paseo desde la app. Si ya realizaste el pago, el saldo se reembolsa automáticamente a tu monedero virtual.

**¿Puedo pasear perros considerados potencialmente peligrosos?**  
Solo si has indicado en tu perfil que cuentas con la certificación oficial para ello.

**¿Cómo califico un paseo?**  
Al finalizar el paseo, se te mostrará un cuadro para valorar el servicio de 1 a 5 estrellas y dejar una reseña. Esta será visible solo para las partes involucradas.

**¿Qué hago si ocurre un incidente durante el paseo?**  
Desde la sección *Detalles del paseo* puedes:

- **Contactar con soporte** usando la opción "*Llámanos*", para asistencia inmediata en casos urgentes.  
- **Llamar directamente al dueño del perro**, si la situación lo requiere.

La seguridad de los usuarios y sus mascotas es siempre nuestra prioridad.


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
