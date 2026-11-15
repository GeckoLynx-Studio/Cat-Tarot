#!/usr/bin/env python3
"""Cross-platform asset bundle tool for one game repo.

Works on Linux, macOS and Windows (Python 3.8+, standard library only).

Layout it manages inside a game repo:
    assets/            raw assets (git-ignored, the source of truth)
    assets.tar.gz      deterministic bundle for Unix/macOS (git-ignored; on a Release)
    assets.zip         deterministic bundle for Windows (git-ignored; on a Release)
    assets.sha256      content hash of assets/ (committed; proves a bundle is current)

Commands (run inside the game repo, or pass --root):
    pack     build assets.tar.gz + assets.zip and refresh assets.sha256
    stamp    refresh assets.sha256 only (no bundle)
    check    exit 1 if assets/ drifted from assets.sha256 (no assets/ -> skip, exit 0)
    fetch    restore assets/ from a local bundle or the GitHub Release
    push     pack, then upload both bundles to the game's GitHub Release
    status   show hash / stamp / bundle state

Both archive formats carry identical content and are validated by the same
assets.sha256; users pick whichever their OS opens natively. Bundles are
published to the GitHub Release tagged `assets` (override with --tag).
No Git LFS is used anywhere.
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path
from typing import Iterable, Optional

ASSETS_DIRNAME = "assets"
BUNDLE_TGZ = "assets.tar.gz"
BUNDLE_ZIP = "assets.zip"
BUNDLE_NAMES = (BUNDLE_TGZ, BUNDLE_ZIP)
STAMP_NAME = "assets.sha256"
DEFAULT_TAG = os.environ.get("ASSETS_TAG", "assets")

# Fixed ZIP timestamp (1980-01-01) so the archive is byte-for-byte reproducible.
ZIP_EPOCH = (1980, 1, 1, 0, 0, 0)

# Files that Godot / the OS regenerate and that must not affect the stamp.
IGNORE_NAMES = {".DS_Store", "Thumbs.db", "desktop.ini"}
IGNORE_SUFFIXES = (".import", ".tmp", ".swp", "~")


def die(msg: str, code: int = 1) -> "NoReturn":  # type: ignore[name-defined]
    print(f"error: {msg}", file=sys.stderr)
    raise SystemExit(code)


def info(msg: str) -> None:
    print(f"  {msg}")


def human(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1024 or unit == "GB":
            return f"{n:.1f} {unit}" if unit != "B" else f"{n} B"
        n /= 1024.0
    return f"{n:.1f} GB"


def is_ignored(rel: str) -> bool:
    name = rel.rsplit("/", 1)[-1]
    return name in IGNORE_NAMES or rel.endswith(IGNORE_SUFFIXES)


def iter_files(assets_dir: Path) -> Iterable[tuple[str, Path]]:
    """Yield (posix-relpath, absolute-path) in a deterministic order."""
    for dirpath, dirnames, filenames in os.walk(assets_dir):
        dirnames[:] = sorted(d for d in dirnames if d != ".git")
        for fn in sorted(filenames):
            p = Path(dirpath) / fn
            if not p.is_file():
                continue
            rel = p.relative_to(assets_dir).as_posix()
            if is_ignored(rel):
                continue
            yield rel, p


def hash_assets(assets_dir: Path) -> str:
    h = hashlib.sha256()
    for rel, p in iter_files(assets_dir):
        h.update(b"f\0")
        h.update(rel.encode("utf-8"))
        h.update(b"\0")
        h.update(str(p.stat().st_size).encode("ascii"))
        h.update(b"\0")
        with p.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b""):
                h.update(chunk)
    return h.hexdigest()


def write_stamp(root: Path, value: str) -> None:
    (root / STAMP_NAME).write_text(value + "\n", encoding="ascii")


def read_stamp(root: Path) -> Optional[str]:
    p = root / STAMP_NAME
    if not p.is_file():
        return None
    return p.read_text(encoding="ascii").strip() or None


def _bundle_dirs(files: list[tuple[str, Path]]) -> list[str]:
    dirs: set[str] = set()
    for rel, _ in files:
        parts = rel.split("/")[:-1]
        for i in range(1, len(parts) + 1):
            dirs.add("/".join(parts[:i]))
    return sorted(dirs)


def build_targz(root: Path, files: list[tuple[str, Path]]) -> Path:
    bundle = root / BUNDLE_TGZ
    tmp = bundle.with_name(bundle.name + ".tmp")
    with tmp.open("wb") as raw, gzip.GzipFile(
        filename="", mode="wb", fileobj=raw, mtime=0, compresslevel=9
    ) as gz:
        with tarfile.open(fileobj=gz, mode="w", format=tarfile.PAX_FORMAT) as tar:
            for d in _bundle_dirs(files):
                ti = tarfile.TarInfo(f"{ASSETS_DIRNAME}/{d}")
                ti.type = tarfile.DIRTYPE
                ti.mode = 0o755
                ti.mtime = 0
                ti.uid = ti.gid = 0
                ti.uname = ti.gname = ""
                tar.addfile(ti)
            for rel, p in files:
                ti = tarfile.TarInfo(f"{ASSETS_DIRNAME}/{rel}")
                ti.size = p.stat().st_size
                ti.mode = 0o644
                ti.mtime = 0
                ti.type = tarfile.REGTYPE
                ti.uid = ti.gid = 0
                ti.uname = ti.gname = ""
                with p.open("rb") as fh:
                    tar.addfile(ti, fh)
    os.replace(tmp, bundle)
    return bundle


def build_zip(root: Path, files: list[tuple[str, Path]]) -> Path:
    bundle = root / BUNDLE_ZIP
    tmp = bundle.with_name(bundle.name + ".tmp")
    with zipfile.ZipFile(tmp, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for d in _bundle_dirs(files):
            zi = zipfile.ZipInfo(f"{ASSETS_DIRNAME}/{d}/", date_time=ZIP_EPOCH)
            zi.create_system = 3  # Unix, so external_attr is honoured by unzip
            zi.external_attr = (0o40755 << 16) | 0x10
            z.writestr(zi, b"")
        for rel, p in files:
            zi = zipfile.ZipInfo(f"{ASSETS_DIRNAME}/{rel}", date_time=ZIP_EPOCH)
            zi.create_system = 3
            zi.external_attr = 0o100644 << 16
            zi.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(zi, p.read_bytes())
    os.replace(tmp, bundle)
    return bundle


def build_bundles(root: Path) -> list[Path]:
    assets = root / ASSETS_DIRNAME
    if not assets.is_dir():
        die(f"{assets} not found (nothing to pack)")
    files = list(iter_files(assets))
    return [build_targz(root, files), build_zip(root, files)]


def _reset_assets(root: Path) -> None:
    assets = root / ASSETS_DIRNAME
    if assets.exists():
        shutil.rmtree(assets)


def _safe_member(root: Path, name: str) -> Path:
    target = (root / name).resolve()
    if not str(target).startswith(str(root.resolve()) + os.sep):
        die(f"refusing unsafe path in bundle: {name}")
    return target


def extract_bundle(root: Path, bundle: Path) -> None:
    _reset_assets(root)
    if zipfile.is_zipfile(bundle):
        with zipfile.ZipFile(bundle) as z:
            for name in z.namelist():
                _safe_member(root, name)
            z.extractall(root)
        return
    with tarfile.open(bundle, "r:gz") as tar:
        for m in tar.getmembers():
            _safe_member(root, m.name)
        if hasattr(tarfile, "data_filter"):
            tar.extractall(root, filter="data")  # Python 3.12+
        else:
            tar.extractall(root)


def try_github_slug(root: Path) -> Optional[str]:
    try:
        url = subprocess.check_output(
            ["git", "-C", str(root), "remote", "get-url", "origin"],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    m = re.search(r"github\.com[:/]+([^/]+)/([^/]+?)(?:\.git)?/?$", url)
    return f"{m.group(1)}/{m.group(2)}" if m else None


def github_slug(root: Path) -> str:
    slug = try_github_slug(root)
    if slug is None:
        die("no GitHub 'origin' remote (add one to publish/fetch bundles)")
    return slug


def have_gh() -> bool:
    return shutil.which("gh") is not None


# --------------------------------------------------------------------------- commands


def cmd_pack(root: Path, tag: str, quiet: bool) -> int:
    value = hash_assets(root / ASSETS_DIRNAME)
    bundles = build_bundles(root)
    write_stamp(root, value)
    if not quiet:
        n = sum(1 for _ in iter_files(root / ASSETS_DIRNAME))
        sizes = ", ".join(f"{b.name} {human(b.stat().st_size)}" for b in bundles)
        info(f"packed {n} files -> {sizes}")
        info(f"stamp  {value}")
    return 0


def cmd_stamp(root: Path, quiet: bool) -> int:
    value = hash_assets(root / ASSETS_DIRNAME)
    write_stamp(root, value)
    if not quiet:
        info(f"stamp {value}")
    return 0


def cmd_check(root: Path, quiet: bool, strict: bool) -> int:
    assets = root / ASSETS_DIRNAME
    if not assets.is_dir():
        if strict:
            die(f"{assets} not found; run tools/fetch-assets.sh")
        if not quiet:
            info("assets/ not present - skipping stamp check")
        return 0
    saved = read_stamp(root)
    if saved is None:
        print("", file=sys.stderr)
        print(f"error: {STAMP_NAME} is missing.", file=sys.stderr)
        print("  run: tools/pack-assets.sh  (then commit assets.sha256)", file=sys.stderr)
        return 1
    current = hash_assets(assets)
    if current != saved:
        print("", file=sys.stderr)
        print("error: assets/ changed but assets.sha256 is stale.", file=sys.stderr)
        print(f"  stamp:   {saved}", file=sys.stderr)
        print(f"  current: {current}", file=sys.stderr)
        print("  run: tools/pack-assets.sh && tools/push-assets.sh", file=sys.stderr)
        print("  then commit the updated assets.sha256", file=sys.stderr)
        return 1
    if not quiet:
        info("assets/ matches assets.sha256")
    return 0


def _preferred_names(fmt: str) -> list[str]:
    if fmt == "zip":
        return [BUNDLE_ZIP]
    if fmt == "tar":
        return [BUNDLE_TGZ]
    # auto: on Windows zip opens natively, elsewhere tar.gz is smaller/faster
    return [BUNDLE_ZIP, BUNDLE_TGZ] if os.name == "nt" else [BUNDLE_TGZ, BUNDLE_ZIP]


def _download_via_gh(root: Path, tag: str, dest_dir: Path, name: str) -> Optional[Path]:
    slug = github_slug(root)
    out = dest_dir / name
    r = subprocess.run(
        ["gh", "release", "download", tag, "-R", slug, "-p", name, "--clobber", "-D", str(dest_dir)],
        text=True,
    )
    return out if r.returncode == 0 and out.is_file() else None


def _download_via_http(root: Path, tag: str, dest_dir: Path, name: str) -> Optional[Path]:
    import urllib.request

    slug = github_slug(root)
    url = f"https://github.com/{slug}/releases/download/{tag}/{name}"
    out = dest_dir / name
    try:
        with urllib.request.urlopen(url) as resp, out.open("wb") as fh:
            shutil.copyfileobj(resp, fh)
        return out
    except Exception as exc:  # noqa: BLE001 - network errors are all equivalent here
        print(f"  download failed ({name}): {exc}", file=sys.stderr)
        return None


def _download(root: Path, tag: str, dest_dir: Path, fmt: str) -> Optional[Path]:
    for name in _preferred_names(fmt):
        got = None
        if have_gh():
            got = _download_via_gh(root, tag, dest_dir, name)
        if got is None:
            got = _download_via_http(root, tag, dest_dir, name)
        if got is not None:
            return got
    return None


def cmd_fetch(root: Path, tag: str, force: bool, quiet: bool, fmt: str) -> int:
    assets = root / ASSETS_DIRNAME
    saved = read_stamp(root)
    if assets.is_dir() and saved and not force:
        if hash_assets(assets) == saved:
            if not quiet:
                info("assets/ already up to date")
            return 0

    local = next((root / n for n in _preferred_names(fmt) if (root / n).is_file()), None)
    if local is not None and not force:
        src = local
        if not quiet:
            info(f"using local {src.name} ({human(src.stat().st_size)})")
    else:
        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            got = _download(root, tag, td_path, fmt)
            if got is None:
                names = ", ".join(_preferred_names(fmt))
                die(f"could not download {names} from release '{tag}'")
            # keep both formats local for future offline fetches
            for n in BUNDLE_NAMES:
                if (td_path / n).is_file():
                    shutil.copyfile(td_path / n, root / n)
            src = root / got.name
            if not quiet:
                info(f"downloaded {got.name} ({human(src.stat().st_size)})")

    extract_bundle(root, src)
    if saved:
        current = hash_assets(assets)
        if current != saved:
            print(f"warning: extracted assets do not match {STAMP_NAME}", file=sys.stderr)
            print(f"  stamp:   {saved}", file=sys.stderr)
            print(f"  current: {current}", file=sys.stderr)
            return 1
    if not quiet:
        info("assets/ restored")
    return 0


def cmd_push(root: Path, tag: str, quiet: bool, skip_pack: bool) -> int:
    if not have_gh():
        die("gh CLI not found; install https://cli.github.com to publish bundles")
    if not skip_pack:
        cmd_pack(root, tag, quiet)
    bundles = [root / n for n in BUNDLE_NAMES if (root / n).is_file()]
    if not bundles:
        die(f"no bundles found; run pack first")
    slug = github_slug(root)
    view = subprocess.run(
        ["gh", "release", "view", tag, "-R", slug], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    if view.returncode != 0:
        if not quiet:
            info(f"creating release '{tag}' on {slug}")
        subprocess.run(
            ["gh", "release", "create", tag, "-R", slug, "--title", "Game assets",
             "--notes", "Asset bundle. Managed by tools/assets.py; do not edit by hand."],
            check=True,
        )
    subprocess.run(
        ["gh", "release", "upload", tag, *[str(b) for b in bundles], "--clobber", "-R", slug],
        check=True,
    )
    if not quiet:
        sizes = ", ".join(f"{b.name} {human(b.stat().st_size)}" for b in bundles)
        info(f"uploaded {sizes} -> {slug} release '{tag}'")
    return 0


def cmd_status(root: Path, tag: str) -> int:
    assets = root / ASSETS_DIRNAME
    stamp = read_stamp(root)
    present = assets.is_dir()
    current = hash_assets(assets) if present else None
    print(f"root:    {root}")
    print(f"assets:  {'present' if present else 'missing'}")
    if present:
        n = sum(1 for _ in iter_files(assets))
        sz = sum(p.stat().st_size for _, p in iter_files(assets))
        print(f"         {n} files, {human(sz)}")
    print(f"stamp:   {stamp or '(none)'}")
    print(f"current: {current or '(n/a)'}")
    for n in BUNDLE_NAMES:
        b = root / n
        print(f"{n + ':':<12}{'present ' + human(b.stat().st_size) if b.is_file() else 'missing'}")
    synced = bool(present and stamp and current == stamp)
    print(f"synced:  {'yes' if synced else 'NO'}")
    slug = try_github_slug(root)
    print(f"remote:  {slug + ' (tag ' + tag + ')' if slug else '(none)'}")
    return 0 if synced or not present else 1


def main(argv: Optional[list[str]] = None) -> int:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("-q", "--quiet", action="store_true", default=argparse.SUPPRESS,
                        help="only report errors")

    ap = argparse.ArgumentParser(description="Asset bundle tool for a single game repo.")
    ap.add_argument("--root", default=".", help="game repo root (default: current directory)")
    ap.add_argument("--tag", default=DEFAULT_TAG, help=f"release tag (default: {DEFAULT_TAG})")
    ap.add_argument("-q", "--quiet", action="store_true", help="only report errors")
    sub = ap.add_subparsers(dest="cmd", required=True)

    sub.add_parser("pack", parents=[common], help="build assets.tar.gz + assets.zip and refresh assets.sha256")
    sub.add_parser("stamp", parents=[common], help="refresh assets.sha256 only")
    p_check = sub.add_parser("check", parents=[common], help="fail if assets/ drifted from assets.sha256")
    p_check.add_argument("--strict", action="store_true", help="fail when assets/ is missing")
    p_fetch = sub.add_parser("fetch", parents=[common], help="restore assets/ from bundle or Release")
    p_fetch.add_argument("--force", action="store_true", help="re-download / re-extract even if current")
    p_fetch.add_argument(
        "--format", choices=("auto", "tar", "zip"), default="auto",
        help="preferred archive format (default: auto = zip on Windows, tar.gz elsewhere)",
    )
    p_push = sub.add_parser("push", parents=[common], help="pack and upload both bundles to the GitHub Release")
    p_push.add_argument("--no-pack", action="store_true", help="upload the existing bundle as-is")
    sub.add_parser("status", parents=[common], help="show sync state")

    args = ap.parse_args(argv)
    root = Path(args.root).resolve()
    if not (root / "project.godot").is_file() and not (root / ASSETS_DIRNAME).is_dir():
        die(f"{root} does not look like a game repo (no project.godot / assets/)")

    if args.cmd == "pack":
        return cmd_pack(root, args.tag, args.quiet)
    if args.cmd == "stamp":
        return cmd_stamp(root, args.quiet)
    if args.cmd == "check":
        return cmd_check(root, args.quiet, args.strict)
    if args.cmd == "fetch":
        return cmd_fetch(root, args.tag, args.force, args.quiet, args.format)
    if args.cmd == "push":
        return cmd_push(root, args.tag, args.quiet, args.no_pack)
    if args.cmd == "status":
        return cmd_status(root, args.tag)
    die(f"unknown command {args.cmd}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
