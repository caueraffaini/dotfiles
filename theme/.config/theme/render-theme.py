#!/usr/bin/env python3
"""
render-theme.py — Gruvbox Material Dark Design System Compiler.
Single Source of Truth (SSoT) engine compiling palette.json into *.template files.
"""

import argparse
import json
import os
import re
import sys
import tempfile
import time


def find_repo_root():
    """Find repository root by walking up from this script's directory."""
    current = os.path.dirname(os.path.abspath(__file__))
    while current != os.path.dirname(current):
        if os.path.isdir(os.path.join(current, ".git")) or os.path.isfile(os.path.join(current, "install.sh")):
            return current
        current = os.path.dirname(current)
    # Default fallback
    home_repo = os.path.expanduser("~/dotfiles")
    if os.path.isdir(home_repo):
        return home_repo
    return os.path.dirname(os.path.abspath(__file__))


def hex_to_rgb(hex_str):
    """Convert #RRGGBB hex string to (R, G, B) tuple."""
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 3:
        hex_str = "".join([c * 2 for c in hex_str])
    return tuple(int(hex_str[i:i + 2], 16) for i in (0, 2, 4))


def load_palette(palette_path):
    """Load JSON color palette from path."""
    if not os.path.isfile(palette_path):
        print(f"error: palette file not found at {palette_path}", file=sys.stderr)
        sys.exit(1)
    with open(palette_path, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except json.JSONDecodeError as e:
            print(f"error: invalid JSON in palette {palette_path}: {e}", file=sys.stderr)
            sys.exit(1)


def generate_replacements(palette):
    """Generate all token substitution variants (hex, raw hex, rgb string, components)."""
    repls = {}
    for name, hex_val in palette.items():
        if not isinstance(hex_val, str) or not hex_val.startswith("#"):
            continue
        h = hex_val.lstrip("#")
        r, g, b = hex_to_rgb(hex_val)

        # Standard hex: #282828
        repls[name] = hex_val
        # Raw hex: 282828
        repls[f"{name}_hex"] = h
        # RGB string: 40, 40, 40
        repls[f"{name}_rgb"] = f"{r}, {g}, {b}"
        # Individual components
        repls[f"{name}_r"] = str(r)
        repls[f"{name}_g"] = str(g)
        repls[f"{name}_b"] = str(b)

    return repls


def discover_templates(repo_root):
    """Find all *.template files across the repository."""
    templates = []
    for root, dirs, files in os.walk(repo_root):
        # Exclude .git and cache dirs
        if ".git" in dirs:
            dirs.remove(".git")
        if "__pycache__" in dirs:
            dirs.remove("__pycache__")
        for f in sorted(files):
            if f.endswith(".template"):
                t_path = os.path.join(root, f)
                o_path = t_path[:-9]  # Remove .template suffix
                templates.append((t_path, o_path))
    return sorted(templates, key=lambda x: x[0])


def validate_template(template_path, repls):
    """
    Validate that all placeholder tokens in template_path exist in repls.
    Returns (is_valid, list_of_errors).
    """
    with open(template_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    errors = []
    for line_num, line in enumerate(lines, start=1):
        matches = re.finditer(r"\{\{([a-zA-Z0-9_-]+)\}\}", line)
        for m in matches:
            token = m.group(1)
            if token not in repls:
                errors.append((line_num, token))

    return (len(errors) == 0, errors)


def render_template_content(content, repls):
    """Perform regex token substitution on content string."""
    def replace_match(match):
        key = match.group(1)
        return repls[key]

    return re.sub(r"\{\{([a-zA-Z0-9_-]+)\}\}", replace_match, content)


def render_file_atomic(template_path, output_path, repls, check_mode=False, quiet=False):
    """Render a single template to output file with atomic write."""
    with open(template_path, "r", encoding="utf-8") as f:
        content = f.read()

    new_content = render_template_content(content, repls)

    if check_mode:
        if os.path.isfile(output_path):
            with open(output_path, "r", encoding="utf-8") as f:
                current_content = f.read()
            if current_content != new_content:
                if not quiet:
                    print(f"  [out-of-sync] {output_path}")
                return False
            else:
                if not quiet:
                    print(f"  [up-to-date]  {output_path}")
                return True
        else:
            if not quiet:
                print(f"  [missing]     {output_path}")
            return False

    # Atomic write: write to temp file in same directory then os.replace
    out_dir = os.path.dirname(output_path)
    os.makedirs(out_dir, exist_ok=True)

    tmp_file = tempfile.NamedTemporaryFile("w", dir=out_dir, delete=False, encoding="utf-8")
    try:
        tmp_file.write(new_content)
        tmp_file.flush()
        os.fsync(tmp_file.fileno())
        tmp_file.close()
        os.replace(tmp_file.name, output_path)
        os.chmod(output_path, 0o644)
    except Exception as e:
        if os.path.exists(tmp_file.name):
            os.unlink(tmp_file.name)
        raise e

    if not quiet:
        print(f"  [rendered] {template_path} -> {output_path}")
    return True



def run_pipeline(repo_root, palette_path, check_mode=False, quiet=False):
    """Execute validation and rendering pipeline across all discovered templates."""
    palette = load_palette(palette_path)
    repls = generate_replacements(palette)
    templates = discover_templates(repo_root)

    if not templates:
        print("warning: no *.template files found in repository", file=sys.stderr)
        return 0

    all_valid = True
    total_tokens = 0
    validation_failures = 0

    # Step 1: Validation pass
    for t_path, _ in templates:
        is_valid, errors = validate_template(t_path, repls)
        if not is_valid:
            all_valid = False
            validation_failures += 1
            rel_t = os.path.relpath(t_path, repo_root)
            print(f"error: undefined token(s) in {rel_t}:", file=sys.stderr)
            for line_no, token in errors:
                print(f"  line {line_no}: {{{{{token}}}}} is not defined in palette.json", file=sys.stderr)

    if not all_valid:
        print(f"\nerror: {validation_failures} template(s) failed token validation.", file=sys.stderr)
        return 1

    # Step 2: Render or Check pass
    sync_issues = 0
    for t_path, o_path in templates:
        ok = render_file_atomic(t_path, o_path, repls, check_mode=check_mode, quiet=quiet)
        if not ok and check_mode:
            sync_issues += 1

    if check_mode:
        if sync_issues > 0:
            print(f"\ncheck: {sync_issues} target file(s) out-of-sync with templates.")
            return 2
        else:
            if not quiet:
                print(f"\ncheck: all {len(templates)} templates valid and synchronized.")
            return 0

    if not quiet:
        print(f"\nsuccess: rendered {len(templates)} templates atomically.")
    return 0


def main():
    parser = argparse.ArgumentParser(description="Gruvbox Material Dark Theme Compiler")
    parser.add_argument("-c", "--check", "--dry-run", dest="check", action="store_true",
                        help="Validate tokens and check sync status without writing files")
    parser.add_argument("-p", "--palette", dest="palette", default=None,
                        help="Path to palette.json file")
    parser.add_argument("-f", "--force", dest="force", action="store_true",
                        help="Force compilation of all templates")
    parser.add_argument("-r", "--reload", dest="reload", action="store_true",
                        help="Trigger live UI reload via sys-reload post compilation")
    parser.add_argument("-q", "--quiet", dest="quiet", action="store_true",
                        help="Suppress standard output")
    parser.add_argument("-w", "--watch", dest="watch", action="store_true",
                        help="Watch palette.json and *.template files for changes and re-render")

    args = parser.parse_args()

    repo_root = find_repo_root()
    palette_path = args.palette
    if not palette_path:
        default_repo_pal = os.path.join(repo_root, "theme", ".config", "theme", "palette.json")
        default_home_pal = os.path.expanduser("~/.config/theme/palette.json")
        if os.path.isfile(default_repo_pal):
            palette_path = default_repo_pal
        elif os.path.isfile(default_home_pal):
            palette_path = default_home_pal
        else:
            palette_path = default_repo_pal

    if args.watch:
        print(f"watching {palette_path} and templates for changes (Ctrl+C to stop)...")
        last_mtime = 0
        while True:
            try:
                current_mtime = os.path.getmtime(palette_path) if os.path.exists(palette_path) else 0
                if current_mtime != last_mtime:
                    last_mtime = current_mtime
                    run_pipeline(repo_root, palette_path, check_mode=False, quiet=args.quiet)
                    if args.reload:
                        os.system("sys-reload all 2>/dev/null || true")
                time.sleep(1)
            except KeyboardInterrupt:
                break
        return 0

    rc = run_pipeline(repo_root, palette_path, check_mode=args.check, quiet=args.quiet)

    if rc == 0 and args.reload and not args.check:
        os.system("sys-reload all 2>/dev/null || true")

    sys.exit(rc)


if __name__ == "__main__":
    main()
