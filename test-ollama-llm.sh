#!/bin/bash

LOG="ollama-cloud-test.log"

if [ ! -f "model_names.txt" ]; then
    echo "File model_names.txt mancante"
    exit 1
fi

echo "===================================" | tee "$LOG"
echo " Test Ollama Cloud Free Tier" | tee -a "$LOG"
date | tee -a "$LOG"
echo "===================================" | tee -a "$LOG"


while read -r MODEL; do

    [ -z "$MODEL" ] && continue

    echo
    echo "Testing: $MODEL"

    RESULT=$(timeout 20 ollama show "$MODEL" 2>&1)

    if echo "$RESULT" | grep -qi "not found"; then
        STATUS="❌ NON DISPONIBILE"

    elif echo "$RESULT" | grep -qi "subscription\|upgrade\|403\|forbidden"; then
        STATUS="🔒 SOLO ABBONAMENTO"

    else
        STATUS="✅ PRESENTE/ACCESSIBILE"
    fi

    echo "$MODEL --> $STATUS" | tee -a "$LOG"

done < model_names.txt


echo
echo "Test completato"
echo "Log: $LOG"
