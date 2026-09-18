#!/usr/bin/env python3
"""Local server for development & testing."""

from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent / "src"


class RawScriptHandler(SimpleHTTPRequestHandler):
    def guess_type(self, path: str) -> str:
        return "text/plain; charset=utf-8"

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    ROOT.mkdir(exist_ok=True)

    handler = partial(RawScriptHandler, directory=str(ROOT))
    server = ThreadingHTTPServer((args.host, args.port), handler)

    print(f"Serving: {ROOT}")
    print(f"URL: http://{args.host}:{args.port}/")
    print("Press Ctrl+C to stop.")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
