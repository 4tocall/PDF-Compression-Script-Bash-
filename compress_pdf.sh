#!/bin/bash

if [ -z "$1" ]; then
  echo "❌ Usage: compress /path/to/file.pdf [quality]"
  exit 1
fi

FILE="$1"

if [ ! -f "$FILE" ]; then
  echo "❌ File not found: $FILE"
  exit 1
fi

QUALITY="${2:-2}"

if [[ ! "$QUALITY" =~ ^[1-3]$ ]]; then
  QUALITY=2
fi

EXT="${FILE##*.}"
BASENAME="${FILE%.*}"
DIRNAME="$(dirname "$FILE")"
BASENAME_ONLY="$(basename "$BASENAME")"
OUTPUT="${DIRNAME}/${BASENAME_ONLY}_compressed.${EXT}"

i=2
while [ -f "$OUTPUT" ]; do
  OUTPUT="${DIRNAME}/${BASENAME_ONLY}_compressed_${i}.${EXT}"
  ((i++))
done

ORIG_SIZE=$(du -h "$FILE" | cut -f1)

case "$QUALITY" in
  1)
    PDFSETTING="/prepress"
    QUALITY_LABEL="Less compression, High quality (adjusted with image downsampling)"
    EXTRA_GS_OPTS="-dColorImageResolution=150 -dGrayImageResolution=150 -dMonoImageResolution=150 \
-dDownsampleColorImages=true -dDownsampleGrayImages=true -dDownsampleMonoImages=true \
-dColorImageDownsampleType=/Bicubic -dGrayImageDownsampleType=/Bicubic -dMonoImageDownsampleType=/Subsample"
    ;;
  2)
    PDFSETTING="/ebook"
    QUALITY_LABEL="Recommended compression, Good quality"
    EXTRA_GS_OPTS=""
    ;;
  3)
    PDFSETTING="/screen"
    QUALITY_LABEL="Extreme compression, Less quality"
    EXTRA_GS_OPTS=""
    ;;
esac

FILE_BASENAME="$(basename "$FILE")"
case "$QUALITY" in
  1)
    QUALITY_DESC="Less compression, High quality (adjusted with image downsampling)"
    ;;
  2)
    QUALITY_DESC="Recommended compression, Good quality"
    ;;
  3)
    QUALITY_DESC="Extreme compression, Less quality"
    ;;
  *)
    QUALITY_DESC="Recommended compression, Good quality (default)"
    ;;
esac

# Couleurs ANSI
YELLOW="\033[33m"
GREEN="\033[32m"
RESET="\033[0m"

echo -e "⏳ Starting compression of \"$FILE_BASENAME\" with quality setting: ${YELLOW}$QUALITY ($QUALITY_DESC)${RESET}..."

gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="$PDFSETTING" \
-dNOPAUSE -dQUIET -dBATCH $EXTRA_GS_OPTS \
-sOutputFile="$OUTPUT" "$FILE"

if [ -f "$OUTPUT" ]; then
  COMP_SIZE=$(du -h "$OUTPUT" | cut -f1)
  OUTPUT_BASENAME=$(basename "$OUTPUT")
  echo -e "✅ ${GREEN}Compressed file: $OUTPUT_BASENAME${RESET} | Original size: ${YELLOW}$ORIG_SIZE${RESET} | Compressed size: ${GREEN}$COMP_SIZE${RESET}"
else
  echo "❌ An error occurred during compression."
fi
