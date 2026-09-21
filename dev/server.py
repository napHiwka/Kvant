#!/usr/bin/env python3

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


class Handler(SimpleHTTPRequestHandler):
    def guess_type(self, path: str) -> str:
        return "text/plain; charset=utf-8"

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> None:
    server = ThreadingHTTPServer(
        ("127.0.0.1", 6969),
        lambda *args, **kwargs: Handler(
            *args,
            directory=str(ROOT),
            **kwargs,
        ),
    )

    print(f"Serving: {ROOT}", flush=True)
    print("http://127.0.0.1:6969/", flush=True)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()