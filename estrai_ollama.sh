#!/bin/bash

# Configurazione colori per il terminale
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0;37m'
RESET='\033[0m'

echo -e "${CYAN}=== Estrazione Modelli Ollama Free Veri (No Subscription) ===${RESET}"

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Errore: 'jq' non è installato. Installalo con 'sudo apt install jq'.${RESET}"
    exit 1
fi

OLLAMA_HOST=${OLLAMA_HOST:-"http://localhost:11434"}
if ! curl -s --connect-timeout 2 "$OLLAMA_HOST" &> /dev/null; then
    echo -e "${RED}Errore: Ollama locale deve essere attivo per fare il test di chiamata cloud.${RESET}"
    exit 1
fi

echo -e "${YELLOW}Lettura del catalogo e test di chiamata in corso...${RESET}"
Modelli_Raw=$(curl -s https://ollama.com/library | grep -oE 'href="/library/[a-zA-Z0-9._-]+"' | cut -d'"' -f2 | cut -d'/' -f3 | sort -u)

if [ -z "$Modelli_Raw" ]; then
    Modelli_Raw=("gemma2" "qwen2.5" "deepseek-r1" "llama3.3" "mistral" "phi4" "minimax-m2.5" "glm-4" "kimi-k2.5-code")
fi

echo -e "\n--------------------------------------------------------------------------------"
printf "%-25s | %-30s | %-25s\n" "NOME MODELLO" "TIPO ACCESSO" "STATO DI ACCESSO"
echo -e "--------------------------------------------------------------------------------"

for modello in $Modelli_Raw; do
    if [[ "$modello" =~ (minimax|glm|kimi|cloud|gpt-oss) ]]; then
        tipo_accesso="CLOUD (No Download)"
        colore_tipo=$GREEN
        tag_modello="${modello}:cloud"
    else
        tipo_accesso="Locale (Download richiesto)"
        colore_tipo=$NC
        tag_modello="${modello}:latest"
    fi

    if [[ "$tipo_accesso" == "CLOUD (No Download)" ]]; then
        # TEST REALE DI CHIAMATA CLOUD: Inviamo un prompt minimo per vedere se rifiuta la connessione (403)
        # Usiamo un timeout breve per non bloccare lo script
        risposta_api=$(curl -s -w "\n%{http_code}" -X POST "$OLLAMA_HOST/api/generate" \
            -d "{\"model\": \"$tag_modello\", \"prompt\": \"hi\", \"stream\": false}" --max-time 5)
        
        http_code=$(echo "$risposta_api" | tail -n 1)
        corpo_risposta=$(echo "$risposta_api" | head -n -1)

        if [ "$http_code" -eq 200 ]; then
            stato_test="Gratuito & Disponibile"
            colore_stato=$GREEN
        elif [[ "$corpo_risposta" =~ "subscription" || "$http_code" -eq 403 ]]; then
            stato_test="Richiede Abbonamento"
            colore_stato=$RED
        else
            stato_test="Errore: Crediti Esauriti "
            colore_stato=$YELLOW
        fi
    else
        # Per i modelli locali verifichiamo solo la presenza sul registro remoto come prima
        controllo_remoto=$(curl -s -X POST "$OLLAMA_HOST/api/show" -d "{\"name\": \"$tag_modello\"}" -w "%{http_code}" -o /dev/null)
        if [ "$controllo_remoto" -eq 200 ]; then
            stato_test="Disponibile al Download"
            colore_stato=$YELLOW
        else
            stato_test="Non trovato online"
            colore_stato=$RED
        fi
    fi

    printf "%-25s | %b%-30s%b | %b%-25s%b\n" \
        "$modello" \
        "$colore_tipo" "$tipo_accesso" "$RESET" \
        "$colore_stato" "$stato_test" "$RESET"
done

echo -e "--------------------------------------------------------------------------------"
