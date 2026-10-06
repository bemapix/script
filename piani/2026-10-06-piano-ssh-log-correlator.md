---
type: plan
date: 2026-10-06
status: proposto
tags: [python, ssh, sysadmin, logging]
---

# SSH Log Correlator & Analyzer

Programma agentless che si connette a macchine Linux via SSH per analizzare, correlare e classificare i log di sistema e applicativi in base a timestamp e ID di transazione.

## La richiesta, chiarita
**LAVORO:** Analisi post-mortem e health-check di server Linux. Il controller locale si connette via SSH, legge i log (standard e custom), correla gli eventi che avvengono nello stesso arco temporale o condividono un ID, e produce un report ordinato per gravità con spiegazione del problema.
**PERCHE':** Attualmente l'analisi è manuale, frammentata tra più file di log e soggetta a errori di allineamento temporale. L'automazione riduce il tempo di troubleshooting e permette di identificare problemi preventivi.
**PALETTI:** 
- **Agentless:** Non deve essere installato nulla sul server remoto per evitare di alterare lo stato della macchina.
- **Configurazione esterna:** Accessi SSH e path dei log devono stare in un file di configurazione.
- **Sicurezza:** Supporto sia per password che per chiavi SSH (certificati).
**FINITO:** Output testuale o report che elenca gli errori in ordine di gravità (CRITICAL $\rightarrow$ WARNING $\rightarrow$ INFO), indicando il file di origine, il timestamp e i link agli eventi correlati in altri file.

## Cosa esiste gia'
### In casa
Nessuno strumento specifico per la correlazione di log SSH.
### Fuori
- [Vamp-Log-Hunter](https://github.com/Vampsecure-Labs/vamp-log-hunter): Eccellente per la correlazione tra `auth.log` e syslog per scopi di security. (Prova: codice)
- [Argus UEBA](https://github.com/jaradat13/argus-ueba): Utilizza LLM locali per spiegare anomalie nei log. (Prova: codice)
- [LogAnalyzer (Prakashgode)](https://github.com/Prakashgode/log-analyzer): Esempio di ricostruzione di catene di attacco. (Prova: codice)

## Verdetto
**Esiste a metà $\rightarrow$ si costruisce.**
Gli strumenti esistenti sono orientati alla Cyber Security. Serve un tool orientato alla System Administration che permetta la definizione custom di "gravità" e "correlazione" per scopi di manutenzione e stabilità.

## Il piano
Si implementerà un programma in Python strutturato come segue:
1. **Modulo SSH (Paramiko):** Gestione connessioni sicure, esecuzione di comandi `cat` o `grep` remoti per estrarre i log senza copiarli interamente in locale se non necessario.
2. **Parser Log Generico:** Motore basato su Regex che estrae Timestamp, Livello di Log (se presente), Messaggio e ID Transazione.
3. **Motore di Correlazione:**
   - **Temporale:** Raggruppamento di eventi che avvengono entro un delta $T$ (configurabile, es. 5 secondi).
   - **Logica:** Raggruppamento tramite ID univoci trovati nei messaggi.
4. **Classificatore di Gravità:** Mapping di parole chiave (es. "Panic", "Error", "Failed", "Critical") a livelli di priorità definiti in configurazione.
5. **Report Generator:** Ordinamento dei gruppi di eventi per gravità e stampa a video/file.

## Idee prese da fuori, trappole gia' pagate
- **Analisi remota vs Locale:** Per evitare di saturare la banda o il disco locale, il tool eseguirà pre-filtri (`grep` o `awk`) direttamente sul server remoto tramite SSH.
- **Gestione Timestamp:** I log Linux hanno formati di data diversi (alcuni con anno, altri no). Il parser dovrà normalizzare tutto in oggetti `datetime` Python. `da provare`: usare `dateutil.parser` per gestire formati eterogenei.
- **Falsi Positivi:** Evitare che ogni "Warning" venga visto come critico. Implementare una "whitelist" di errori noti e innocui.

## Cosa serve
- Python 3.x
- Libreria `paramiko` per SSH.
- Libreria `python-dotenv` o `yaml` per la configurazione.
- Accessi SSH (User/Password o Private Key) ai server target.

## Come si capisce se ha funzionato
**Test di Validazione:** 
Creare un set di log sintetici su una VM con:
- Un errore critico in `syslog` alle 10:00:00.
- Un errore correlato in un log applicativo alle 10:00:02.
- Un warning irrilevante alle 10:05:00.
**Risultato atteso:** Il programma deve presentare l'evento delle 10:00 come unico blocco `CRITICAL` raggruppando i due file, seguito dal warning.

## Il brief per partire

LAVORO
Costruire un programma Python "SSH Log Correlator" agentless. Il tool deve connettersi a server Linux via SSH, analizzare i log in `/var/log` (e path custom), correlare gli eventi tramite timestamp ($\pm$ 5s) e ID transazione, e produrre un report ordinato per gravità.

PERCHE'
Sostituire l'analisi manuale e frammentata dei log di sistema, permettendo un health-check rapido e la prevenzione di problemi attraverso la correlazione di errori distribuiti su più file.

PALETTI
- No installazioni sul server (Agentless).
- Accessi gestiti via file di configurazione (Password/Certificati).
- Output ordinato per gravità: [CRITICAL] $\rightarrow$ [WARNING] $\rightarrow$ [INFO].
- Supporto a path di log personalizzabili via opzioni.

FINITO
Un report finale che mostri:
`[GRAVITÀ] - Messaggio Errore - File: /path/to/log - Timestamp: YYYY-MM-DD HH:MM:SS - Correlati: [File B, File C]`
Verifica: Corretta associazione di eventi distribuiti in file diversi che avvengono nello stesso arco temporale.

RIFERIMENTI
- Libreria `paramiko` per la gestione SSH.
- Ispirazione per la correlazione: [Vamp-Log-Hunter](https://github.com/Vampsecure-Labs/vamp-log-hunter).

PRIMA di partire
Intervistami su:
1. Quali sono le parole chiave che definiscono per te un errore "CRITICAL" rispetto a un "WARNING"?
2. Esistono ID di transazione specifici (es. Request-ID) che il programma deve cercare prioritariamente?
