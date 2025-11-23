# Requirements Document

## Introduction

The Local Vocal Remover & Music Player is a mobile application (iOS & Android) that functions as a standard music player with AI-powered vocal removal capabilities. The system processes audio files stored locally on the user's device using on-device inference, implementing a "Convert-then-Play" architecture with intelligent background queue processing to ensure seamless playback without real-time streaming overhead.

## Glossary

- **System**: The Local Vocal Remover & Music Player mobile application
- **User**: The person operating the mobile application
- **Audio File**: A digital music file in MP3, WAV, M4A, or FLAC format
- **Instrumental Stem**: The audio output containing only the accompaniment (music without vocals)
- **Queue**: The ordered list of songs to be played
- **Cache**: Local storage area for processed instrumental files
- **DRM-Protected File**: Audio file encrypted with Digital Rights Management technology
- **Background Processing**: AI vocal removal executed in a separate thread while other operations continue
- **Look-Ahead Processing**: Pre-processing the next queued song while the current song plays
- **LRU Policy**: Least Recently Used eviction strategy for cache management
- **AI Model**: The quantized deep learning model (Spleeter or Demucs) for vocal separation

## Requirements

### Requirement 1: Local Audio File Import

**User Story:** As a user, I want to import audio files from my device's local storage, so that I can play them with vocal removal.

#### Acceptance Criteria

1. WHEN the User selects the import function, THE System SHALL display audio files from the device's local file system
2. THE System SHALL support MP3, WAV, M4A, and FLAC file formats
3. WHEN the System encounters an unsupported file type, THE System SHALL exclude that file from the displayed list
4. WHEN the System encounters a DRM-Protected File, THE System SHALL mark that file as unavailable for processing
5. WHERE an Audio File contains ID3 metadata tags, THE System SHALL extract and display the Artist, Title, and Album Art information

### Requirement 2: AI-Based Vocal Removal Processing

**User Story:** As a user, I want the app to automatically remove vocals from my songs using on-device AI, so that I can listen to instrumental versions without requiring an internet connection.

#### Acceptance Criteria

1. THE System SHALL execute vocal removal using a quantized deep learning model (Spleeter or Demucs) on the device
2. WHEN the System processes an Audio File, THE System SHALL generate an Instrumental Stem in WAV format
3. WHEN the System processes a 3-minute Audio File on a flagship device (iPhone 13+ or Pixel 6+), THE System SHALL complete processing within 30 seconds
4. THE System SHALL perform audio resampling to 44.1kHz before AI Model inference
5. THE System SHALL apply Short-Time Fourier Transform (STFT) to generate spectrograms for model input

### Requirement 3: Smart Queue and Background Processing

**User Story:** As a user, I want the app to automatically process upcoming songs in the background, so that I experience seamless transitions between tracks without waiting.

#### Acceptance Criteria

1. WHEN a song is selected for playback, THE System SHALL check the Cache for an existing Instrumental Stem
2. IF an Instrumental Stem exists in the Cache, THEN THE System SHALL begin playback immediately
3. IF an Instrumental Stem does not exist in the Cache, THEN THE System SHALL display a "Processing" indicator, generate the Instrumental Stem, and begin playback upon completion
4. WHILE a song is playing, THE System SHALL identify the next Audio File in the Queue
5. WHILE a song is playing, THE System SHALL initiate Background Processing for the next Audio File in the Queue
6. WHEN the User skips to a different song, THE System SHALL cancel the current Background Processing task and prioritize the newly selected song
7. WHEN Background Processing completes for a queued song, THE System SHALL store the Instrumental Stem in the Cache

### Requirement 4: Standard Playback Controls

**User Story:** As a user, I want standard music player controls, so that I can manage playback like any other music app.

#### Acceptance Criteria

1. THE System SHALL provide a play control to start audio playback
2. THE System SHALL provide a pause control to temporarily stop audio playback
3. THE System SHALL provide a skip control to advance to the next song in the Queue
4. THE System SHALL provide a seek control to navigate to different positions within the current song
5. THE System SHALL provide a loop control to repeat the current song or Queue

### Requirement 5: Intelligent Cache Management

**User Story:** As a user, I want the app to manage storage automatically, so that processed songs are saved for quick access without filling up my device.

#### Acceptance Criteria

1. THE System SHALL store processed Instrumental Stems in the application's private cache directory
2. THE System SHALL implement an LRU Policy for cache eviction
3. WHEN available storage space falls below the threshold, THE System SHALL delete Instrumental Stems that have not been played in 30 days
4. THE System SHALL enforce a maximum cache size of 1GB by default
5. WHEN the Cache exceeds the maximum size, THE System SHALL remove the least recently used Instrumental Stems until the cache size is within the limit

### Requirement 6: DRM Protection Handling

**User Story:** As a user, I want clear indication when files cannot be processed due to DRM protection, so that I understand why certain files are unavailable.

#### Acceptance Criteria

1. WHEN the System detects a DRM-Protected File, THE System SHALL identify it using platform-specific APIs (AVAsset on iOS or MediaExtractor on Android)
2. WHEN the System detects a DRM-Protected File, THE System SHALL display the file with a visual indicator showing it is unavailable for processing
3. IF the User attempts to play a DRM-Protected File, THEN THE System SHALL display an error message explaining that DRM-protected files cannot be processed

### Requirement 7: Battery and Performance Optimization

**User Story:** As a user, I want the app to manage device resources responsibly, so that my battery life and device performance are not severely impacted.

#### Acceptance Criteria

1. WHERE a Battery Saver mode is enabled, THE System SHALL disable Look-Ahead Processing when device battery level is below 20 percent
2. WHILE processing multiple songs in the background, THE System SHALL introduce a 1-second pause between consecutive processing tasks
3. WHEN Background Processing is active, THE System SHALL utilize platform-specific optimization APIs (CoreML with Apple Neural Engine on iOS, TensorFlow Lite with NNAPI Delegate on Android)

### Requirement 8: User Interface Feedback

**User Story:** As a user, I want clear visual feedback during processing, so that I know the app is working and understand the current state.

#### Acceptance Criteria

1. WHEN the System is processing an Audio File for the first time, THE System SHALL display the album art with a circular progress indicator overlay
2. WHEN the System is processing an Audio File for the first time, THE System SHALL display the text "Removing vocals..."
3. WHEN processing completes and playback begins, THE System SHALL remove the progress indicator
4. WHILE audio is playing, THE System SHALL provide visual feedback such as animated album art or an audio visualizer
5. WHEN Background Processing is occurring for the next song, THE System SHALL not display any intrusive UI elements that interrupt the current playback experience
