const next = require("next");
const http = require("http");

const port = Number(process.env.PORT || 1044);
const hostname = process.env.BIND_HOST || "0.0.0.0";
const app = next({ dev: false, hostname, port });
const handle = app.getRequestHandler();

app.prepare()
  .then(() => {
    http.createServer((request, response) => handle(request, response)).listen(port, hostname, () => {
      console.log(`Taskcard Hub läuft auf http://${hostname}:${port}`);
    });
  })
  .catch((error) => {
    console.error("Taskcard Hub konnte nicht gestartet werden:", error);
    process.exit(1);
  });
