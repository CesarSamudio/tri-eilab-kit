#!/usr/bin/env python3
"""
buzon.py - buzon de mensajes HTTP para que dos agentes de DSH se hablen.

Sirve en la red de Tailscale. Solo stdlib.

    python buzon.py --port 8787 --host 100.69.167.28 --token SECRETO

Endpoints:
    GET  /ping              -> "ok"   (sin token)
    POST /msg               -> guarda el cuerpo del mensaje en la bandeja
                               (header X-Token o ?token=)
    GET  /msg?token=...     -> devuelve los mensajes pendientes (no los borra)
    GET  /msg?token=...&clear=1  -> devuelve y borra

Formato de cada mensaje guardado (una linea JSON):
    {"ts": "...", "from": "quien", "text": "..."}
"""
import argparse
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

BASE = os.path.dirname(os.path.abspath(__file__))
Bandeja = os.path.join(BASE, "buzon-mensajes.jsonl")
TOKEN = ""


def guardar(texto, remitente="desconocido"):
    reg = {"ts": time.strftime("%Y-%m-%d %H:%M:%S"), "from": remitente, "text": texto}
    with open(Bandeja, "a", encoding="utf-8") as f:
        f.write(json.dumps(reg, ensure_ascii=False) + "\n")
    return reg


def leer(limite=100):
    if not os.path.exists(Bandeja):
        return []
    out = []
    with open(Bandeja, encoding="utf-8") as f:
        for linea in f:
            linea = linea.strip()
            if linea:
                try:
                    out.append(json.loads(linea))
                except Exception:
                    out.append({"ts": "?", "from": "?", "text": linea})
    return out[-limite:]


def borrar():
    if os.path.exists(Bandeja):
        os.remove(Bandeja)


class Handler(BaseHTTPRequestHandler):
    server_version = "buzon/1.0"

    def _token_ok(self):
        if not TOKEN:
            return True
        dado = self.headers.get("X-Token", "")
        if not dado:
            from urllib.parse import urlparse, parse_qs
            q = parse_qs(urlparse(self.path).query)
            dado = (q.get("token") or [""])[0]
        return dado == TOKEN

    def _responder(self, codigo, cuerpo, ctype="text/plain; charset=utf-8"):
        b = cuerpo.encode("utf-8") if isinstance(cuerpo, str) else cuerpo
        self.send_response(codigo)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)

    def do_GET(self):
        from urllib.parse import urlparse, parse_qs
        u = urlparse(self.path)
        if u.path == "/ping":
            return self._responder(200, "ok")
        if u.path == "/msg":
            if not self._token_ok():
                return self._responder(403, "token invalido")
            q = parse_qs(u.query)
            if (q.get("clear") or ["0"])[0] in ("1", "true", "si"):
                datos = leer()
                borrar()
            else:
                datos = leer()
            return self._responder(200, json.dumps(datos, ensure_ascii=False, indent=1),
                                   "application/json; charset=utf-8")
        return self._responder(404, "no encontrado")

    def do_POST(self):
        from urllib.parse import urlparse
        u = urlparse(self.path)
        if u.path != "/msg":
            return self._responder(404, "no encontrado")
        if not self._token_ok():
            return self._responder(403, "token invalido")
        largo = int(self.headers.get("Content-Length", 0))
        crudo = self.rfile.read(largo).decode("utf-8", "replace")
        remitente = self.headers.get("X-From", "desconocido")
        try:
            datos = json.loads(crudo)
            texto = datos.get("text", crudo)
            remitente = datos.get("from", remitente)
        except Exception:
            texto = crudo
        reg = guardar(texto, remitente)
        print("[buzon] recibido de %s: %s" % (remitente, texto[:120]), flush=True)
        return self._responder(200, json.dumps({"ok": True, "recibido": reg}, ensure_ascii=False),
                               "application/json; charset=utf-8")

    def log_message(self, fmt, *args):
        pass


def main():
    global TOKEN
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8787)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--token", default=os.environ.get("BUZON_TOKEN", ""))
    ap.add_argument("--remitente", default="pc-casa")
    args = ap.parse_args()
    TOKEN = args.token
    if not TOKEN:
        print("AVISO: sin token. Cualquiera de la red puede escribir.", file=sys.stderr)
    srv = ThreadingHTTPServer((args.host, args.port), Handler)
    print("[buzon] escuchando en http://%s:%d  (remitente=%s)" % (args.host, args.port, args.remitente), flush=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
