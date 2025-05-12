# DISEÑO

## Diseño del proyecto

### Diagrama de Clases.
El diagrama de clases presenta la estructura completa de la applicación `Dogwalkz`, donde mostramos su arquitectura, la cual sigue un **patrón de capas modificado** adaptado a Flutter, combinando elementos de *Clean Architecture* con el ecosistema específico del framework.



Esta arquitectura está dividida en tres capas principales:

- En la **Capa de Presentación (UI/UX)**, se implementa utilizando los widgets de Flutter como `StatefulWidget` y `StatelessWidget` donde organizamos la interfaz en páginas(p.ej: `HomePage` y `DogsPage`), con sus respectivos estados gestionados en clases(p.ej: `_HomePageState`), utilizando métodos para la gestión del estado nativo(`setState`) además de su ciclo de vida(`initState` y `dispose`).

- La **Capa de Dominio** contiene los modelos de datos esenciales, como `Dog`, `Walker` y `Walk`, las cuales funcionan como DTOs(**Data Transfer Objects**), simples contenedores de datos que facilitan la transferencia de información entre las diferentes capas. 

- En la **Capa de Datos**, se encuentran los repositorios como `DogsRepository` y `WalkRepository`, que gestionan la conexión y la comunicación con Supabase, además de los servicios como `NotificationService` que también forman parte de esta capa,siendo la encargada de la lógica para transformar los datos entre el formato necesario en la aplicación y el que se recibe desde la base de datos.





Finalmente, la **Comunicación con el Backend** se maneja a través de `SupabaseClient`, que actúa como un singleton, centralizado en `SupabaseManager` donde las operaciones con la base de datos se realizan de forma asíncrona. Además, se implementa un manejo de errores mediante excepciones personalizadas.


![Diagrama de clases](/doc/img/dogwalkz_UML_ClassDiagram.png)

### Casos de uso.


El presente **diagrama de casos de uso** describe las principales interacciones entre los **usuarios** y el **sistema** de la aplicación **DogWalkz**, enfocándose en los procesos clave relacionados, como son la **autenticación de usuarios** o la **gestión de los paseos**.

En este contexto, se identifican dos **actores principales**, cada uno con diferentes necesidades y formas de interacción con el sistema:

- **Cliente (dueño del perro):**
  - Registrarse y autenticarse en la aplicación.
  - Solicitar paseos para su perro.
  - Consultar el historial de paseos.
  - Cancelar paseos programados.
  - Marcar paseos como completados.
  - Valorar al paseador tras el servicio.


- **Paseador:**
  - Registrarse y autenticarse en la aplicación.
  - Ver solicitudes de paseo disponibles.
  - Aceptar o rechazar paseos.
  - Iniciar el paseo
  - Cancelar paseos programados.
  - Gestionar su agenda de paseos.


Este tipo de diagrama permite representar de forma clara y estructurada los **requerimientos funcionales** del sistema desde la perspectiva del **tipo de usuario**, facilitando la comprensión de los flujos de interacción y apoyando el diseño centrado en el usuario.



![Diagrama de casos de uso](/doc/img/dogwalkz_UseCaseDiagram.png)

### Deseño de interfaces de usuarios.
#### Login/Register.
![Login-Register Wireframe](/doc/img/Login_Register_Wireframe.png)

### Diagrama de Base de Datos.
La arquitectura de base de datos del sistema `DogWalkz` ha sido diseñada para sustentar una plataforma integral de gestión de servicios de paseo de perros, con un enfoque en la **escalabilidad**, la **integridad de los datos** y la **trazabilidad** de las operaciones. 
El modelo relacional propuesto establece una estructura coherente y normalizada que facilita la interacción entre los distintos actores del sistema.

La entidad central del modelo es la tabla `users`, desde la cual se derivan múltiples relaciones hacia otras entidades clave como `dogs`, `walker_profiles`, `wallets`, y `walks`. Esta estructura permite representar tanto a clientes como a paseadores dentro de un mismo esquema, diferenciándolos mediante atributos y relaciones específicas.

El modelo contempla buenas prácticas de diseño como el uso de claves primarias UUID para garantizar la unicidad, timestamps automáticos para auditoría, y campos con valores por defecto y restricciones de validación, todo ello orientado a garantizar la consistencia, seguridad y eficiencia de la plataforma en entornos productivos de alta demanda.

![Diagrama de base de datos](/doc/img/dogwalkz_DBDiagram.png)


### Diagrama de despliegue.
DogWalkz es una app multiplataforma creada con **Flutter**, apoyandose de **Supabase** para el backend. Esta arquitectura permite que la app funcione sin necesidad de infraestructura personalizada, delegando tareas críticas como autenticación, persistencia de datos y almacenamiento de archivos a servicios gestionados por Supabase.

El cliente móvil se ejecuta en dispositivos Android e iOS, mientras que la comunicación con el backend se realiza a través de una API RESTful segura, generada automáticamente por Supabase a partir del esquema de base de datos PostgreSQL. Esta interacción se refuerza con autenticación basada en tokens **JWT** y **RLS** (políticas de seguridad a nivel de fila), lo que garantiza el acceso controlado a los datos.



![Diagrama de despliegue](/doc/img/dogwalkz_DeploymentDiagram.png)

### Outros diagramas, esquemas ou documentacion (seguridade, redundancia, expliacións, configuracións...)

## Calidade

> *TODO*: Identifica os aspectos que compre controlar para garantir a calidade do proxecto, determinando os procedementos de actuación ou execución das actividades, establecendo un sistema para garantir o cumprimento das condicións do proxecto (requisitos, funcionalidades...)