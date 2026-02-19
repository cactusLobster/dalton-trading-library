#!/bin/bash
set -e
OUT="/Users/jarvis/_OpenClaw/agents/tick/knowledge/dalton"

for DVD in 2 3 4; do
  echo "=== DVD $DVD ==="
  AUDIO="$OUT/dvd${DVD}_audio.wav"
  SRT="$OUT/dvd${DVD}_audio.srt"
  
  if [ -f "$SRT" ]; then
    echo "SRT already exists, skipping"
    continue
  fi
  
  # Extract audio if needed
  if [ ! -f "$AUDIO" ]; then
    echo "[$(date)] Extracting audio..."
    ffmpeg -i "/Users/jarvis/Desktop/Trading/Trading Discord/Dalton/Fields_of_Vision_DVD${DVD}.avi" -vn -acodec pcm_s16le -ar 16000 -ac 1 "$AUDIO" -y 2>/dev/null
  fi
  
  # Extract frames if needed
  FRAMES_DIR="$OUT/dvd${DVD}_frames"
  if [ ! -d "$FRAMES_DIR" ]; then
    echo "[$(date)] Extracting frames..."
    mkdir -p "$FRAMES_DIR"
    ffmpeg -i "/Users/jarvis/Desktop/Trading/Trading Discord/Dalton/Fields_of_Vision_DVD${DVD}.avi" -vf "fps=1/30,scale=800:-1" -q:v 3 "$FRAMES_DIR/frame_%04d.jpg" -y 2>/dev/null
  fi
  
  # Transcribe with MLX Whisper (Apple Silicon GPU accelerated)
  echo "[$(date)] Transcribing DVD $DVD with MLX Whisper..."
  python3 -c "
import mlx_whisper, json

result = mlx_whisper.transcribe('$AUDIO', path_or_hf_repo='mlx-community/whisper-turbo')

# Write SRT
with open('$SRT', 'w') as f:
    for i, seg in enumerate(result['segments']):
        start = seg['start']
        end = seg['end']
        text = seg['text'].strip()
        sh, sm, ss = int(start//3600), int((start%3600)//60), start%60
        eh, em, es = int(end//3600), int((end%3600)//60), end%60
        f.write(f'{i+1}\n')
        f.write(f'{sh:02d}:{sm:02d}:{ss:06.3f} --> {eh:02d}:{em:02d}:{es:06.3f}\n')
        f.write(f'{text}\n\n')

print(f'DVD $DVD: {len(result[\"segments\"])} segments, {len(result[\"text\"])} chars')
"
  echo "[$(date)] DVD $DVD done"
done

echo "=== ALL DVDS COMPLETE ==="
