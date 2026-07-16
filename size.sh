#!/bin/bash
# Path di partenza (modifica se vuoi analizzare una directory specifica)
START_PATH="/"

echo "Analizzo lo spazio disco a partire da $START_PATH..."
echo "----------------------------------------"

# Comando per trovare le directory più grandi (du usa --exclude=PATTERN, non --exclude-dir)
du -h --max-depth=1 \
    --exclude=proc \
    --exclude=sys \
    --exclude=dev \
    --exclude=run \
    "$START_PATH" 2>/dev/null | sort -hr | head -n 20

echo ""
echo "----------------------------------------"
echo "Analizzo i file più grandi (top 20)..."
echo "----------------------------------------"

# Comando per trovare i file più grandi (find usa -path ... -prune per escludere)
find "$START_PATH" \
    \( -path /proc -o -path /sys -o -path /dev -o -path /run \) -prune -o \
    -type f -exec du -h {} + 2>/dev/null | sort -hr | head -n 20
