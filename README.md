# Proyecto fin de ciclo

> *TODO*: Este documento será la "*página de aterrizaje*" de tu proyecto. Será lo primero que vean los que se interesen por él. Cuida su redacción con todo tu mimo. Elimina posteriormente todas las líneas "*TODO*" cuando creas finalizada su redacción.
> Puedes acompañar a la redacción de este fichero con imágenes o gifs, pero no abuses de ellos.

## Descripción

**DogWalkz** is a mobile application that connects dog owners with professional dog walkers in a secure, simple, and intuitive way. It offers easy registration, real-time walk tracking, a secure payment system, and a review-based community to ensure high service quality. Designed for busy pet owners and professional walkers, DogWalkz streamlines the process of managing dog walks safely and transparently.  
Built with modern technologies like Flutter, Supabase, and OAuth, the app is cross-platform and multilingual, making it accessible to a global audience.  
DogWalkz doesn’t just solve a real need, it also opens opportunities for a scalable business through commissions and premium services.

## Instalación / Puesta en marcha

### 1. Install Flutter SDK

First, you need to install Flutter on your machine.

- **Windows**:
  1. Download the latest stable Flutter SDK from the [official website](https://flutter.dev/docs/get-started/install).
  2. Extract the zip file and place it in a desired location (e.g., `C:\src\flutter`).
  3. Add Flutter to your system environment variables:
     - Search "Environment Variables" in Windows.
     - Edit the `Path` variable and add the full path to the `flutter/bin` directory.
  4. Run the following in a terminal to verify:
     ```bash
     flutter doctor
     ```

- **macOS**:
  1. Install Flutter via Homebrew:
     ```bash
     brew install --cask flutter
     ```
     Or download manually from [Flutter downloads](https://flutter.dev/docs/get-started/install/macos).

  2. Verify installation:
     ```bash
     flutter doctor
     ```

- **Linux**:
  1. Download the latest Flutter SDK from [Flutter downloads](https://flutter.dev/docs/get-started/install/linux).
  2. Extract the tar file:
     ```bash
     tar xf flutter_linux_*.tar.xz
     ```
  3. Add Flutter to your PATH:
     ```bash
     export PATH="$PATH:`pwd`/flutter/bin"
     ```
  4. Verify installation:
     ```bash
     flutter doctor
     ```

---

### 2. Install Additional Requirements

- Install an editor like **VS Code** or **Android Studio**.
- For mobile development:
  - Install Android Studio and set up the Android SDK.
  - For iOS development (macOS only): Install Xcode.
- Install the Flutter and Dart plugins in your IDE.
- Accept Android licenses by running:
  ```bash
  flutter doctor --android-licenses

  ```
---
### 3. Clone the DogWalkz Repository
You can clone the project using **HTTPS** or **SSH**:

- **Using HTTPS**:

    ``` bash
    git clone https://gitlab.com/iesleliadoura/DAM2/alejandro-manuel-patino Dogwalkz
    cd Dogwalkz
    ```
- **Using SSH**:

    ``` bash
    git clone git@gitlab.com:iesleliadoura/DAM2/alejandro-manuel-patino Dogwalkz
    cd Dogwalkz
    ```
---

### 4. Get Dependencies
Install all the required Flutter packages:
``` bash
flutter pub get
```
---
### 5. Run the app
To run the app on a device or emulator:

``` bash
flutter run
```
---
### 6. Verify Setup
Finally, check that everything is installed correctly:
``` bash
flutter doctor
```
Resolve any pending issues if needed.


## Uso
DogWalkz is designed to be intuitive and simple for both dog owners and professional dog walkers.

- **Dog Owners**:
  1. Register or log in to the app.
  2. Create a user profile 
  3. Add your dog's information (name, breed, size, sociability).
  4. Book a walk, track your dog’s walk in real-time, and pay securely after completion.
  5. Rate and review the walker after the walk.

- **Dog Walkers**:
  1. Register or log in to the app.
  2. Set up your walker profile by activating the corresponding option in your user profile and adding the required fields: experience, preferred dog sizes, ID...
  3. Accept walk requests from dog owners.
  4. Start and complete the walk while being tracked for transparency.
  5. Receive payment once the walk is completed and reviewed.

*Note*: Make sure you have funds in your virtual wallet and your profile properly completed before booking or accepting walks.

## Sobre el autor

My name is **Alejandro Patiño**, a passionate junior developer specializing in **multiplatform mobile development**.  
My main strength is creating fast, scalable, and intuitive apps using **Flutter Framework**, which enables me to develop native apps for both Android and iOS from a single codebase.

Currently, I am working as an intern at [QBitDynamics](https://qbitdynamics.com/), where I continue expanding my knowledge in real-world mobile projects.  
I have a strong focus on creating clean well documented code, prioritizing the development of intuitive, user-centric UI/UX designs to ensure a seamless and engaging experience.

I chose to develop **DogWalkz** because it combines my love for coding with solving real everyday problems. Pet services are growing rapidly, and I believe this app offers a valuable, scalable solution in a market with high demand.

I am currently based in **Ribeira, Spain**, and open to new opportunities and collaborations.  


You can contact me at:

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/alejandro-m-pati%C3%B1o-garcia-41b000309/)
[![Gmail](https://img.shields.io/badge/Gmail-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:alexpatino1992@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Bitxo92)

---

## Licencia

This software is **proprietary**. All rights are reserved by the author. You may not use, modify, distribute, or copy the software without explicit permission from the author.

For further details, please refer to the [LICENSE](LICENSE) file.


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

> *TODO*: Enlaces externos y descripciones de estos enlaces que creas conveniente indicar aquí. Generalmente ya van a estar integrados con tu documentación, pero si requieres realizar un listado de ellos, este es el lugar.