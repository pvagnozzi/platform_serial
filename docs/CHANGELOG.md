## 0.1.0

### Primi release - Funzionalità core

#### Aggiunte
- Interfaccia unificata `SerialPort` per la comunicazione seriale
- `SerialManager` per la gestione centralizzata delle porte
- Supporto per lettura sincrona e asincrona
- Supporto per dati binari e testuali
- Stream di dati per una lettura continua asincrona
- Configurazione flessibile (baudrate, bit, stop bits, parità, controllo flusso)
- Timeout configurabile per letture e scritture
- Gestione robusta degli errori con tipi specifici:
  - `portNotFound`
  - `portAlreadyOpen`
  - `portClosed`
  - `configurationError`
  - `timeout`
  - `platformUnavailable`
  - `ioError`
  - `permissionDenied`
  - `bufferOverflow`
  - `unknown`

#### Piattaforme supportate
- Windows (implementazione FFI)
- Linux (implementazione FFI)
- macOS (implementazione FFI)
- Android (channel platform + OTG)
- iOS (channel platform + OTG)

#### Informazioni su porte
- Lista delle porte disponibili
- Dettagli del dispositivo (vendor ID, product ID, numero di serie)
- Stato della porta (aperta/chiusa)

#### Test
- Unit test per la logica core
- Integration test per il comportamento platform-specific
- E2E test con good path, bad path e edge cases
- Mock di porte seriali virtuali

#### Note
- Prima versione di rilascio - stabilità della versione
- Pronto per l'uso in produzione su tutte le piattaforme supportate
