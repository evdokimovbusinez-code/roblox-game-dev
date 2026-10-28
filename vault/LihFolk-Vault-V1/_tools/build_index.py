"""Write VAULT_INDEX.md at the vault root: one line per note (title, path, tags, first sentence),
grouped by section, so an AI agent can skim or grep the whole vault in one read.
Usage: py build_index.py <vault folder>"""
import os, re, sys
VAULT = sys.argv[1]
SKIP = ("20 CC0 Library", "30 Models and Environment Kits", os.path.join("31 AI Skills for Roblox", "skills"), ".obsidian", ".claude")
rows = {}
for root, dirs, files in os.walk(VAULT):
    rel = os.path.relpath(root, VAULT)
    if rel == "." or any(rel == d or rel.startswith(d + os.sep) for d in SKIP):
        continue
    for f in sorted(files):
        if not f.endswith(".md"): continue
        path = os.path.join(root, f); text = open(path, encoding="utf-8").read()
        tags = re.search(r"^tags:\s*\[(.*?)\]", text, re.M)
        body = re.sub(r"^---.*?---", "", text, count=1, flags=re.S)
        body = re.sub(r"```.*?```", "", body, flags=re.S)
        summary = ""
        for para in re.split(r"\n\s*\n", body):
            p = para.strip()
            if not p or p.startswith(("#", "!", "|", "<!--", "- ", "Part of")) or p.startswith("**Measured"): continue
            p = re.sub(r"\[\[([^\]|]+)\|?([^\]]*)\]\]", lambda m: m.group(2) or m.group(1), p)
            p = re.sub(r"[*`_]", "", " ".join(p.split()))
            summary = re.split(r"(?<=[.!?])\s", p)[0][:200]
            break
        if "Links - " in f and not summary:
            n = len(re.findall(r"https?://", text)); summary = f"{n} curated links."
        sec = rel.split(os.sep)[0]
        rows.setdefault(sec, []).append((f[:-3], os.path.relpath(path, VAULT).replace(os.sep, "/"), tags.group(1) if tags else "", summary))
out = ["# VAULT_INDEX", "",
       "Machine-friendly index of every note: `title | path | tags | first sentence`. Built for AI agents: grep this file for an API name,",
       "topic or tag, then open only the notes you need. Regenerate after adding notes. Asset folders (20, 30) are not indexed.", ""]
total = 0
for sec in sorted(rows):
    out += [f"## {sec}", ""]
    for t, p, tg, s in rows[sec]:
        out.append(f"- {t} | {p} | {tg} | {s}"); total += 1
    out.append("")
open(os.path.join(VAULT, "VAULT_INDEX.md"), "w", encoding="utf-8", newline="\n").write("\n".join(out))
print("indexed", total)
