#!/usr/bin/env python3

import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote


def copy_clipboard(text: str) -> bool:
    commands = (
        ["pbcopy"],
        ["clip"],
        ["xclip", "-selection", "clipboard"],
        ["xsel", "--clipboard", "--input"],
    )

    for command in commands:
        if not shutil.which(command[0]):
            continue

        try:
            subprocess.run(
                command,
                input=text,
                text=True,
                check=True,
            )
            return True
        except (OSError, subprocess.CalledProcessError):
            continue

    return False


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: loadstring.py <workspace-relative-file>")

    file = Path(sys.argv[1]).resolve()
    workspace = Path.cwd().resolve()

    try:
        relative = file.relative_to(workspace)
    except ValueError:
        raise SystemExit(f"File is outside workspace: {file}")

    if not file.is_file():
        raise SystemExit(f"File does not exist: {file}")

    url = (
        "http://127.0.0.1:6969/"
        + quote(relative.as_posix(), safe="/")
    )

    snippet = f'loadstring(game:HttpGet("{url}"))()'

    print(snippet)

    if copy_clipboard(snippet):
        print("\nCopied to clipboard.")


if __name__ == "__main__":
    main()