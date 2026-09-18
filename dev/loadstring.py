#!/usr/bin/env python3
"""Print and optionally copy a local script URL/loadstring to the clipboard."""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


def copy_clipboard(text: str) -> bool:
    # macOS
    if shutil.which("pbcopy"):
        subprocess.run(["pbcopy"], input=text, text=True, check=True)
        return True

    # Windows
    if shutil.which("clip"):
        subprocess.run(["clip"], input=text, text=True, check=True)
        return True

    # Linux: xclip / xsel
    if shutil.which("xclip"):
        subprocess.run(
            ["xclip", "-selection", "clipboard"],
            input=text,
            text=True,
            check=True,
        )
        return True

    if shutil.which("xsel"):
        subprocess.run(
            ["xsel", "--clipboard", "--input"],
            input=text,
            text=True,
            check=True,
        )
        return True

    return False


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("script", help="Path relative to the src/ directory")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument(
        "--template",
        default='loadstring(game:HttpGet("{url}"))()',
        help="Snippet template. Use {url} where the URL goes.",
    )
    args = parser.parse_args()

    rel_path = Path(args.script)
    rel = rel_path.as_posix().lstrip("/")
    if rel.startswith("src/"):
        rel = rel[len("src/"):]
    url = f"http://{args.host}:{args.port}/{rel}"
    snippet = args.template.format(url=url)
    print(snippet)

    if copy_clipboard(snippet):
        print("\nCopied to clipboard.")
    else:
        print(
            "\nClipboard command not found. "
            "Install xclip/xsel on Linux or copy the printed line manually."
        )


if __name__ == "__main__":
    main()
