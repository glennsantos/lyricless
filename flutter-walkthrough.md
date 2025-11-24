Python CLI Integration Walkthrough
Overview
Successfully integrated the working Python vocal remover CLI into the Flutter app, replacing the non-functional TFLite implementation. The app now uses a Python subprocess to perform vocal removal with the battle-tested Spleeter library.

Changes Made
1. Enhanced Python CLI Script
Modified 
vocal_remover_cli.py
 to support machine-readable progress output:

Key additions:

Added --json-progress flag for JSON output mode
Created 
_emit_progress()
 helper function
Progress updates now output to stdout as JSON
Human-readable messages go to stderr in JSON mode
Added progress checkpoints at key stages (0%, 10%, 30%, 80%, 100%)
Example JSON output:

{"progress": 0.0, "status": "Initializing"}
{"progress": 0.1, "status": "Loading model"}
{"progress": 0.3, "status": "Separating audio"}
{"progress": 0.8, "status": "Processing output"}
{"progress": 1.0, "status": "Complete"}
{"success": true, "output_path": "/path/to/output.mp3"}
2. Created PythonAudioProcessor
Created 
python_audio_processor.dart
 as a new implementation of the 
AudioProcessor
 interface.

Key features:

Process Execution: Uses Dart's Process.start() to run the Python script
Progress Parsing: Monitors stdout for JSON progress updates
Error Handling: Captures stderr and maps errors to VocalRemoverError
Cancellation: Implements process termination via SIGTERM
Validation: Checks for Python environment and dependencies during initialization
Hardcoded paths:

static const String _pythonPath = '/Users/aryeh/dev/lyricless/python/venv/bin/python';
static const String _scriptPath = '/Users/aryeh/dev/lyricless/python/vocal_remover_cli.py';
3. Updated Main App Configuration
Modified 
main.dart
 to use the new processor:

-import 'managers/audio_processor_impl.dart';
+import 'managers/python_audio_processor.dart';
-final audioProcessorProvider = Provider((ref) => AudioProcessorImpl());
+final audioProcessorProvider = Provider((ref) => PythonAudioProcessor());
How It Works
Initialization Flow
App starts → 
main.dart
 initializes 
PythonAudioProcessor
Processor checks:
Python executable exists at the specified path
Python script exists
Spleeter is installed (import spleeter test)
Ready → Processor marked as initialized
Processing Flow
User selects audio file → Flutter UI calls 
processAudio()
Validation → Check input file exists
Generate output path → Create temp directory path with timestamp
Start Python process:
/path/to/python vocal_remover_cli.py <input> <output> --json-progress
Monitor progress:
Parse JSON from stdout
Extract 
progress
 and status fields
Call Flutter progress callback
Display in UI
Wait for completion:
Process exits with code 0 (success)
Output file is verified to exist
Return result → Path to instrumental MP3
Error Handling
Missing Python: VocalRemoverError.modelLoadFailed during initialization
Missing Spleeter: VocalRemoverError.modelLoadFailed during initialization
Process failure: VocalRemoverError.processingFailed with stderr contents
Missing output: VocalRemoverError.processingFailed if file not created
Testing Instructions
Quick Test via CLI
Test the enhanced Python CLI directly:

cd /Users/aryeh/dev/lyricless/python
./venv/bin/python vocal_remover_cli.py /path/to/song.mp3 --json-progress
You should see JSON progress updates followed by the final success message.

Testing in Flutter App
Run the app:

cd /Users/aryeh/dev/lyricless
flutter run -d macos
Select an audio file from the UI

Monitor progress in the UI progress bar

Verify output:

Check that the instrumental file is created
Listen to verify vocals are removed
Check console for debug output showing progress updates
Debugging
Enable verbose logging in the Python script:

# Shows stderr messages in console
flutter run -d macos --verbose
Check Python process output in Flutter console:

Look for [Python stderr] prefixed messages
Progress updates show as Progress: XX.X% - Status
Known Limitations
IMPORTANT

Platform Support: This implementation only works on macOS desktop where the Python environment is installed. It will NOT work on:

iOS (no Python runtime)
Android (no Python runtime)
Web (no subprocess support)
NOTE

Python Path: The Python interpreter path is hardcoded. If the virtual environment is moved or recreated, the path in 
python_audio_processor.dart
 must be updated.

Files Modified
vocal_remover_cli.py
 - Added JSON progress mode
python_audio_processor.dart
 - New processor implementation
main.dart
 - Use new processor
Next Steps
To make this more robust, consider:

Dynamic path discovery: Use environment variables or config files instead of hardcoded paths
Fallback mechanism: Keep old 
AudioProcessorImpl
 as a backup
Platform detection: Auto-select appropriate processor based on platform
Progress refinement: Add more granular progress updates from Spleeter
Error messages: Improve user-facing error messages with recovery suggestions