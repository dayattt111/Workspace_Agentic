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

// Kode Warna ANSI Terminal (Emas, Tulang, & Hijau)
const GOLD = "\x1b[38;5;220m";
const BONE = "\x1b[38;5;254m";
const GRAY = "\x1b[38;5;244m";
const GREEN = "\x1b[38;5;114m";
const RESET = "\x1b[0m";

console.log(`
${GOLD}           .@@@@@@.
         @%  @@@@  %@        @@
      @*   #@@@*=+%@:  -@   @*#@
     @ .@@@@@+ :++    .  #@#- .@
    %* +@@@# -*    *@@@@@@-  %@
     * :@@.=     *@:   *%  -%* #@
 @:  @@@==     +@:  -*   -   +@
 * @@@@%=     =@   *        +@@
 * @@@@#     :@   #       :=+#%
  # @@@:      @@. #  .-+%%+
   % @@*.      %@# *#   .*:  :+
  @ +@@@@=       =@@@%@@@%-*@
    %  *@*::           +#
      *#  *@@@@%+=.
            **++**${RESET}

    ${BONE}\x1b[1mG a s k e n L E${RESET} ${GRAY}— workspace —${RESET}
    ${GRAY}Made by Hikaruu (Muhammad Amin Hidayat)${RESET}

  ${GREEN}⚡ GaskenLE Docs aktif di:${RESET} ${BONE}http://localhost:${server.port}${RESET}
  ${GRAY}Tekan Ctrl + C untuk mematikan server.${RESET}
`);
