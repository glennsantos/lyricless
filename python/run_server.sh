#!/bin/bash
source /Users/aryeh/dev/lyricless/python/venv/bin/activate
cd /Users/aryeh/dev/lyricless/python
uvicorn server:app --reload --host 0.0.0.0 --port 8000
