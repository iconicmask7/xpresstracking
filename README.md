# XpressTrack 🚚

XpressTrack is a professional, high-performance delivery partner tracking application built with Flutter. It provides real-time location check-ins, tracking history, and administrative dashboards for tracking delivery personnel. 

Designed with top-tier UI/UX principles, the application features dynamic glassmorphism aesthetics, fluid micro-animations, and robust error handling.

---

## 📸 Core Features

- **Role-Based Access Control**: Distinct flows for Admin and Delivery Partners.
- **Real-Time GPS Check-ins**: Delivery partners can check in with their exact GPS coordinates, add notes, and capture optional on-site photos.
- **Admin Dashboard**: Real-time overview of active routes, completed tasks, and delivery personnel on the field.
- **Interactive Maps**: Full OpenStreetMap integration allowing admins to view the exact location of check-ins and delivery tracking history.
- **Tracking History**: Grouped historical data for past delivery sessions.
- **Robust Error Handling**: Deeply integrated reactive error-catching providing user-friendly feedback across all screens.

---

## 🛠️ Tech Stack

This project is built using modern architecture and best practices for scalability and performance.

### **Core**
- **Framework**: [Flutter](https://flutter.dev/) (Dart SDK ^3.9.2)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) for deep linking and declarative navigation.

### **Backend as a Service (BaaS)**
- **Authentication**: Firebase Auth (Email & Password with robust client-side validation)
- **Database**: Cloud Firestore (Real-time syncing and structured NoSQL data)
- **Storage**: Firebase Storage (For check-in images)

### **Location & Mapping**
- **Maps**: `flutter_map` (OpenStreetMap integration) & `latlong2`
- **Geolocation**: `geolocator` and `location` for precise GPS tracking

### **UI & Aesthetics**
- **Animations**: `flutter_animate` (Fluid micro-animations & transitions)
- **Typography & Styling**: `google_fonts` (Outfit & Inter), `flutter_screenutil` (Responsive sizing)
- **Placeholders**: `shimmer` (Loading states)

---

## 🚀 Installation & Setup

Follow these steps to run the project locally on your machine.

### **1. Prerequisites**
- Flutter SDK installed ([Install Guide](https://docs.flutter.dev/get-started/install))
- Android Studio / Xcode for emulators
- A Firebase Project ([Setup Guide](https://firebase.google.com/docs/flutter/setup))

### **2. Clone the Repository**
```bash
git clone https://github.com/iconicmask7/xpresstracking
cd xpresstrack
```

### **3. Install Dependencies**
Fetch all the required Dart packages:
```bash
flutter pub get
```

### **4. Firebase Configuration**
Since this project uses Firebase, you need to configure your own Firebase project. 
1. Create a project in the Firebase Console.
2. Enable **Authentication** (Email/Password), **Firestore Database**, and **Storage**.
3. Use the FlutterFire CLI to configure your app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. This will automatically generate the `firebase_options.dart` file in your `lib/` directory.

### **5. Code Generation (Riverpod)**
This project uses Riverpod Generator for type-safe state management. Generate the `.g.dart` files:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
*Note: If you make changes to any ViewModels or Providers, run this command again or use the `watch` flag.*

### **6. Run the App**
Connect a physical device or start an emulator, then run:
```bash
flutter run
```

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── router/          # GoRouter configurations and paths
│   ├── theme/           # Global colors, typography, and theme definitions
│   └── utils/           # Helper classes (ErrorHandler, LocationHandler, UI widgets)
├── features/
│   ├── admin/           # Admin Dashboard, Partner Details, and Live Route Maps
│   ├── auth/            # Login, Register, and unified validation logic
│   ├── delivery/        # Delivery Check-in, tracking status, and drawer
│   └── shared/          # Shared views (Checkpoint details, History screens)
├── models/              # Immutable data models (User, Checkpoint)
├── services/            # Firebase integration services (Auth, Firestore, Storage)
└── main.dart            # Entry point of the application
```

---

## 🛡️ Best Practices Implemented

- **Reactive UI**: Deeply integrated Riverpod `StreamProvider` and `AsyncNotifier` to ensure the UI is strictly a reflection of the state.
- **Fail-Safe Architecture**: Universal error listening (`ref.listen`) ensuring that no server crash or network failure breaks the app silently.
- **Separation of Concerns**: Strict MVVM (Model-View-ViewModel) architecture isolating business logic (ViewModels) from UI presentation (Views) and data fetching (Services). 

---

Developed with ❤️ using Flutter.
