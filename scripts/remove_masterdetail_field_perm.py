import re, os, glob

PROFILES_DIR = r"c:\- DESARROLLOS\SALESFORCE\ProyectoOllin2026\force-app\main\default\profiles"

# MasterDetail fields must not appear in profile fieldPermissions
fields_to_remove = {"ejecutivocontacto__c.institucion__c"}

FP_RE = re.compile(
    r'\s*<fieldPermissions>\s*'
    r'<editable>(.*?)</editable>\s*'
    r'<field>(.*?)</field>\s*'
    r'<readable>(.*?)</readable>\s*'
    r'</fieldPermissions>',
    re.DOTALL
)

updated = 0
for path in glob.glob(os.path.join(PROFILES_DIR, "*.profile-meta.xml")):
    with open(path, encoding="utf-8") as f:
        content = f.read()

    def should_remove(m):
        return m.group(2).strip().lower() in fields_to_remove

    if not any(should_remove(m) for m in FP_RE.finditer(content)):
        continue

    new_content = FP_RE.sub(lambda m: "" if should_remove(m) else m.group(0), content)
    with open(path, "w", encoding="utf-8") as f:
        f.write(new_content)
    updated += 1

print(f"Profiles actualizados: {updated}")
