#!/bin/bash

# Controlla se jq è installato
if ! command -v jq &> /dev/null; then
    echo "Errore: 'jq' non è installato. Installalo con:"
    echo "  - Debian/Ubuntu: sudo apt-get install jq"
    echo "  - macOS: brew install jq"
    exit 1
fi

# URL dell'API di Ollama per ottenere la lista dei modelli
API_URL="https://ollama.com/api/tags"

# Scarica i dati JSON dall'API
echo "Scaricamento della lista dei modelli da Ollama..."
response=$(curl -s "$API_URL")

# Controlla se la richiesta è andata a buon fine
if [ -z "$response" ]; then
    echo "Errore: Impossibile scaricare i dati dall'API di Ollama."
    exit 1
fi

# Estrai i nomi dei modelli e salvali in un file
echo "Estrazione dei nomi dei modelli..."
jq -r '.models[].name' <<< "$response" > model_names.txt

# Verifica se il file è stato creato correttamente
if [ -s "model_names.txt" ]; then
    # Conta il numero di modelli scaricati
    model_count=$(wc -l < model_names.txt)
    echo "Successo! Tutti i modelli sono stati salvati in 'model_names.txt'."
    echo "Numero totale di modelli scaricati: $model_count"
else
    echo "Errore: Nessun modello trovato. Controlla la risposta dell'API."
    echo "Risposta grezza:"
    echo "$response"
fi
