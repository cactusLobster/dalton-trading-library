#!/bin/bash
set -e

OUT="/Users/jarvis/_OpenClaw/agents/tick/knowledge/dalton"

# Convert each slide PDF to images, then OCR
for DVD in 1 2 3 4; do
  PDF="$OUT/Field of Vision Course Slides, DVD ${DVD}.pdf"
  SLIDE_DIR="$OUT/dvd${DVD}_slide_images"
  OCR_OUT="$OUT/field-of-vision-slides-${DVD}-ocr.txt"
  
  if [ -f "$OCR_OUT" ]; then
    echo "DVD $DVD slides already OCR'd, skipping"
    continue
  fi
  
  echo "[$(date)] Processing DVD $DVD slides..."
  
  # Convert PDF pages to images using sips/ImageMagick alternative
  mkdir -p "$SLIDE_DIR"
  
  # Use python to convert PDF pages to images
  python3 << PYEOF
import subprocess, os, glob

pdf = "$PDF"
out_dir = "$SLIDE_DIR"

# Use pdf2image if available, otherwise fall back to sips
try:
    from pdf2image import convert_from_path
    images = convert_from_path(pdf, dpi=300)
    for i, img in enumerate(images):
        img.save(os.path.join(out_dir, f"page_{i+1:03d}.png"))
    print(f"Converted {len(images)} pages")
except ImportError:
    # Fallback: use ghostscript or pdftoppm
    r = subprocess.run(['pdftoppm', '-png', '-r', '300', pdf, os.path.join(out_dir, 'page')], 
                       capture_output=True, text=True)
    if r.returncode != 0:
        # Last resort: convert via preview/sips won't work for multi-page PDF
        # Use ghostscript
        subprocess.run(['gs', '-dBATCH', '-dNOPAUSE', '-sDEVICE=png16m', '-r300',
                       f'-sOutputFile={out_dir}/page_%03d.png', pdf],
                       capture_output=True, text=True)
    pages = glob.glob(os.path.join(out_dir, '*.png'))
    print(f"Converted {len(pages)} pages")
PYEOF
  
  # OCR each page image
  echo "" > "$OCR_OUT"
  for img in $(ls "$SLIDE_DIR"/*.png 2>/dev/null | sort); do
    page=$(basename "$img" .png)
    echo "--- $page ---" >> "$OCR_OUT"
    tesseract "$img" stdout 2>/dev/null >> "$OCR_OUT"
    echo "" >> "$OCR_OUT"
  done
  
  chars=$(wc -c < "$OCR_OUT")
  echo "[$(date)] DVD $DVD slides OCR complete: $chars chars"
done

echo "=== ALL SLIDES OCR COMPLETE ==="
