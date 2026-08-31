#!/bin/bash
# Verifica quali modelli cloud Ollama sono davvero raggiungibili sul tuo account.
#
# Perché non scraping + regex: la pagina ollama.com/library elenca TUTTI i modelli
# (quasi tutti locali) e non c'è modo di dedurre in modo affidabile quali siano
# cloud e disponibili sul piano free indovinando dal nome. L'unica fonte
# autorevole è la pagina "Cloud Usage" del tuo account (screenshot) o una vera
# chiamata autenticata. Qui testiamo la lista attuale del tuo piano; se Ollama
# la cambia, aggiorna semplicemente l'array MODELLI qui sotto.

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

echo -e "${CYAN}=== Verifica modelli cloud Ollama (piano Free) ===${RESET}"

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Errore: 'jq' non è installato. Installalo con 'sudo apt install jq'.${RESET}"
    exit 1
fi

OLLAMA_HOST=${OLLAMA_HOST:-"http://localhost:11434"}
if ! curl -s --connect-timeout 2 "$OLLAMA_HOST" &> /dev/null; then
    echo -e "${RED}Errore: Ollama locale deve essere attivo (ollama serve).${RESET}"
    exit 1
fi

# Lista reale presa dalla pagina Cloud Usage del tuo account (aggiornala se cambia).
# Nota il tag: il suffisso è "-cloud" sul TAG, non ":cloud" sul nome base.
MODELLI=(
    "gemma4:31b-cloud"
    "gpt-oss:120b-cloud"
    "gpt-oss:20b-cloud"
    "nemotron-3-nano:30b-cloud"
    "nemotron-3-super:cloud"
    "nemotron-3-ultra:cloud"
)

echo -e "${YELLOW}Test di chiamata reale in corso (richiede login: 'ollama signin')...${RESET}\n"
printf "%-30s | %-25s\n" "MODELLO" "STATO"
echo "--------------------------------------------------------------"

for tag_modello in "${MODELLI[@]}"; do
    risposta_api=$(curl -s -w "\n%{http_code}" -X POST "$OLLAMA_HOST/api/generate" \
        -d "{\"model\": \"$tag_modello\", \"prompt\": \"hi\", \"stream\": false}" --max-time 15)
    http_code=$(echo "$risposta_api" | tail -n 1)
    corpo_risposta=$(echo "$risposta_api" | sed '$d')

    if [ "$http_code" -eq 200 ]; then
        stato="Disponibile e funzionante"
        colore=$GREEN
    elif [ "$http_code" -eq 401 ]; then
        stato="Non autenticato (esegui: ollama signin)"
        colore=$RED
    elif [ "$http_code" -eq 403 ] || echo "$corpo_risposta" | grep -qi "subscription"; then
        stato="Richiede un piano superiore"
        colore=$RED
    elif [ "$http_code" -eq 429 ]; then
        stato="Limite di sessione/settimana raggiunto"
        colore=$YELLOW
    else
        stato="Errore (HTTP $http_code)"
        colore=$YELLOW
    fi

    printf "%-30s | %b%-25s%b\n" "$tag_modello" "$colore" "$stato" "$RESET"
done

echo "--------------------------------------------------------------"
