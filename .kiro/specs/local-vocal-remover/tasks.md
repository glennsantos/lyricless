# Implementation Plan

## Flutter Cross-Platform Implementation

- [ ] 1. Set up Flutter project structure and dependencies
  - Create new Flutter project with support for iOS, Android, and Web
  - Configure pubspec.yaml with required packages: tflite_flutter, just_audio, file_picker, path_provider, sqflite, idb_shim
  - Set minimum SDK versions (iOS 12.0+, Android API 26+)
  - Enable web support and configure web-specific settings
  - _Requirements: 2.1, 2.3, 7.3_

- [ ] 2. Implement data models
  - [ ] 2.1 Create AudioFile model
    - Define AudioFile class with id, path, title, artist, album, duration, format, isDRMProtected, albumArtwork
    - Implement toJson/fromJson for serialization
    - Add copyWith method for immutability
    - _Requirements: 1.3_
  
  - [ ] 2.2 Create CacheEntry model
    - Define CacheEntry class with fileHash, instrumentalPath, originalPath, fileSize, lastPlayed, createdAt
    - Implement database serialization methods
    - _Requirements: 5.1, 5.2_
  
  - [ ] 2.3 Create ProcessingTask model
    - Define ProcessingTask class with id, audioFile, status, progress, startTime
    - Add TaskStatus enum (queued, processing, completed, cancelled, failed)
    - _Requirements: 3.3, 3.6_
  
  - [ ] 2.4 Define error types
    - Create VocalRemoverError exception class
    - Define ErrorType enum (unsupportedFormat, drmProtected, processingFailed, etc.)
    - _Requirements: 6.3_

- [ ] 3. Implement abstract interfaces for managers
  - Create abstract classes for LibraryManager, AudioProcessor, QueueManager, CacheManager, PlaybackManager
  - Define method signatures with proper return types and parameters
  - Document expected behaviors in comments
  - _Requirements: 1.1, 2.1, 3.1, 4.1, 5.1_

- [ ] 4. Implement Library Manager
  - [ ] 4.1 Create file import functionality
    - Use file_picker package for cross-platform file selection
    - Filter for supported formats (MP3, WAV, M4A, FLAC)
    - Handle web file selection with File API
    - _Requirements: 1.1, 1.2_
  
  - [ ] 4.2 Implement metadata extraction
    - Use flutter_audio_metadata or platform channels for ID3 tag parsing
    - Extract title, artist, album, artwork
    - Handle missing metadata with defaults
    - Create web-specific implementation using Web Audio API
    - _Requirements: 1.3_
  
  - [ ] 4.3 Add DRM detection
    - Attempt audio decode to detect DRM on mobile platforms
    - For web, catch decode errors as DRM indicator
    - Mark files with isDRMProtected flag
    - _Requirements: 1.2, 6.1, 6.2_
  
  - [ ] 4.4 Implement file scanning for mobile
    - Use platform channels to access native file systems (iOS FileManager, Android MediaStore)
    - Build file list with metadata
    - Skip DRM-protected files
    - _Requirements: 1.1_

- [ ] 5. Implement Audio Processor with TensorFlow Lite
  - [ ] 5.1 Set up TFLite model loading
    - Load .tflite model from assets for mobile
    - Load TensorFlow.js model for web platform
    - Configure interpreter with GPU delegates (NNAPI for Android, Metal for iOS, WebGL for web)
    - Handle model loading errors with fallback to CPU
    - _Requirements: 2.1, 7.3_
  
  - [ ] 5.2 Implement audio pre-processing
    - Load audio file using just_audio or platform-specific decoder
    - Resample to 44.1kHz using dart audio libraries
    - Convert to PCM format
    - Implement FFT to generate spectrogram (use fftea package or Web Audio API)
    - Normalize input to [-1, 1] range
    - _Requirements: 2.4, 2.5_
  
  - [ ] 5.3 Create platform-specific pre-processing
    - Mobile: Use platform channels for native FFT (vDSP on iOS, KissFFT on Android)
    - Web: Use Web Audio API AnalyserNode for FFT
    - Ensure consistent output format across platforms
    - _Requirements: 2.4, 2.5_
  
  - [ ] 5.4 Implement inference execution
    - Feed spectrogram to TFLite interpreter (mobile) or TensorFlow.js (web)
    - Track progress and call progress callback
    - Handle inference errors and timeouts
    - Implement cancellation support
    - _Requirements: 2.1, 2.3, 3.6_
  
  - [ ] 5.5 Implement audio post-processing
    - Apply soft mask to input spectrogram
    - Perform inverse FFT using platform-specific methods
    - Mobile: Write output to WAV file in cache directory
    - Web: Create Blob from audio data
    - _Requirements: 2.2_
  
  - [ ] 5.6 Add background processing support
    - Mobile: Use compute() function for isolate-based processing
    - Web: Implement Web Worker for background processing
    - Ensure UI remains responsive during processing
    - _Requirements: 3.3, 3.5_

