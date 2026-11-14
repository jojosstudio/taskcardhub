# Taskcard Hub Flutter-App

Native Flutter-Android-App für `https://hub.jojosstudio.de` mit:

- eigener mobiler Oberfläche und Bottom-Navigation
- Taskcard-Liste, Suche und Status-/Fachfiltern
- Warnung vor nicht bestätigten Links
- nativer Clerk-Anmeldung und Kontoverwaltung
- Taskcard-Erstellung mit Clerk-Session-Token
- bestehender Taskcard-Hub-API und MySQL-Datenbank als Backend

Am Server musste für die App nichts geändert werden. Es gibt deshalb keinen
zusätzlichen Server-Upload-Patch.

## Lokal testen

```powershell
flutter pub get
flutter run
```

APK:

```powershell
flutter build apk --debug
```

Für die Production-Instanz kann der Publishable Key beim Build gesetzt werden:

```powershell
flutter build apk --release `
  --dart-define=CLERK_PUBLISHABLE_KEY=pk_live_DEIN_PUBLISHABLE_KEY
```

Secret Keys gehören niemals in Flutter-Code, APKs oder Git.

## Clerk

Die ausgewählte Clerk-Anwendung bleibt:

`app_3M1A3oJHgrcJFZGzIpAw04kVJKg`

Keine andere Anwendung anlegen oder auswählen. Im Clerk Dashboard:

1. **Native API** aktivieren.
2. Unter **Native applications** die Android-App registrieren.
3. Paketname und SHA-256-Zertifikat hinterlegen.

Für den aktuellen Debug-Test sind diese Werte einzutragen:

- Namespace: `de.jojosstudio.taskcard_hub_flutter`
- Paketname: `de.jojosstudio.taskcard_hub_flutter`
- Debug-SHA-256: `01:79:ED:DE:A2:0C:CA:BF:BD:6C:B3:66:F0:27:0C:74:0C:96:A8:DC:F2:FA:16:15:FE:7A:C2:F8:25:A4:D1:39`
- Native Callback (automatisch): `clerk://de.jojosstudio.taskcard_hub_flutter.callback`
- Web-Redirect-URL: `https://hub.jojosstudio.de`

Wichtig: Die `clerk://...callback`-Adresse wird von der Native-App automatisch
registriert und darf nicht als normale Web-Redirect-URL eingetragen werden.
Für die Account-Portal-Redirects ist `https://hub.jojosstudio.de` zu verwenden.

Falls die Clerk-CLI benötigt wird, zuerst im Host-Terminal anmelden:

```powershell
npx -y clerk@latest auth login
npx -y clerk@latest init --app app_3M1A3oJHgrcJFZGzIpAw04kVJKg
```

## Android-Paket und Signatur

Paketname:

`de.jojosstudio.taskcard_hub_flutter`

Debug-SHA-256:

```powershell
keytool -list -v -alias androiddebugkey `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android -keypass android
```

Für eine veröffentlichte App muss zusätzlich der SHA-256-Fingerprint des
Release- beziehungsweise Play-App-Signing-Zertifikats in Clerk registriert
werden. Für Production werden der Production-Publishable-Key und die
Frontend API `clerk.jojosstudio.de` verwendet.
