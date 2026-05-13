import re, os, glob

PROFILES_DIR = r"c:\- DESARROLLOS\SALESFORCE\ProyectoOllin2026\force-app\main\default\profiles"

FP_RE = re.compile(
    r'\s*<fieldPermissions>\s*'
    r'<editable>(.*?)</editable>\s*'
    r'<field>(.*?)</field>\s*'
    r'<readable>(.*?)</readable>\s*'
    r'</fieldPermissions>',
    re.DOTALL
)

fixed = 0
skipped = 0

for path in glob.glob(os.path.join(PROFILES_DIR, "*.profile-meta.xml")):
    with open(path, encoding="utf-8") as f:
        content = f.read()

    matches = list(FP_RE.finditer(content))
    if not matches:
        skipped += 1
        continue

    seen = {}
    for m in matches:
        editable = m.group(1).strip()
        field    = m.group(2).strip()
        readable = m.group(3).strip()
        key = field.lower()
        if key not in seen:
            seen[key] = (field, editable, readable)

    sorted_entries = sorted(seen.values(), key=lambda x: x[0].lower())

    new_blocks = ""
    for field, editable, readable in sorted_entries:
        new_blocks += (
            f"\n    <fieldPermissions>\n"
            f"        <editable>{editable}</editable>\n"
            f"        <field>{field}</field>\n"
            f"        <readable>{readable}</readable>\n"
            f"    </fieldPermissions>"
        )

    stripped = FP_RE.sub("", content)

    if "</Profile>" not in stripped:
        print(f"SKIP (no </Profile>): {os.path.basename(path)}")
        skipped += 1
        continue

    new_content = stripped.replace("</Profile>", new_blocks + "\n</Profile>", 1)

    with open(path, "w", encoding="utf-8") as f:
        f.write(new_content)

    fixed += 1
    print(f"OK  {os.path.basename(path)}  ({len(sorted_entries)} permisos)")

print(f"\nFixed: {fixed}  |  Skipped: {skipped}")
