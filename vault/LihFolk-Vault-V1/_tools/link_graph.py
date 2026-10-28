"""Add a regenerable "Connected notes" block to every vault note: the most similar notes by TF-IDF
(4 overall + 2 from other sections) plus the section hub, skipping notes it already links.
Re-running replaces the old block. Usage: py link_graph.py <vault folder>"""
import math, os, re, sys
from collections import Counter

VAULT = sys.argv[1]
SKIP_DIRS = ("20 CC0 Library", "30 Models and Environment Kits", os.path.join("31 AI Skills for Roblox", "skills"), ".obsidian", ".claude", "_tools")
SKIP_NOTES = {"00 Start Here", "Open Questions - Whole Vault", "README", "Glossary", "Using This Vault in Obsidian", "AGENTS", "CLAUDE", "VAULT_INDEX"}
START, END = "<!-- auto-links:start -->", "<!-- auto-links:end -->"
BLOCK_RE = re.compile(r"\n*## Connected notes\n" + re.escape(START) + r".*?" + re.escape(END) + r"\n?", re.S)
STOP = set("""the and for that with this from are you your can not but its it's has have was were will would should could into
than then them they their there these those what when where which while who why how all any each other some such only own same
also just more most very too one two three use used uses using make makes made get gets like need needs about over under
after before between both because does doing done here out off per via see note notes vault section roblox studio game games
player players file files value values set sets new way ways first last time times example examples rule thumb docs measured
reference project october 2026 start here related""".split())

notes = {}
for root, dirs, files in os.walk(VAULT):
    rel = os.path.relpath(root, VAULT)
    if any(rel == d or rel.startswith(d + os.sep) for d in SKIP_DIRS): continue
    for f in files:
        if f.endswith(".md") and f[:-3] not in SKIP_NOTES:
            notes[f[:-3]] = os.path.join(root, f)

def section_of(path): return os.path.relpath(path, VAULT).split(os.sep)[0]
def tokens(text):
    text = re.sub(r"```.*?```", " ", text, flags=re.S)
    text = re.sub(r"^---.*?---", " ", text, flags=re.S)
    return [w for w in re.findall(r"[a-z][a-z0-9]{2,}", text.lower()) if w not in STOP]

raw, links = {}, {}
for name, path in notes.items():
    text = BLOCK_RE.sub("\n", open(path, encoding="utf-8").read())
    raw[name] = text
    links[name] = {m.strip() for m in re.findall(r"\[\[([^\]\|#]+)", text)}
    c = Counter(tokens(text))
    for w in tokens(name): c[w] += 6                     # titles count a lot
    links[name + "__tf"] = c
df = Counter()
for name in notes: df.update(set(links[name + "__tf"]))
N = len(notes)
vec = {}
for name in notes:
    tf = links[name + "__tf"]
    v = {w: (1 + math.log(n)) * math.log(N / df[w]) for w, n in tf.items() if df[w] > 1}
    v = dict(sorted(v.items(), key=lambda kv: -kv[1])[:180])
    norm = math.sqrt(sum(x * x for x in v.values())) or 1
    vec[name] = {w: x / norm for w, x in v.items()}
inv = {}
for name, v in vec.items():
    for w, x in v.items(): inv.setdefault(w, []).append((name, x))

hubs = {}
for name, path in notes.items():
    if name.endswith("Start Here"): hubs.setdefault(section_of(path), name)

added = 0
for name, path in notes.items():
    scores = Counter()
    for w, x in vec[name].items():
        for other, y in inv[w]:
            if other != name: scores[other] += x * y
    sec = section_of(path)
    have = links[name]
    ranked = [o for o, _ in scores.most_common(60) if o not in have]
    same = [o for o in ranked][:4]
    cross = [o for o in ranked if section_of(notes[o]) != sec and o not in same][:2]
    picks = same + cross
    hub = hubs.get(sec)
    if hub and hub != name and hub not in have and hub not in picks: picks.append(hub)
    if not picks: continue
    block = "\n\n## Connected notes\n" + START + "\n" + " · ".join(f"[[{p}]]" for p in picks) + "\n" + END + "\n"
    text = raw[name].rstrip() + block
    with open(path, "w", encoding="utf-8", newline="\n") as fh: fh.write(text)
    added += len(picks)
print("notes", N, "links added", added)
