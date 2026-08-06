version VERSION:
    #!/usr/bin/env uv run python
    import re
    from pathlib import Path

    version = "{{VERSION}}"
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise SystemExit("version must use the X.Y.Z format")

    root = Path.cwd()
    files = {
        root / ".github/plugin/marketplace.json": 2,
        root / "plugins/copilot-goal-skill/.github/plugin/plugin.json": 1,
    }
    pattern = re.compile(r'("version"\s*:\s*")[^"]+(")')

    replacements = {}
    for path, expected_count in files.items():
        content = path.read_text()
        updated, count = pattern.subn(rf"\g<1>{version}\g<2>", content)
        if count != expected_count:
            raise SystemExit(
                f"expected {expected_count} version fields in {path}, found {count}"
            )
        replacements[path] = updated

    for path, content in replacements.items():
        path.write_text(content)

    print(f"Updated plugin manifests to version {version}")
