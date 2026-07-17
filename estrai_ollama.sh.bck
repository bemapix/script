#!/bin/bash

# Configurazione colori per il terminale
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0;37m' # Bianco/Grigio standard
RESET='\033[0m'

echo -e "${CYAN}=== Estrazione Modelli Ollama Free & Verifica Cloud ===${RESET}"

# 1. Verifica che curl e jq siano installati
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Errore: 'jq' non è installato. Installalo con 'sudo apt install jq'.${RESET}"
    exit 1
fi

# 2. Controllo se il servizio Ollama locale è attivo
OLLAMA_HOST=${OLLAMA_HOST:-"http://localhost:11434"}
if ! curl -s --connect-timeout 2 "$OLLAMA_HOST" &> /dev/null; then
    echo -e "${YELLOW}Avviso: Ollama locale non risponde su $OLLAMA_HOST.${RESET}"
    echo -e "${YELLOW}Il test sicuro senza download richiede che il demone Ollama sia avviato.${RESET}\n"
fi

# 3. Estrazione dei modelli dal catalogo pubblico di Ollama
echo -e "${YELLOW}Lettura dei modelli dal catalogo pubblico di Ollama...${RESET}"
Modelli_Raw=$(curl -s https://ollama.com/library | grep -oE 'href="/library/[a-zA-Z0-9._-]+"' | cut -d'"' -f2 | cut -d'/' -f3 | sort -u)

# Fallback se lo scraping fallisce o il sito cambia struttura
if [ -z "$Modelli_Raw" ]; then
    Modelli_Raw=("gemma2" "qwen2.5" "deepseek-r1" "llama3.3" "mistral" "phi4" "minimax-m2.5" "glm-4" "kimi-k2.5-code")
fi

echo -e "\n--------------------------------------------------------------------------------"
printf "%-25s | %-30s | %-25s\n" "NOME MODELLO" "TIPO ACCESSO" "STATO TEST SICURO"
echo -e "--------------------------------------------------------------------------------"

for modello in $Modelli_Raw; do
    # Identifica se è un modello cloud (es. minimax, glm, kimi o tag espliciti)
    if [[ "$modello" =~ (minimax|glm|kimi|cloud|gpt-oss) ]]; then
        tipo_accesso="CLOUD (No Download)"
        colore_tipo=$GREEN
        tag_modello="${modello}:cloud"
    else
        tipo_accesso="Locale (Download richiesto)"
        colore_tipo=$NC
        tag_modello="${modello}:latest"
    fi

    # 4. Test di verifica sicuro tramite API locale (NON usa 'ollama run/pull' sul disco)
    controllo_remoto=$(curl -s -X POST "$OLLAMA_HOST/api/show" -d "{\"name\": \"$tag_modello\"}" -w "%{http_code}" -o /dev/null)

    if [ "$controllo_remoto" -eq 200 ]; then
        stato_test="Disponibile (OK)"
        colore_stato=$GREEN
    elif [ "$controllo_remoto" -eq 404 ]; then
        stato_test="Verificabile online"
        colore_stato=$YELLOW
    else
        stato_test="Host locale offline"
        colore_stato=$RED
    fi

    # Stampa formattata accoppiando correttamente i codici colore (%b) con le stringhe (%s)
    printf "%-25s | %b%-30s%b | %b%-25s%b\n" \
        "$modello" \
        "$colore_tipo" "$tipo_accesso" "$RESET" \
        "$colore_stato" "$stato_test" "$RESET"
done

echo -e "--------------------------------------------------------------------------------"
echo -e "${CYAN}Fine report.${RESET}"
