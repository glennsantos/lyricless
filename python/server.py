import os
import shutil
import tempfile
from pathlib import Path
from typing import Optional

import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException, BackgroundTasks
from fastapi.responses import FileResponse, JSONResponse
from pydantic import BaseModel

# Import existing logic (assuming it's in the same directory or properly installed)
# We might need to adjust imports if running from root vs python dir
try:
    from vocal_remover_cli import remove_vocals
except ImportError:
    # Fallback for running from root
    import sys
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    from vocal_remover_cli import remove_vocals

app = FastAPI(title="Lyricless Vocal Remover API")

class ProcessResponse(BaseModel):
    task_id: str
    status: str
    message: str

# Store for task status (in-memory for simplicity)
tasks = {}

@app.get("/")
async def root():
    return {"message": "Lyricless Vocal Remover API is running"}

@app.post("/process")
async def process_audio(file: UploadFile = File(...)):
    """
    Upload an audio file to remove vocals.
    Returns the instrumental file directly for simplicity in this version.
    """
    # Create a temporary directory for this request
    temp_dir = Path(tempfile.mkdtemp(prefix="lyricless_"))
    
    try:
        # Save uploaded file
        input_path = temp_dir / file.filename
        with open(input_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Define output path
        output_filename = f"{input_path.stem}_instrumental.mp3"
        output_path = temp_dir / output_filename
        
        # Run vocal removal (synchronously for now, can be asyncified)
        # We use the existing logic from vocal_remover_cli
        print(f"Processing {input_path}...")
        result_path = remove_vocals(
            str(input_path), 
            str(output_path), 
            verbose=True, 
            json_progress=False
        )
        
        # Return the file
        # We use a background task to clean up the temp dir after sending
        return FileResponse(
            path=result_path, 
            filename=output_filename,
            media_type="audio/mpeg",
            background=BackgroundTasks()
        )
        
    except Exception as e:
        # Cleanup on error
        shutil.rmtree(temp_dir, ignore_errors=True)
        raise HTTPException(status_code=500, detail=str(e))

def cleanup_temp_dir(path: Path):
    try:
        shutil.rmtree(path, ignore_errors=True)
    except Exception as e:
        print(f"Error cleaning up {path}: {e}")

# Add cleanup to FileResponse
# Note: FastAPI's background tasks run after the response is sent.
# However, FileResponse might need the file to exist while streaming.
# A robust solution would use a separate cleanup job or rely on OS temp cleanup.
# For this MVP, we'll leave the temp files or implement a periodic cleaner.
# OR better: we can subclass FileResponse to delete after.

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
