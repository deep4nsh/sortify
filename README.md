# Sortify 📸✨

**Sortify** is an intelligent gallery application built with Flutter that automatically organizes your photos using on-device Machine Learning and Cloud AI.

## 🚀 Features

### 🧠 Smart Categorization
-   **On-Device ML**: Instantly categorizes your photos (e.g., "Cat", "Food", "Beach") using Google ML Kit.
-   **Privacy-Focused**: Most processing happens right on your phone.
-   **AI Fallback**: If the local model is unsure, Sortify seamlessly uses the **Gemini API** to provide a precise label (e.g., "Espresso" instead of "Unknown").

### 👤 Facial Recognition & Clustering
-   **Facial Recognition**: Automatically detects faces in your gallery and groups them together.
-   **Face Clustering**: Uses **MobileFaceNet** (TFLite) to recognize unique faces and cluster them into "People".
-   **Custom Naming**: Tap on a person to name them (e.g., "Me", "Bestie").

### 🎨 Premium UI
-   **Dark Mode**: Sleek, battery-saving dark interface.
-   **Smooth Animations**: Polished transitions and interactions.
-   **Fast Performance**: Optimized for handling large galleries.

## 🛠️ Setup & Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/sortify.git
    cd sortify
    ```

2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Configure AI (Gemini)**:
    -   Get a free API Key from [Google AI Studio](https://aistudio.google.com/).
    -   Open `lib/services/ai_service.dart`.
    -   Replace `YOUR_API_KEY` with your actual key:
        ```dart
        static const String _apiKey = 'AIzaSy...';
        ```

4.  **Assets**:
    -   Ensure `assets/MobileFaceNet.tflite` is present (it should be downloaded automatically or included in the repo).

5.  **Run the App**:
    ```bash
    flutter run
    ```

## 📱 Usage

-   **Home Screen**: View your automatically sorted photos. Use the chips at the top to filter by category.
-   **Search**: Type to find specific objects (e.g., "Dog").
-   **People**: Tap the **People Icon** (👥) in the top-right to scan your gallery for faces.
    -   *Note*: The first scan might take some time as it analyzes every photo.
-   **Albums**: View standard folder-based albums.

## 🏗️ Tech Stack

-   **Framework**: Flutter
-   **ML (On-Device)**: Google ML Kit (Image Labeling, Face Detection)
-   **ML (Embeddings)**: TensorFlow Lite (`tflite_flutter`) with MobileFaceNet
-   **AI (Cloud)**: Google Gemini API (`google_generative_ai`)
-   **State Management**: `setState` (Simple & Effective)
-   **Image Handling**: `photo_manager`, `image` package

## 📄 License

This project is licensed under the MIT License.