- [ ] 6. Implement Cache Manager with LRU eviction
  - [ ] 6.1 Set up database layer
    - Mobile: Use sqflite for SQLite database
    - Web: Use idb_shim for IndexedDB
    - Create CacheEntry table schema
    - Implement CRUD operations
    - _Requirements: 5.1_
  
  - [ ] 6.2 Implement cache storage operations
    - Mobile: Store files in app cache directory using path_provider
    - Web: Store files in Cache API with Blob objects
    - Generate SHA256 hash for file naming using crypto package
    - Write CacheEntry to database
    - _Requirements: 5.1_
  
  - [ ] 6.3 Implement cache retrieval
    - Query database by file hash
    - Mobile: Verify file exists on disk
    - Web: Check Cache API for stored audio
    - Update lastPlayed timestamp on access
    - Return file path or null if not cached
    - _Requirements: 3.1_
  
  - [ ] 6.4 Implement LRU eviction logic
    - Query entries older than 30 days
    - Sort by lastPlayed ascending
    - Delete files until cache size < 1GB
    - Remove entries from database
    - Handle platform-specific file deletion
    - _Requirements: 5.2, 5.3, 5.4, 5.5_
  
  - [ ] 6.5 Add storage monitoring
    - Calculate total cache size across platforms
    - Trigger eviction when threshold exceeded
    - Handle low storage conditions
    - Web: Monitor IndexedDB quota
    - _Requirements: 5.4, 5.5_

- [ ] 7. Implement Queue Manager with look-ahead processing
  - [ ] 7.1 Create queue state management
    - Use ValueNotifier or Riverpod for state management
    - Maintain list of AudioFile objects
    - Track currentTrack and nextTrack
    - Implement queue operations (enqueue, skip, clear)
    - _Requirements: 3.2, 4.3_
  
  - [ ] 7.2 Implement look-ahead processing logic
    - Trigger background processing when track starts playing
    - Check cache before processing next track
    - Spawn isolate (mobile) or Web Worker (web) for processing
    - Monitor for skip events
    - _Requirements: 3.2, 3.3, 3.5_
  
  - [ ] 7.3 Add task cancellation on skip
    - Cancel current background task when user skips
    - Prioritize newly selected track
    - Re-trigger look-ahead for new next track
    - Clean up resources properly
    - _Requirements: 3.4, 3.6_
  
  - [ ] 7.4 Implement repeat and shuffle modes
    - Add RepeatMode enum (off, one, all)
    - Implement shuffle algorithm with random seed
    - Update next track calculation based on mode
    - Persist mode preference
    - _Requirements: 4.5_

- [ ] 8. Implement Playback Manager
  - [ ] 8.1 Set up just_audio player
    - Initialize AudioPlayer from just_audio package
    - Configure for local file playback
    - Handle audio session interruptions
    - Set up platform-specific audio focus
    - _Requirements: 4.1_
  
  - [ ] 8.2 Implement play functionality with cache check
    - Check cache for processed instrumental
    - If not cached, show processing UI and trigger processing
    - Load audio file into player (file path for mobile, Blob URL for web)
    - Start playback and notify queue manager
    - _Requirements: 3.1, 3.2, 3.3, 4.1_
  
  - [ ] 8.3 Add playback controls
    - Implement pause, resume, seek operations
    - Expose playback state stream (isPlaying, position, duration)
    - Handle playback errors
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ] 8.4 Handle track transitions
    - Listen for playback completion events
    - Automatically advance to next track
    - Ensure seamless transition with pre-processed audio
    - Handle end of queue behavior
    - _Requirements: 3.5_
  
  - [ ] 8.5 Add volume control
    - Implement setVolume method
    - Persist volume preference
    - _Requirements: 4.1_

- [ ] 9. Implement battery optimization (mobile only)
  - [ ] 9.1 Add battery level monitoring
    - Use battery_plus package for battery monitoring
    - Listen for battery state changes
    - _Requirements: 7.1_
  
  - [ ] 9.2 Implement Battery Saver mode
    - Disable look-ahead processing when battery < 20%
    - Add user toggle in settings
    - Persist preference
    - _Requirements: 7.1_
  
  - [ ] 9.3 Add processing throttling
    - Introduce 1-second delay between background tasks
    - Prevent thermal throttling on mobile devices
    - _Requirements: 7.2_

