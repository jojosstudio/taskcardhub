Übergabe für den externen Server
=================================

Vorhandene Dateien im Übergabeordner wurden gelöscht und durch diese aktuellen Dateien ersetzt:

mobile-server-patch\app\page.tsx -> app/page.tsx
mobile-server-patch\app\globals.css -> app/globals.css
mobile-server-patch\app\api\taskcards\route.ts -> app/api/taskcards/route.ts

Die Erstelleranzeige verwendet jetzt Clerk username/fullName/firstName und zeigt keine E-Mail-Adresse an.
Bereits gespeicherte E-Mail-Anzeigen werden als „Unbekannter Nutzer“ dargestellt.

Nach dem Kopieren im Server-Container:
  npm run build
  node index.js
