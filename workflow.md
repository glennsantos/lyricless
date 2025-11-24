# Lyricless App Workflow: Vocal Removal

This document outlines the complete workflow for obtaining vocalless audio (instrumentals) using the Lyricless app.

## 1. User Workflow (The "Happy Path")

1.  **Import Audio**:
    *   Navigate to the **Library** tab.
    *   Tap the **Import** button (Floating Action Button).
    *   Select audio files from your device. Supported formats: `MP3`, `WAV`, `M4A`, `FLAC`.
    *   *Note: Files are imported into the app's internal library.*

2.  **Select & Play**:
    *   Tap on any song in your Library.
    *   The app immediately attempts to play the song.

3.  **Automatic Processing**:
    *   **First Time Play**: If the song hasn't been processed yet, the app shows a "Processing..." state.
    *   Behind the scenes, the app removes the vocals.
    *   Once finished, playback starts automatically with the **instrumental version**.

4.  **Subsequent Plays**:
    *   The instrumental version is **cached**. Next time you play the same song, it plays instantly without waiting.

## 2. Technical Workflow (Under the Hood)

When you select a file, the `PlaybackManager` orchestrates the following pipeline:

### A. Cache Check
*   The app generates a unique hash of the file.
*   It checks `CacheManager` to see if an instrumental version already exists.
*   **Hit**: Plays the cached WAV file immediately.
*   **Miss**: Triggers `AudioProcessor`.

### B. Audio Processing Pipeline (`AudioProcessor`)
1.  **Loading & Conversion**:
    *   The original audio file is read.
    *   If it's not already WAV, it's converted to a temporary WAV file.
    *   The audio is decoded into **PCM data** (Float32List).

2.  **Spectrogram Generation (Pre-processing)**:
    *   The PCM data is transformed into a **Spectrogram** using Short-Time Fourier Transform (STFT).
    *   *Frame Size: 1024, Hop Size: 256.*
    *   This converts time-domain audio into frequency-domain visual data (Magnitude & Phase).

3.  **AI Inference (The Magic)**:
    *   The **Magnitude Spectrogram** is fed into a **TensorFlow Lite (TFLite)** model (`vocal_remover.tflite`).
    *   The model predicts a "mask" or directly outputs the instrumental spectrogram.
    *   *Note: This runs on the GPU (NNAPI on Android, Metal on iOS) for speed.*

4.  **Audio Reconstruction (Post-processing)**:
    *   The processed magnitude spectrogram is combined with the **original phase** (from step 2).
    *   **Inverse FFT (iFFT)** converts it back to time-domain audio.
    *   **Overlap-Add** method reconstructs the continuous waveform.

5.  **Saving**:
    *   The resulting vocalless audio is encoded as a **WAV file**.
    *   It is saved in the app's cache directory (e.g., `instrumental_123456789.wav`).

## 3. Output Format

*   **Current Output**: The app currently generates and plays **WAV** files.
*   **Why WAV?**: WAV is uncompressed, ensuring no quality loss during the processing pipeline.
*   **Access**: Currently, these files are stored internally for playback.
*   **Future Improvement**: To get "vocalless mp3 files" for export, an additional step would be needed to encode the WAV output to MP3 and save it to the user's public Documents/Music folder.
