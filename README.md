# Proyecto fin de ciclo
**¡Bienvenido a DogWalkz 🐾 — una plataforma diseñada para programar paseos para tus perros de forma fácil y cómoda!**

<p align="center">
  <img src="https://gitlab.com/iesleliadoura/DAM2/alejandro-manuel-patino/-/raw/main/doc/img/DogWalkz-Intro.gif" alt="Dog Walkz Intro" style="width: auto; height: 300px;">
</p>



## Descripción

**DogWalkz** es una aplicación móvil que conecta a dueños de perros con paseadores profesionales de manera segura, sencilla e intuitiva. Ofrece un registro fácil, seguimiento de paseos en tiempo real, un sistema de pagos seguro y una comunidad basada en reseñas para garantizar un servicio de alta calidad. Diseñada para dueños de mascotas ocupados y paseadores profesionales, DogWalkz simplifica el proceso de gestionar paseos de perros de forma segura y transparente.  
Construida con tecnologías modernas como Flutter, Supabase y OAuth, la app es multiplataforma y multilingüe, lo que la hace accesible para una audiencia global.  
DogWalkz no solo resuelve una necesidad real, sino que también abre oportunidades para un negocio escalable a través de comisiones y servicios premium.


## Instalación / Puesta en marcha

### 1. Instalar SDK de Flutter

Primero, debemos instalar Flutter en nuestra máquina.

