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
l presente **diagrama de casos de uso** describe las principales interacciones entre los **usuarios** y el **sistema** de la aplicación **DogWalkz**, enfocándose en los procesos clave relacionados, como son la **autenticación de usuarios** o la **gestión de los paseos**.

Este tipo de diagrama permite representar de forma clara y estructurada los **requerimientos funcionales** del sistema desde la perspectiva del **tipo de usuario**.


![Diagrama de casos de uso](/doc/img/dogwalkz_UseCaseDiagram.png)

### Deseño de interfaces de usuarios [mockups ou diagramas...].

### Diseño de interfaces software e hardware (se aplica)

### Diagrama de Base de Datos.

### Diagrama de compoñentes software que constitúen o produto e de despregue.

### Diagrama de despregamento

### Outros diagramas, esquemas ou documentacion (seguridade, redundancia, expliacións, configuracións...)

## Calidade

> *TODO*: Identifica os aspectos que compre controlar para garantir a calidade do proxecto, determinando os procedementos de actuación ou execución das actividades, establecendo un sistema para garantir o cumprimento das condicións do proxecto (requisitos, funcionalidades...)