- [ ] 10. Build Flutter UI
  - [ ] 10.1 Create app structure and navigation
    - Set up MaterialApp with theme
    - Implement bottom navigation or drawer
    - Create routes for library, now playing, queue, settings
    - Ensure responsive layout for web
    - _Requirements: All UI requirements_
  
  - [ ] 10.2 Create library screen
    - Display list of imported audio files using ListView.builder
    - Show metadata (title, artist, artwork)
    - Indicate DRM-protected files with visual marker
    - Add floating action button for file import
    - Implement search and filter functionality
    - _Requirements: 1.1, 1.3, 6.2_
  
  - [ ] 10.3 Create now playing screen
    - Display large album artwork
    - Show track title, artist, album
    - Add playback controls (play/pause, skip forward/back, seek bar)
    - Implement progress indicator
    - Add volume slider
    - Show queue button
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 8.4_
  
  - [ ] 10.4 Add processing feedback UI
    - Show circular progress indicator during first-time processing
    - Display "Removing vocals..." text with progress percentage
    - Animate album artwork during playback (rotation or pulsing)
    - Add shimmer effect for loading states
    - _Requirements: 8.1, 8.2, 8.3_
  
  - [ ] 10.5 Implement queue screen
    - Display upcoming tracks in reorderable list
    - Allow drag-to-reorder (mobile) or buttons (web)
    - Show processing status for next track
    - Add remove from queue action
    - Display current track at top
    - _Requirements: 3.2, 8.5_
  
  - [ ] 10.6 Create settings screen
    - Display cache size with clear cache button
    - Add Battery Saver toggle (mobile only)
    - Show app version and model info
    - Add repeat mode selector
    - Include about section with licenses
    - _Requirements: 5.4, 7.1_
  
  - [ ] 10.7 Implement responsive web layout
    - Create desktop-friendly layout with sidebar navigation
    - Adjust controls for mouse/keyboard input
    - Add keyboard shortcuts for playback
    - Ensure proper scaling on different screen sizes
    - _Requirements: All UI requirements_

- [ ] 11. Implement error handling and user feedback
  - [ ] 11.1 Create error handling system
    - Implement VocalRemoverError exception hierarchy
    - Add error recovery strategies
    - Log errors for debugging (use logger package)
    - _Requirements: 6.3_
  
  - [ ] 11.2 Add user-facing error messages
    - Display SnackBar or Dialog for errors
    - Provide actionable guidance in error messages
    - Implement retry mechanisms
    - _Requirements: 6.3_
  
  - [ ] 11.3 Implement fallback to original audio
    - Play original file if processing fails after retry
    - Notify user of fallback behavior
    - Log failure for analysis
    - _Requirements: 6.3_
  
  - [ ] 11.4 Add loading states throughout app
    - Show skeleton screens while loading
    - Display progress indicators for long operations
    - Provide feedback for all user actions
    - _Requirements: 8.1, 8.2, 8.3_

- [ ] 12. Implement platform-specific features
  - [ ] 12.1 Create platform channels for iOS
    - Set up MethodChannel for CoreML integration (optional optimization)
    - Implement native FFT using vDSP
    - Handle background audio session
    - _Requirements: 2.1, 7.3_
  
  - [ ] 12.2 Create platform channels for Android
    - Set up MethodChannel for native FFT if needed
    - Implement Foreground Service for background processing
    - Handle audio focus properly
    - _Requirements: 2.1, 7.3_
  
  - [ ] 12.3 Implement web-specific features
    - Use Web Audio API for audio processing
    - Implement Web Worker for background processing
    - Handle browser storage quotas
    - Add PWA manifest for installability
    - _Requirements: 2.1, 5.1_

- [ ]* 13. Add unit tests
  - [ ]* 13.1 Test Cache Manager LRU eviction
    - Verify eviction when cache exceeds 1GB
    - Test 30-day expiration logic
    - Validate LRU ordering
    - Test across mobile and web platforms
    - _Requirements: 5.2, 5.3, 5.5_
  
  - [ ]* 13.2 Test Queue Manager look-ahead logic
    - Verify background processing triggers
    - Test cancellation on skip
    - Validate next track calculation
    - Test repeat and shuffle modes
    - _Requirements: 3.2, 3.3, 3.4, 3.6_
  
  - [ ]* 13.3 Test data models
    - Test serialization/deserialization
    - Verify copyWith methods
    - Test equality and hashCode
    - _Requirements: 1.3, 5.1_
  
  - [ ]* 13.4 Test error handling
    - Verify error types are thrown correctly
    - Test recovery strategies
    - Validate fallback behavior
    - _Requirements: 6.3_