- **Windows**:
  1. Descarga la última versión estable del SDK de Flutter desde el [sitio web oficial](https://flutter.dev/docs/get-started/install).
  2. Extrae el archivo zip y colócalo en la ubicación deseada (por ejemplo, `C:\src\flutter`).
  3. Agrega Flutter a las variables de entorno del sistema:
      - Busca "Variables de Entorno" en Windows.
      - Edita la variable `Path` y añade la ruta completa al directorio `flutter/bin`.
  4. Ejecuta lo siguiente en una terminal para verificar:
     ```bash
     flutter doctor
     ```

- **macOS**:
  1. Instalar Flutter via Homebrew:
     ```bash
     brew install --cask flutter
     ```
    O realiza la descarga manualmente desde [Flutter downloads](https://flutter.dev/docs/get-started/install/macos).

  2. Verificar Instalación:
     ```bash
     flutter doctor
     ```

- **Linux**:
  1. Descarga la última versión estable del SDK de Flutter desde [Flutter downloads](https://flutter.dev/docs/get-started/install/linux).
  2. Extrae el fichero tar:
     ```bash
     tar xf flutter_linux_*.tar.xz
     ```
  3. Añade Flutter a la variable `Path`:
     ```bash
     export PATH="$PATH:`pwd`/flutter/bin"
     ```
  4. Verificar la instalación:
     ```bash
     flutter doctor
     ```

---

### 2. Instalar requisitos adicionales

- Instala un editor como **VS Code** o **Android Studio**.
- Para el desarrollo móvil:
  - Instala Android Studio y configura el SDK de Android.
  - Para el desarrollo en iOS (solo en macOS): Instala Xcode.
- Instala los complementos de Flutter y Dart en tu IDE.
- Acepta las licencias de Android ejecutando:
  ```bash
  flutter doctor --android-licenses

  ```
---
### 3. Clonar el Repositorio Dogwalkz
Se puede clonar por **HTTPS** o **SSH**:

- **Via HTTPS**:

    ``` bash
    git clone https://gitlab.com/iesleliadoura/DAM2/alejandro-manuel-patino Dogwalkz
    cd Dogwalkz
    ```
- **Via SSH**:

    ``` bash
    git clone git@gitlab.com:iesleliadoura/DAM2/alejandro-manuel-patino Dogwalkz
    cd Dogwalkz
    ```
---

### 4. Obtener dependencias
Instala todos los paquetes requeridos de Flutter:
``` bash
flutter pub get
```
---
### 5. Ejecutar la aplicación
Para ejecutar la aplicación en un dispositivo o emulador:

``` bash
flutter run
```
---
### 6. Verificar la configuración
Finalmente, verifica que todo esté instalado correctamente:
``` bash
flutter doctor
```
Resuelve cualquier problema pendiente si es necesario.

> [!TIP]
> Si surgen algún problema con algúna libreria tras clonar el repositorio,ejecute el siguiente comando en la terminal:
 > ``` bash
 > flutter build
 > ```




## Uso
DogWalkz está diseñado para ser intuitivo y sencillo tanto para dueños de perros como para paseadores profesionales.

- **Dueños de perros**:
  1. Regístrate o inicia sesión en la aplicación.
  2. Crea tu perfil de usuario.
  3. Agrega la información de tu perro (nombre, raza, tamaño, sociabilidad).
  4. Reserva un paseo, sigue el recorrido de tu perro en tiempo real y paga de forma segura al finalizar.
  5. Califica y deja una reseña del paseador después del paseo.

- **Paseadores de perros**:
  1. Regístrate o inicia sesión en la aplicación.
  2. Configura tu perfil de paseador activando la opción correspondiente en tu perfil de usuario y completando los campos requeridos: experiencia, tamaños de perros preferidos, identificación...
  3. Acepta solicitudes de paseo de los dueños de perros.
  4. Inicia y completa el paseo mientras eres rastreado para mayor transparencia.
  5. Recibe el pago una vez que el paseo sea completado y revisado.

> [!NOTE] 
> Asegúrate de tener fondos en tu monedero virtual y de que tu perfil esté debidamente completado antes de reservar o aceptar paseos.


## Sobre el autor

Mi nombre es **Alejandro Patiño**, soy un desarrollador junior especializado en **desarrollo móvil multiplataforma**.  
Mi principal fortaleza es crear aplicaciones rápidas, escalables e intuitivas utilizando **Flutter Framework**, lo que me permite desarrollar aplicaciones nativas, tanto para Android como iOS desde una única base de código.

Actualmente, estoy trabajando como alumno en prácticas en [QBitDynamics](https://qbitdynamics.com/), donde sigo ampliando mis conocimientos en proyectos móviles.  
Tengo un fuerte enfoque en crear código limpio y bien documentado, priorizando el desarrollo de diseños UI/UX intuitivos para garantizar una experiencia fluida y atractiva.

Elegí desarrollar **DogWalkz** porque combina mi amor por la programación con la solución de problemas reales cotidianos. Los servicios para mascotas están creciendo rápidamente, y creo que esta aplicación ofrece una solución valiosa y escalable en un mercado de alta demanda.

Actualmente vivo en **Ribeira, España**, y estoy abierto a nuevas oportunidades y colaboraciones.
 


Puedes contactarme en:

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/alejandro-m-pati%C3%B1o-garcia-41b000309/)
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:alexpatino1992@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Bitxo92)

---

## Licencia

Este software es **propietario**. Todos los derechos están reservados por el autor. No se permite utilizar, modificar, distribuir ni copiar el software sin el permiso explícito del autor.

Para más detalles, consulta el archivo [LICENSE](LICENSE).



## Índice

1. Anteproyecto
    * 1.1. [Idea](doc/templates/1_idea.md)
    * 1.2. [Necesidades](doc/templates/2_necesidades.md)
2. [Análisis](doc/templates/3_analise.md)
3. [Planificación](doc/templates/4_planificacion.md)
4. [Diseño](doc/templates/5_deseño.md)
5. Implantación
    * 5.1 [Implementación](doc/templates/6_implementacion.md)
    * 5.2 [Producción](doc/templates/7_producion.md)



## Links


### Flutter

- [ Instalación de Flutter](https://flutter.dev/docs/get-started/install) — Guía oficial para instalar Flutter en Windows, macOS y Linux.
- [ Documentación de Flutter](https://docs.flutter.dev/) — Manual oficial para aprender Flutter y consultar referencias.
- [ Pub.dev](https://pub.dev/) — Repositorio oficial de paquetes para Flutter y Dart.

### Supabase

- [ Supabase Docs](https://supabase.com/docs) — Aprende a usar Supabase como backend, autenticación y base de datos en tiempo real.

### Entornos de Desarrollo

- [ Visual Studio Code](https://code.visualstudio.com/) — Editor de código multiplataforma recomendado.
- [ Plugins de Flutter y Dart para VS Code](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) — Extensiones necesarias para desarrollar con Flutter.
- [ Android Studio](https://developer.android.com/studio) — IDE completo para el desarrollo y emulación de apps Android.
- [ Instalar SDK de Android](https://developer.android.com/studio/install) — Guía para instalar y configurar el SDK de Android.

### Desarrollo iOS (solo macOS)

- [ Instalación de Xcode](https://developer.apple.com/xcode/) — Requisito esencial para compilar y ejecutar apps en dispositivos Apple.



### Repositorio del Proyecto

- [ DogWalkz en GitLab](https://gitlab.com/iesleliadoura/DAM2/alejandro-manuel-patino/-/tree/main/src/dogwalkz) — Accede al código fuente, documentación y recursos del proyecto.

---