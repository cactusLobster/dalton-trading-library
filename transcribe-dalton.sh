#!/bin/bash
set -e

SRC="/Users/jarvis/Desktop/Trading/Trading Discord/Dalton"
OUT="/Users/jarvis/_OpenClaw/agents/tick/knowledge/dalton"

for DVD in 1 2 3 4; do
  echo "=== DVD $DVD ==="
  VIDEO="$SRC/Fields_of_Vision_DVD${DVD}.avi"
  AUDIO="$OUT/dvd${DVD}_audio.wav"
  FRAMES_DIR="$OUT/dvd${DVD}_frames"
  
  # 1. Extract audio
  if [ ! -f "$AUDIO" ]; then
    echo "[$(date)] Extracting audio from DVD $DVD..."
    ffmpeg -i "$VIDEO" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO" -y 2>/dev/null
    echo "[$(date)] Audio extracted: $(du -h "$AUDIO" | cut -f1)"
  else
    echo "Audio already exists, skipping extraction"
  fi
  
  # 2. Extract frames every 30 seconds
  if [ ! -d "$FRAMES_DIR" ]; then
    echo "[$(date)] Extracting frames every 30s from DVD $DVD..."
    mkdir -p "$FRAMES_DIR"
    ffmpeg -i "$VIDEO" -vf "fps=1/30,scale=800:-1" -q:v 3 "$FRAMES_DIR/frame_%04d.jpg" -y 2>/dev/null
    echo "[$(date)] Frames extracted: $(ls "$FRAMES_DIR" | wc -l) frames"
  else
    echo "Frames already exist, skipping extraction"
  fi
  
  # 3. Transcribe with Whisper (SRT format for timestamps)
  if [ ! -f "$OUT/dvd${DVD}_audio.srt" ]; then
    echo "[$(date)] Transcribing DVD $DVD with Whisper (medium model)..."
    whisper "$AUDIO" --model turbo --output_format srt --output_dir "$OUT" 2>&1 | tail -5
    echo "[$(date)] Transcription complete"
  else
    echo "Transcript already exists, skipping"
  fi
  
  echo "[$(date)] DVD $DVD done"
  echo ""
done

echo "=== ALL DVDs COMPLETE ==="
echo "[$(date)] Starting contextualization..."
