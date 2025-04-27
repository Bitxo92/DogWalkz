# DogWalkz 🐾  : App for Effortless Dog Walking! 

## Overview

DogWalkz connects dog owners with professional walkers, offering an intuitive and reliable service for booking, tracking, and managing dog walks. The platform ensures safety, convenience, and ease of use, making it ideal for pet owners who need help caring for their dogs. The project will not only focus on the planning and design stages but will also deliver a fully functional cross-platform mobile application.

The main goal of DogWalkz is to provide a trustworthy, easy-to-use solution for dog owners who need assistance walking their pets. It is aimed at two primary user groups: busy dog owners who may struggle to find time for daily walks and professional or freelance walkers looking to connect with new clients. This service fits perfectly within urban and suburban contexts where pet ownership is high and the demand for pet care services continues to grow.

DogWalkz addresses several key needs, including providing a secure way to book dog walkers, enabling real-time walk tracking for owners, and facilitating easy, protected payments. In addition to solving a clear problem, the app opens strong business opportunities through a commission-based model, optional premium subscriptions for additional benefits, and potential partnerships with pet product companies. These commercial avenues make the platform scalable and sustainable.

Although applications like Rover and Wag! exist, many users find them either complex or limited to larger metropolitan areas. DogWalkz aims to improve on this by delivering a more intuitive experience, ensuring payment transparency, supporting multiple languages, and fostering a reliable community through user reviews and a trusted reputation system.

The primary objectives are to develop a secure, user-friendly mobile platform, manage user profiles for both owners and walkers, offer real-time GPS tracking during walks, and provide a protected wallet system for handling payments. Essential requirements include secure authentication (OAuth), robust backend management (Supabase), intuitive mobile frontend development (Flutter), real-time location services, and multilanguage support to reach a wider international audience.

## Main Features

### 📝 **User Registration & Login**
- **Simple Onboarding**: Users (owners & walkers) can easily register using email, phone, or social media accounts.
- **Secure Authentication**: Login via email/password or linked social media, with password recovery options.

### 👤 **User Profiles**
- **Dog Owner Profiles**: Store personal information and details of registered dogs (name, breed, size, sociability).
- **Walker Profiles**: Includes personal details, experience, and dog size qualifications (small/medium/large) to ensure compatibility with dog types.

### 💰 **Virtual Wallet & Payments**
- **Flexible Payment Methods**: Clients can load funds using credit/debit cards, PayPal, and bank transfers.
- **Payment Holding**: Payments are securely held until the walk is completed, with walkers able to transfer funds to their bank accounts.

### 📍 **Real-time Walk Tracking**
- **Location Tracking**: Clients can track the walker’s real-time location during walks for peace of mind and transparency.
- **Walk Completion**: After each walk, clients receive a notification to rate the service, and payments are processed securely.

### ⭐ **Ratings & Reviews**
- **Reputation System**: Clients and walkers can rate each other, contributing to a trustworthy community.
- **Feedback & Ratings**: Reviews help maintain high-quality service and offer valuable feedback for improvement.

## Technologies

### **Frontend Development**
- **Flutter** </> : A powerful framework for building cross-platform mobile apps for both iOS and Android. Ensures fast and responsive user interfaces, providing a smooth experience for all users.

<img src="https://storage.googleapis.com/cms-storage-bucket/4fd0db61df0567c0f352.png" alt="Flutter Logo" height="100"/>


### **Backend Development**
- **Supabase** ⛃ : An open-source backend-as-a-service (BaaS) providing database storage, authentication, and real-time capabilities. It simplifies backend management, scaling, and security without the need to build from scratch.

<img src="https://raw.githubusercontent.com/supabase/supabase/master/packages/common/assets/images/supabase-logo-wordmark--dark.png" alt="Supabase Logo" height="100"/>


### **Authentication & Security**
- **OAuth** 🔐 : Secure and scalable authentication, allowing for social media logins and token-based session management.
- **JWT Tokens** 🔑 : JSON Web Tokens will be used to manage sessions securely, allowing stateless authentication across multiple platforms and improving scalability.

<img src="https://oauth.net/images/oauth-logo-square.png" alt="OAuth Logo" height="100"/> 


---

### Benefits of This Approach

1. **Ease of Use**: The platform will provide a user-friendly, easy-to-navigate experience, ensuring both dog owners and walkers can quickly manage their accounts and requests.
2. **Security**: With OAuth and JWT-based session handling, the platform ensures user privacy and data protection.
3. **Scalability**: By utilizing **Flutter** and **Supabase**, the platform can easily scale to accommodate more users as the service grows.