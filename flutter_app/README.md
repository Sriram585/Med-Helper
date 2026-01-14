# Med Helper - Flutter Mobile App

This is a Flutter port of the Med Helper web application. It allows users to access their health dashboard, chat with AI, and analyze lab reports from their mobile device.

## Prerequisites

-   [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
-   Android Studio (with Emulator) or VS Code with Flutter extensions.
-   Python 3.x (for the backend).

## Setup & Run

### 1. Start the Backend server

The Flutter app needs the backend to be running to fetch data.

1.  Open a terminal in the root `Med Helper` directory.
2.  Activate your virtual environment (if you have one, e.g., `venv\Scripts\activate`).
3.  Run the server:
    ```bash
    python main.py
    ```

### 2. Run the Flutter App

1.  Open a new terminal and navigate to the `flutter_app` folder:
    ```bash
    cd flutter_app
    ```
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run the app (select your emulator when prompted or ensure one is running):
    ```bash
    flutter run
    ```

## Notes for Emulator

-   The app is configured to connect to `http://10.0.2.2:8000`, which is the special alias for `localhost` within the Android Emulator.
-   If you are running on an iOS Simulator, you may need to change `baseUrl` in `lib/services/api_service.dart` to `http://127.0.0.1:8000`.
-   If you run on a physical device, change the IP to your computer's local network IP (e.g., `192.168.1.x`).
