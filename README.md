# 🎥 Video Converter Pro

**Video Converter Pro** is a modern, feature-rich video conversion application built with Flutter. It offers a premium, immersive experience with a glassmorphism-inspired UI and high-performance processing powered by FFmpeg.

[![Flutter](https://img.shields.io/badge/Flutter-v3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-v4.1-0078D7?logo=ffmpeg&logoColor=white)](https://ffmpeg.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Key Features

- 🔄 **Versatile Video Conversion**: Effortlessly convert between multiple formats (MP4, MKV, AVI, MOV, WEBM, FLV).
- 🎵 **Audio Extraction**: High-quality video-to-audio extraction (MP3, AAC, WAV, M4A).
- ⚙️ **Custom Presets**: Optimized resolutions ranging from 480p to 4K.
- 📉 **Bitrate & FPS Control**: Precise control over output quality with manual bitrate and frame rate settings (24, 30, 60 FPS).
- ⚡ **Batch Conversion**: Process multiple files simultaneously to save time.
- 🕒 **Conversion History**: Track and manage your previous conversion tasks.
- 🎨 **Premium UI**: Stunning dark AMOLED theme with glassmorphism effects and smooth micro-animations.
- 📳 **Haptic Feedback**: Enhanced user experience with meaningful haptic touches.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **Core Processing**: [ffmpeg_kit_flutter_new](https://pub.dev/packages/ffmpeg_kit_flutter_new)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Animations**: [flutter_animate](https://pub.dev/packages/flutter_animate)
- **Design System**: Material Design 3 with custom Glassmorphism components.

## 📁 Project Structure

```text
lib/
├── core/           # Theme, constants, and global configurations
├── data/           # Models and repositories (data layer)
├── presentation/   # UI components, screens, and providers (presentation layer)
├── services/       # FFmpeg, File, and Haptic services (infrastructure layer)
└── main.dart       # App entry point
```

## 🚀 Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/video_converter_pro.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Run the app**:
   ```bash
   flutter run
   ```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

