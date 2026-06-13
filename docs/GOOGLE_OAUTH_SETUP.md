# Google OAuth Setup for pub.dev Publishing

Questo documento spiega come configurare l'autenticazione Google OAuth per pubblicare automaticamente su pub.dev tramite GitHub Actions.

## 📋 Prerequisites

- Account Google (piergiorgio.vagnozzi@gmail.com)
- Accesso a Google Cloud Console
- Repository GitHub

## 🔧 Step 1: Crea un Progetto Google Cloud

1. **Vai a Google Cloud Console**:
   - https://console.cloud.google.com/

2. **Crea un nuovo progetto**:
   - Clicca il menu a tendina "Seleziona un progetto"
   - Clicca "NUOVO PROGETTO"
   - Nome: `platform_serial_pubdev`
   - Clicca "CREA"

3. **Attendi il completamento** (ci vogliono 30 secondi circa)

## 👤 Step 2: Crea un Service Account

1. **Nel menu di Google Cloud Console**, vai a:
   - **"Credenziali"** (a sinistra)

2. **Crea una nuova credenziale**:
   - Clicca "+ CREA CREDENZIALI"
   - Seleziona **"Account di servizio"**

3. **Compila i dettagli**:
   - **Nome**: `pub-dev-publisher`
   - **ID**: `pub-dev-publisher` (auto-generato)
   - **Descrizione**: `Automatizza publishing su pub.dev`
   - Clicca "CREA E CONTINUA"

4. **Salta le altre sezioni** (facoltative):
   - Clicca "CONTINUA" → "FINE"

## 🔑 Step 3: Genera la Chiave JSON

1. **Nella lista Account di servizio**:
   - Clicca su **`pub-dev-publisher`**

2. **Nella scheda "Chiavi"**:
   - Clicca "AGGIUNGI CHIAVE" → "Crea nuova chiave"

3. **Seleziona il tipo**:
   - Tipo di chiave: **JSON**
   - Clicca "CREA"

4. **Salva il file**:
   - Il browser scaricherà automaticamente un file JSON
   - **Salva e custodiscilo in un posto sicuro**
   - Non condividerlo mai pubblicamente

**Il file JSON contiene**:
```json
{
  "type": "service_account",
  "project_id": "platform-serial-pubdev",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "pub-dev-publisher@platform-serial-pubdev.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

## 🔐 Step 4: Configura il Secret su GitHub

1. **Copia il contenuto del JSON**:
   - Apri il file JSON scaricato
   - Seleziona tutto e copia

2. **Vai al repository GitHub**:
   - Settings → Secrets and variables → Actions

3. **Crea il secret**:
   - Clicca "New repository secret"
   - **Name**: `GOOGLE_SERVICE_ACCOUNT_JSON`
   - **Value**: Incolla il contenuto JSON completo
   - Clicca "Add secret"

✅ **FATTO!** Il secret è configurato.

## 🚀 Step 5: Collega l'account pub.dev

Devi associare il Service Account Google alla tua pubblicazione su pub.dev:

1. **Vai a https://pub.dev**

2. **Accedi con il tuo account** (piergiorgio.vagnozzi@gmail.com)

3. **Vai a My Packages** (se necessario)

4. **Se `platform_serial` è già pubblicato**:
   - Clicca su "platform_serial"
   - Vai a Settings → Publishing
   - Aggiungi il Service Account come publisher autorizzato

   Oppure **Link the Service Account**:
   - URL: https://pub.dev/packages/platform_serial/admin
   - Aggiungi il service account come amministratore

**Opzionale ma consigliato**:
- In pub.dev Settings → Publish requirements
- Abilita "Requires verified publisher"
- Verifica il dominio (se disponibile)

## ✅ Verifica il Setup

1. **Testa il workflow manualmente**:
   - Vai a GitHub repo → Actions
   - Seleziona "Publish Release to pub.dev"
   - Clicca "Run workflow"
   - Seleziona il branch `main`

2. **Monitorare il workflow**:
   - Clicca sul workflow in esecuzione
   - Guarda i log per gli eventuali errori

3. **Se tutto va bene**:
   - ✅ La release viene creata
   - ✅ Il package è pubblicato su pub.dev
   - ✅ Vedi la nuova versione in https://pub.dev/packages/platform_serial

## 🔄 Flusso di Pubblicazione Automatica

Dopo il setup, la pubblicazione avviene così:

```
1. Aggiorna versione in pubspec.yaml
   ↓
2. Commit e push a develop
   ↓
3. Crea Pull Request a main
   ↓
4. Merge PR a main
   ↓
5. GitHub Actions trigger:
   - Analyze
   - Test
   - Crea GitHub Release (tag: v{version})
   - Pubblica su pub.dev (usando credenziali Google)
   ↓
✅ Nuovo package disponibile su pub.dev
```

## 🐛 Troubleshooting

### "Permission denied" durante publish

**Causa**: Il Service Account non ha accesso al package su pub.dev.

**Soluzione**:
1. Accedi a pub.dev come proprietario del package
2. Vai a https://pub.dev/packages/platform_serial/admin
3. Aggiungi il Service Account email come publisher
4. Riprova il workflow

### "Invalid credentials"

**Causa**: Il JSON secret è malformato o scaduto.

**Soluzione**:
1. Elimina il secret in GitHub
2. Genera una nuova chiave JSON da Google Cloud
3. Configura di nuovo il secret

### "Workflow stuck/hanging"

**Causa**: Potrebbe aspettare l'autenticazione manuale.

**Soluzione**:
1. Cancella il workflow
2. Verifica che `credentials.json` sia creato correttamente
3. Esegui `flutter pub publish --force` localmente per testare

### Errore: "pub.dev rejected the package"

**Cause comuni**:
- Versione duplicata (già pubblicata)
- Changelog non aggiornato
- Pubspec.yaml non valido
- Permessi insufficienti

**Soluzione**:
1. Leggi l'errore completo nei log del workflow
2. Testa localmente: `flutter pub publish --dry-run`
3. Correggi i problemi e riprova

## 📚 Link Utili

- [Google Cloud Console](https://console.cloud.google.com/)
- [pub.dev Publisher Console](https://pub.dev/packages/platform_serial/admin)
- [Dart pub publish documentation](https://dart.dev/tools/pub/publishing)
- [GitHub Actions: google-github-actions/auth](https://github.com/google-github-actions/auth)

## 🔒 Sicurezza

- ⚠️ **MAI** condividere il file JSON pubblicamente
- ⚠️ **MAI** committare il JSON nel repository
- ✅ Usa sempre GitHub Secrets per credenziali
- ✅ Rivedi periodicamente i Service Accounts attivi in Google Cloud
- ✅ Rota le credenziali ogni 90 giorni

## 🎯 Prossimi Step

1. ✅ Crea il progetto Google Cloud
2. ✅ Genera il JSON del Service Account
3. ✅ Configura il secret `GOOGLE_SERVICE_ACCOUNT_JSON` su GitHub
4. ✅ Associa il Service Account al package su pub.dev
5. ✅ Testa il workflow manualmente

---

**Domande?** Leggi la documentazione ufficiale di Dart pub.dev o contatta il supporto Google Cloud.
