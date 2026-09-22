const PORT = Number(process.env.PORT) || 3999;

const server = Bun.serve({
  port: PORT,
  async fetch(req) {
    const url = new URL(req.url);
    let filePath = decodeURIComponent(url.pathname);

    if (filePath === "/" || filePath === "") {
      filePath = "/index.html";
    }

    const file = Bun.file(import.meta.dir + filePath);
    if (await file.exists()) {
      return new Response(file);
    }

    // Docsify SPA fallback for client-side routing
    const indexFile = Bun.file(import.meta.dir + "/index.html");
    if (await indexFile.exists()) {
      return new Response(indexFile);
    }

    return new Response("Not Found", { status: 404 });
  },
});

console.log(`\n⚡ Gaskenle Docs aktif di: http://localhost:${server.port}`);
console.log(`Tekan Ctrl + C untuk mematikan server.\n`);
