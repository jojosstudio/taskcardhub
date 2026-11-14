# Taskcard Hub

Eine zentrale, durchsuchbare Taskcard-Datenbank mit Clerk-Login, Admin-Freigaben und Prisma/MySQL.

## Lokal starten

1. Abhängigkeiten installieren: `npm install`
2. `.env.example` nach `.env.local` kopieren und die Clerk-Schlüssel aus dem Clerk Dashboard eintragen.
3. `DATABASE_URL` auf deine MySQL-Datenbank setzen.
4. Im Clerk Dashboard unter **User & Authentication > Users** einen Benutzer öffnen und unter **Public metadata** folgendes eintragen:
   ```json
   { "role": "admin" }
   ```
   Alternativ wird `{ "isAdmin": true }` unterstützt.
   Zusätzlich kann `ADMIN_EMAILS` in `.env.local` verwendet werden. Die aktuelle Alpha-Konfiguration berücksichtigt `juliensperling79@gmail.com`.
5. Datenbank anlegen: `npm run db:push`
6. Optional Beispieldaten einfügen: `npm run db:seed`
7. Entwicklungsserver starten: `npm run dev`

## Serverbetrieb

Nach dem Build kann die App mit einem einzigen Node-Befehl auf allen Interfaces und Port 1044 gestartet werden:

```bash
npm run build
node index.js
```

Die App ist dann unter `http://SERVER-IP:1044` erreichbar. Der Server muss Port 1044 in der Firewall freigeben. Die Oberfläche ist responsive und kann auf unterstützten Geräten über „Zum Startbildschirm hinzufügen“ als Web-App installiert werden.

Admins können Taskcards bestätigen, löschen und eingehende Meldungen bearbeiten. Nutzer können fehlerhafte oder problematische Taskcards mit Grund und Nachricht melden. Weitere Admin-E-Mails können einfach in [config/admins.ts](./config/admins.ts) ergänzt werden. Die Adminberechtigung kommt aus Clerk Public Metadata oder dieser Datei. Nicht bestätigte Links zeigen vor dem Öffnen eine Warnung. Lehrkräfte werden beim Anlegen als Komma-getrennte Namen eingetragen und in der Datenbank dedupliziert.

Admins wechseln über `/admin` in das getrennte Dashboard. Dort werden Seitenaufrufe, aktive Nutzer, externe Link-Öffnungen, offene Meldungen und die meistgenutzten Taskcards der letzten 30 Tage angezeigt.
