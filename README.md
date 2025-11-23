# Lyricless

A cross-platform local vocal remover application built with Flutter. Lyricless uses AI-powered vocal separation to create instrumental versions of your audio files, with intelligent caching and look-ahead processing for seamless playback.

## Features

- **AI-Powered Vocal Removal**: Uses TensorFlow Lite models to separate vocals from instrumentals
- **Cross-Platform**: Supports iOS, Android, and Web
- **Smart Caching**: LRU cache with automatic eviction to manage storage efficiently
- **Look-Ahead Processing**: Processes next track in the background for seamless transitions
- **Battery Optimization**: Intelligent battery saver mode for mobile devices
- **DRM Detection**: Automatically detects and filters DRM-protected files
- **Rich Metadata**: Extracts and displays album artwork, artist, and track information

## Architecture

### Core Components

- **Library Manager**: Handles file import, metadata extraction, and DRM detection
- **Audio Processor**: TensorFlow Lite-based vocal removal with progress tracking
- **Cache Manager**: LRU-based cache with 1GB limit and 30-day expiration
- **Queue Manager**: Playback queue with look-ahead processing and shuffle/repeat
- **Playback Manager**: Audio playback with just_audio integration
- **Battery Service**: Battery-aware processing for mobile platforms

### Data Models

- `AudioFile`: Represents an audio file with metadata
- `CacheEntry`: Tracks cached processed audio files
- `ProcessingTask`: Manages vocal removal task state
- `VocalRemoverError`: Comprehensive error handling

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or later
- For iOS: Xcode 14+ and iOS 12.0+
- For Android: Android Studio and API 26+
- For Web: Modern browser with WebGL support

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/lyricless.git
cd lyricless
```

2. Install dependencies:
```bash
flutter pub get
```

3. Prepare the AI model:
```bash
cd python
python convert_model.py
```

4. Run the app:
```bash
# For mobile
flutter run

# For web
flutter run -d chrome
```

## Model Preparation

The AI model needs to be converted to TensorFlow Lite format for mobile and TensorFlow.js for web:

1. Set up Python environment:
```bash
cd python
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. Run the conversion script:
```bash
python convert_model.py
```

This will:
- Download the pre-trained Spleeter or Demucs model
- Convert to TFLite with quantization
- Convert to TensorFlow.js
- Place models in `assets/models/`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── audio_file.dart
│   ├── cache_entry.dart
│   ├── processing_task.dart
│   └── vocal_remover_error.dart
├── managers/                 # Business logic
│   ├── library_manager.dart
│   ├── audio_processor.dart
│   ├── cache_manager.dart
│   ├── queue_manager.dart
│   └── playback_manager.dart
├── services/                 # Platform services
│   └── battery_service.dart
└── ui/                      # User interface
    ├── screens/
    └── widgets/

test/
├── unit/                    # Unit tests
└── widget/                  # Widget tests
```

## Testing

Run unit tests:
```bash
flutter test
```

Run widget tests:
```bash
flutter test test/widget
```

## Platform-Specific Notes

### iOS
- Uses Metal delegate for GPU acceleration
- Requires iOS 12.0 or later
- Audio session management for background playback

### Android
- Uses NNAPI delegate for GPU acceleration
- Requires API level 26 or later
- Foreground service for background processing

### Web
- Uses TensorFlow.js with WebGL backend
- IndexedDB for cache storage
- Web Workers for background processing
- Limited to browser storage quotas

## Performance

- Processing time: ~10-30 seconds per 3-minute song (varies by device)
- Cache storage: 1GB max with LRU eviction
- Look-ahead processing ensures no waiting between tracks
- GPU acceleration on supported platforms

## Privacy

- All processing happens locally on device
- No data is sent to external servers
- No telemetry or analytics
- No PII collection

## Supported Audio Formats

- MP3
- WAV
- M4A
- FLAC

## Known Limitations

- DRM-protected files cannot be processed
- Web version limited by browser storage quotas
- Model size: ~50MB
- Requires decent CPU/GPU for real-time processing

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- TensorFlow Lite for mobile ML inference
- Spleeter/Demucs for the base vocal separation models
- just_audio for audio playback
- Flutter team for the amazing framework
