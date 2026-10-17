"""Check publishable source files; generated local outputs are excluded."""
from pathlib import Path
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
IGNORED = {".git", "outputs", "work", "__pycache__", "slprj"}
GENERATED_SUFFIXES = {".slxc", ".asv", ".m~", ".pyc"}
FORBIDDEN_PARTS = {"raw", "metadata", ".aws", ".ssh", ".codex", ".agents"}
PATTERNS = [
    ("personal Windows path", re.compile(r"[A-Za-z]:[\\/]+Users[\\/]+[^\\/\s]+", re.I)),
    ("private key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----")),
    ("access token", re.compile(r"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|AKIA[A-Z0-9]{16})")),
]


def source_files(root):
    if (root / ".git").exists():
        result = subprocess.run(["git", "-C", str(root), "ls-files", "-z"], check=True, capture_output=True)
        return [root / name for name in result.stdout.decode("utf-8").split("\0") if name]
    return [p for p in root.rglob("*") if p.is_file() and p.suffix.lower() not in GENERATED_SUFFIXES and not any(x in IGNORED for x in p.relative_to(root).parts)]


def inspect(root):
    errors = []
    files = source_files(root)
    for p in files:
        rel = p.relative_to(root)
        if p.suffix.lower() in GENERATED_SUFFIXES:
            errors.append(f"{rel}: generated cache is not public source")
            continue
        if p.is_symlink():
            errors.append(f"{rel}: symbolic links must be reviewed")
            continue
        if any(x.lower() in FORBIDDEN_PARTS for x in rel.parts) or p.name.startswith(".env"):
            errors.append(f"{rel}: private input or configuration path")
        if tuple(x.lower() for x in rel.parts[:2]) == ("data", "local") or rel.parts[0].lower() in {"outputs", "work"}:
            errors.append(f"{rel}: local user input must not be published")
        if p.suffix.lower() in {".docx", ".xlsx", ".pdf", ".slx", ".mat", ".zip"}:
            errors.append(f"{rel}: binary artifact is outside the public source package")
            continue
        if p.suffix.lower() == ".png":
            if rel.parts[:2] != ("docs", "images"):
                errors.append(f"{rel}: image must be in the reviewed screenshot directory")
            continue
        try:
            content = p.read_text(encoding="utf-8-sig")
        except UnicodeError:
            errors.append(f"{rel}: unreviewed binary or text encoding")
            continue
        for label, pattern in PATTERNS:
            if pattern.search(content):
                errors.append(f"{rel}: {label}")
    return files, errors


def main():
    files, errors = inspect(ROOT)
    print(json.dumps({"filesChecked": len(files), "errors": errors}, ensure_ascii=False, indent=2))
    raise SystemExit(bool(errors))


if __name__ == "__main__":
    main()