- [ ]* 14. Add widget tests
  - [ ]* 14.1 Test library screen
    - Verify file list rendering
    - Test import button interaction
    - Validate DRM indicator display
    - _Requirements: 1.1, 1.3, 6.2_
  
  - [ ]* 14.2 Test now playing screen
    - Verify playback controls work
    - Test seek bar interaction
    - Validate metadata display
    - _Requirements: 4.1, 4.2, 4.3, 4.4_
  
  - [ ]* 14.3 Test queue screen
    - Verify reordering functionality
    - Test remove from queue
    - Validate processing status display
    - _Requirements: 3.2_

## Model Preparation Tasks (Python)

- [ ] 15. Set up Python environment for model conversion
  - Create virtual environment
  - Install dependencies from requirements.txt (tensorflow, torch, coremltools, spleeter, librosa)
  - Verify installations
  - _Requirements: 2.1_

- [ ] 16. Convert AI model for mobile and web deployment
  - [ ] 16.1 Download pre-trained model
    - Obtain Spleeter 2-stem or Demucs model checkpoint
    - Verify model architecture compatibility
    - _Requirements: 2.1_
  
  - [ ] 16.2 Convert model to TensorFlow Lite
    - Create convert_model.py script
    - Apply dynamic range quantization
    - Export to .tflite format for mobile
    - Verify output size < 50MB
    - _Requirements: 2.1, 2.3_
  
  - [ ] 16.3 Convert model to TensorFlow.js
    - Use tensorflowjs_converter to create web model
    - Optimize for WebGL backend
    - Export model shards
    - Verify output size < 50MB
    - _Requirements: 2.1, 2.3_
  
  - [ ]* 16.4 Validate converted models
    - Test inference on sample audio for all platforms
    - Compare output quality with original model
    - Measure SDR metrics
    - Verify processing time meets requirements on target devices
    - _Requirements: 2.3_

## Integration and Polish

- [ ] 17. Integrate converted models into Flutter app
  - Add .tflite model to assets for mobile
  - Add TensorFlow.js model files to web assets
  - Verify model loading on all platforms
  - Test inference on each platform
  - _Requirements: 2.1_

- [ ] 18. End-to-end testing on all platforms
  - [ ] 18.1 Test on iOS devices
    - Test complete flow: import → process → cache → play → skip
    - Verify look-ahead processing works seamlessly
    - Test DRM detection and error handling
    - Measure performance metrics (processing time, battery, memory)
    - _Requirements: All_
  
  - [ ] 18.2 Test on Android devices
    - Test complete flow on multiple Android versions
    - Verify NNAPI acceleration works
    - Test Foreground Service behavior
    - Measure performance metrics
    - _Requirements: All_
  
  - [ ] 18.3 Test on web browsers
    - Test on Chrome, Firefox, Safari
    - Verify Web Worker processing
    - Test IndexedDB and Cache API storage
    - Measure performance in browser
    - Test PWA installation
    - _Requirements: All_

- [ ] 19. Performance optimization
  - [ ] 19.1 Optimize audio processing pipeline
    - Profile processing pipeline for bottlenecks
    - Optimize FFT operations
    - Reduce memory allocations
    - _Requirements: 2.3_
  
  - [ ] 19.2 Optimize UI performance
    - Ensure 60 FPS during background processing
    - Optimize list rendering with proper keys
    - Reduce unnecessary rebuilds
    - _Requirements: 7.2, 7.3_
  
  - [ ] 19.3 Optimize cache operations
    - Tune cache eviction thresholds
    - Optimize database queries
    - Reduce I/O operations
    - _Requirements: 5.2, 5.5_
  
  - [ ] 19.4 Optimize web bundle size
    - Tree-shake unused code
    - Optimize asset loading
    - Implement code splitting
    - Compress model files
    - _Requirements: 2.1_

- [ ] 20. Add analytics and monitoring (optional)
  - Implement error tracking (Sentry or similar)
  - Add performance monitoring
  - Track processing success rates
  - Monitor cache hit rates
  - Ensure privacy compliance (no PII)
  - _Requirements: All_

- [ ] 21. Final polish and bug fixes
  - Fix any crashes or UI glitches across platforms
  - Improve error messages
  - Add loading states and animations
  - Ensure consistent behavior across platforms
  - Polish web experience for desktop users
  - Test accessibility features
  - _Requirements: All_

- [ ] 22. Prepare for deployment
  - [ ] 22.1 iOS App Store preparation
    - Configure app icons and launch screens
    - Set up provisioning profiles
    - Create App Store listing
    - Prepare screenshots
    - _Requirements: All_
  
  - [ ] 22.2 Android Play Store preparation
    - Configure app icons and splash screens
    - Generate signed APK/AAB
    - Create Play Store listing
    - Prepare screenshots
    - _Requirements: All_
  
  - [ ] 22.3 Web deployment preparation
    - Configure hosting (Firebase Hosting, Netlify, etc.)
    - Set up custom domain
    - Configure PWA settings
    - Optimize for SEO
    - _Requirements: All_
