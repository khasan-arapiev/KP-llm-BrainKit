"""KP-WikiHealth mechanical scanner. Read-only: writes one JSON report to %TEMP%.

Usage: python scan.py            full scan, prints summary, writes wikihealth.json
Resolution is Brain-wide (the Obsidian vault root), not wiki-only.
"""
import os, re, json, datetime, collections, io, sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

def _vault_root():
    cfg = os.path.join(os.path.expanduser("~"), ".claude", "brainkit.json")
    with open(cfg, encoding="utf-8") as f:
        return json.load(f)["vaultPath"]

BRAIN = _vault_root()
WIKI = os.path.join(BRAIN, "wiki")
TODAY = datetime.date.today()
SKIP_DIRS = {".git", ".obsidian", ".backups", "node_modules", "production"}
VALID_TYPES = {
    "entity","concept","source-summary","synthesis","comparison","log","skill","lesson",
    "reference","social-hub","social-voice","social-ledger","social-profile",
    "project-overview","project-map","project-context","project-review","project-status",
    "project-strategy","plan","decision","post-mortem","learning","project-index",
    "orchestrator-board",
}
STATUS_RANK = {
    "building":0,"in-progress":0,"approved":1,"ready":1,"open":2,"proposed":2,
    "drafted":2,"drafting":2,"living":2,"partially-shipped":3,"accepted":4,
    "shipped-to-test":5,"complete":6,"shipped":7,"superseded":8,"archived":8,"abandoned":8,
}
SEG_HEADING = {"core":"Core","plans":"Plans","decisions":"Decisions","reviews":"Reviews",
               "post-mortems":"Post-mortems","learnings":"Learnings","reference":"Reference"}
HEADING_ORDER = ["Root","Core","Plans","Decisions","Reviews","Post-mortems","Learnings","Reference"]
REQUIRED = ["title", "type", "created", "updated"]
OPS = {"ingest","query","lint","setup","note","wrap-up","grill","ship","bugfix",
       "decision","plan","code-cowork","migrate"}
FROZEN_STATUS = {"shipped", "shipped-to-test", "accepted", "abandoned", "superseded", "archived"}
LOG_SIZE_BUDGET_KB = 250
# CLAUDE.md itself instructs linking these Brain-root targets from wiki pages, so a wiki link
# resolving to them outside wiki/ is by design, not drift.
SANCTIONED_OUTSIDE = {"credentials", "project-handling", "claude"}
# Orchestrator lane workspaces (briefs, reports, inboxes, lane handoffs) are transient KP-God
# work artifacts, not wiki knowledge pages: exempt from page-hygiene checks. board.md keeps
# its own checks (orchestrator-board type, board_oversize, multiple_live_boards).
lane_re = re.compile(r"^projects/[^/]+/orchestrator/")

fm_re = re.compile(r"^---\s*\n(.*?)\n---\s*\n?", re.S)
link_re = re.compile(r"!?\[\[([^\]\[]+?)\]\]")

def strip_code(text):
    text = re.sub(r"```.*?```", "", text, flags=re.S)
    return re.sub(r"`[^`\n]*`", "", text)

def parse_fm(text):
    m = fm_re.match(text)
    if not m:
        return None, text
    fm = {}
    for line in m.group(1).splitlines():
        kv = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if kv:
            fm[kv.group(1).strip()] = kv.group(2).strip().strip('"').strip("'")
    return fm, text[m.end():]

def _page_meta(path):
    raw = open(path, "rb").read().decode("utf-8", errors="replace").lstrip("﻿")
    fm, _ = parse_fm(raw)
    fm = fm or {}
    stem = os.path.basename(path)[:-3]
    created = fm.get("created", "")
    if not created:
        m = re.match(r"(\d{4}-\d{2}-\d{2})", stem)
        created = m.group(1) if m else ""
    return {"title": fm.get("title") or stem, "status": (fm.get("status") or "").lower(),
            "created": created, "date": created or "0000-00-00", "stem": stem}

def build_indexes():
    """Generate one _index.md catalog per project root. Deterministic, LF, idempotent."""
    proj = os.path.join(WIKI, "projects")
    roots = []
    for dp, dirs, files in os.walk(proj):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        if any(f.endswith("-overview.md") for f in files):
            roots.append(dp)
    nroots = {os.path.normpath(r) for r in roots}
    written = 0
    for root in sorted(roots):
        nroot = os.path.normpath(root)
        slug = next((f[:-len("-overview.md")] for f in os.listdir(root)
                     if f.endswith("-overview.md")), os.path.basename(root))
        index_name = slug + "-index.md"
        owned = []
        for dp, dirs, files in os.walk(root):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            if os.path.normpath(dp) != nroot and os.path.normpath(dp) in nroots:
                dirs[:] = []  # nested project root: pages belong to it, not this index
                continue
            for f in files:
                if f.endswith(".md") and f not in (index_name, "_index.md"):
                    owned.append(os.path.join(dp, f))
        if len(owned) <= 1:
            continue  # a root whose only page is its overview needs no catalog (umbrella groupings)
        groups = collections.defaultdict(list)
        for pth in owned:
            rel = os.path.relpath(pth, root).replace("\\", "/")
            seg = rel.split("/")[0] if "/" in rel else "_root"
            heading = "Root" if seg == "_root" else SEG_HEADING.get(seg, seg.title())
            if "/archive/" in "/" + rel:
                heading += " (archived)"
            m = _page_meta(pth)
            m["link"] = "wiki/" + os.path.relpath(pth, WIKI).replace("\\", "/")[:-3]
            groups[heading].append(m)
        def hkey(h):
            base = h.replace(" (archived)", "")
            return (HEADING_ORDER.index(base) if base in HEADING_ORDER else 99,
                    h.endswith("(archived)"), h)
        out_lines = ["---", f"title: {slug} page index", "type: project-index",
                     f"project: {slug}", "generated: true", "---", "",
                     f"# {slug} — page index", "",
                     "GENERATED by `skills/KP-WikiHealth/scripts/scan.py --build-indexes`. "
                     "Do not hand-edit; rerun the generator. Catalog of every page under this "
                     "project for reachability and discovery. Live state lives in the project's "
                     "`core/status` page; this is an index, not status."]
        total = 0
        for h in sorted(groups, key=hkey):
            items = groups[h]
            items.sort(key=lambda m: m["stem"])
            items.sort(key=lambda m: m["date"], reverse=True)
            items.sort(key=lambda m: STATUS_RANK.get(m["status"], 4))
            out_lines += ["", f"## {h} ({len(items)})"]
            for m in items:
                st = f" — `{m['status']}`" if m["status"] else ""
                cr = f" ({m['created']})" if m["created"] else ""
                out_lines.append(f"- [[{m['link']}|{m['title']}]]{st}{cr}")
            total += len(items)
        open(os.path.join(root, index_name), "wb").write(
            ("\n".join(out_lines) + "\n").encode("utf-8"))
        written += 1
        print(f"  {os.path.relpath(os.path.join(root, index_name), BRAIN)}  ({total} pages)")
    print(f"built {written} project indexes")

if "--build-indexes" in sys.argv:
    build_indexes()
    sys.exit(0)

brain_stems = collections.defaultdict(list)
handoff_stems = set()
for dp, dirs, files in os.walk(BRAIN):
    dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
    for f in files:
        if f.endswith(".md"):
            rel = os.path.relpath(os.path.join(dp, f), BRAIN).replace("\\", "/")
            brain_stems[f[:-3].lower()].append(rel)
            if rel.startswith("handoffs/"):
                handoff_stems.add(f[:-3].lower())

pages = {}
for dp, dirs, files in os.walk(WIKI):
    for f in files:
        if f.endswith(".md"):
            full = os.path.join(dp, f)
            rel = os.path.relpath(full, WIKI).replace("\\", "/")
            raw = open(full, "rb").read()
            pages[rel] = {
                "stem": f[:-3].lower(),
                "bom": raw.startswith(b"\xef\xbb\xbf"),
                "text": raw.decode("utf-8", errors="replace").lstrip("﻿"),
            }

issues = collections.defaultdict(list)
inbound = collections.defaultdict(set)
frozen = set()

for rel, p in pages.items():
    fm, body = parse_fm(p["text"])
    p["fm"], p["body"] = fm, body
    p["lines"] = p["text"].count("\n") + 1
    p["words"] = len(re.findall(r"\S+", body))
    if p["bom"]:
        issues["bom"].append(rel)
    archived = "/archive/" in rel or rel.startswith("log-archive/")
    if fm and fm.get("status", "").lower() in FROZEN_STATUS:
        archived = True
    if archived:
        frozen.add(rel)
    p["lane"] = bool(lane_re.match(rel)) and (fm or {}).get("type") != "orchestrator-board"
    if rel in ("index.md", "log.md") or (fm or {}).get("type") == "project-index":
        pass  # root catalog, log, and generated per-project indexes: no required-field/stale checks
    elif p["lane"]:
        pass  # transient lane workspace, not a wiki page
    elif fm is None:
        issues["no_frontmatter"].append(rel)
    else:
        miss = [k for k in REQUIRED if k not in fm]
        if miss:
            issues["fm_missing_fields"].append([rel, miss])
        t = fm.get("type")
        if t and t not in VALID_TYPES:
            issues["fm_unknown_type"].append([rel, t])
        st = (fm.get("status") or "").lower()
        if st and st not in STATUS_RANK and t in ("plan", "decision") and not archived:
            issues["unknown_status"].append([rel, st])
        upd = fm.get("updated")
        if upd and not archived:
            try:
                if (TODAY - datetime.date.fromisoformat(upd[:10])).days > 90:
                    issues["stale"].append([rel, upd])
            except ValueError:
                issues["fm_bad_date"].append([rel, upd])

for rel, p in pages.items():
    fm = p.get("fm")
    if fm and fm.get("aliases"):
        for alias in re.findall(r"[\w][\w .-]*", fm["aliases"]):
            brain_stems[alias.strip().lower()].append("wiki/" + rel)

for rel, p in pages.items():
    for m in link_re.finditer(strip_code(p["text"])):
        raw = m.group(1)
        target = raw.split("|")[0].split("#")[0].strip().lower()
        if not target:
            continue
        if "projects/projects/" in target:
            issues["doubled_path"].append([rel, raw])
        stem = target.split("/")[-1]
        wiki_rel_guess = target[5:] + ".md" if target.startswith("wiki/") else target + ".md"
        if stem in handoff_stems:
            issues["handoff_links"].append([rel, raw])
        if re.match(r"^(feedback_|project_|user_)", stem):
            issues["memory_slug_links"].append([rel, raw])
            continue
        if stem in brain_stems:
            hits = sorted(set(brain_stems[stem]))
            wiki_hits = [h for h in hits if h.startswith("wiki/")]
            for h in wiki_hits:
                inbound[h[5:]].add(rel)
            if not wiki_hits:
                if stem not in SANCTIONED_OUTSIDE:
                    issues["resolves_outside_wiki"].append([rel, raw, hits[0]])
            elif len(hits) > 1 and "/" not in target:
                issues["ambiguous_links"].append([rel, raw, hits])
        else:
            # rename detector: same-suffix file elsewhere in wiki
            cands = []
            parts = target.split("-")
            for i in range(1, len(parts)):
                suf = "-".join(parts[i:])
                if suf in brain_stems:
                    cands += [h for h in brain_stems[suf] if h.startswith("wiki/")]
            issues["broken_links"].append([rel, raw, sorted(set(cands))[:3]])

index_text = pages.get("index.md", {}).get("text", "")
index_slugs = {m.group(1).split("|")[0].split("#")[0].strip().lower().split("/")[-1]
               for m in link_re.finditer(index_text)}
for slug in sorted(index_slugs):
    if slug and slug not in brain_stems:
        issues["index_dead_entries"].append(slug)

for rel, p in pages.items():
    if rel in ("index.md", "log.md") or rel in frozen or (p.get("fm") or {}).get("type") == "project-index" or p.get("lane"):
        continue
    if not inbound.get(rel) and p["stem"] not in index_slugs:
        issues["orphans"].append(rel)
    if p["words"] < 50:
        issues["stubs"].append([rel, p["words"]])
    if p["lines"] > 400:
        issues["oversized"].append([rel, p["lines"]])

log_text = pages.get("log.md", {}).get("text", "")
for i, line in enumerate(log_text.splitlines(), 1):
    if line.startswith("## "):
        m = re.match(r"^## \[(\d{4}-\d{2}-\d{2})\] ([a-z-]+) \| .+", line)
        if not m or m.group(2) not in OPS:
            issues["bad_log_headings"].append([i, line[:120]])
log_kb = len(log_text.encode("utf-8")) // 1024
if log_kb > LOG_SIZE_BUDGET_KB:
    issues["log_over_budget"].append([log_kb, LOG_SIZE_BUDGET_KB])

tbl = collections.defaultdict(set)
para = collections.defaultdict(set)
for rel, p in pages.items():
    if (p.get("fm") or {}).get("type") == "project-index":
        continue  # generated build artifacts: banner + catalog rows are intentional, not duplication
    lines = p["text"].splitlines()
    for i, line in enumerate(lines):
        ls = re.sub(r"\s+", " ", line.strip())
        if ls.startswith("|") and ls.count("|") >= 3 and not set(ls) <= set("|-: "):
            nxt = re.sub(r"\s+", " ", lines[i + 1].strip()) if i + 1 < len(lines) else ""
            if "|" in nxt and set(nxt) <= set("|-: "):
                continue  # header row (next line is the |---| separator): structural, not data
            tbl[ls].add(rel)
    for blk in re.split(r"\n\s*\n", p["body"] or ""):
        b = re.sub(r"\s+", " ", blk.strip())
        if len(re.findall(r"[.!?] ", b)) >= 3 and len(b) > 200:
            para[b].add(rel)
issues["dup_tables"] = [[k[:120], sorted(v)] for k, v in tbl.items() if len(v) > 1]
issues["dup_paras"] = [[k[:120], sorted(v)] for k, v in para.items() if len(v) > 1]

# Multiple live orchestrator boards per project. A fresh conductor boots from board.md;
# prior parallel runs must be archived to orchestrator/archive/ on consolidation. More than
# one board outside archive/ means a fresh chat can boot the wrong one (mixes past/present tasks).
boards = collections.defaultdict(list)
for rel, p in pages.items():
    if (p.get("fm") or {}).get("type") == "orchestrator-board" and "/archive/" not in rel:
        parts = rel.split("/")
        if len(parts) > 2 and parts[0] == "projects":
            boards[parts[1]].append(rel)
        # A board is re-read on every conductor boot; past ~12 KB it degrades judgment.
        # KP-God's own rule: compact (collapse done lanes, push narrative into handoffs).
        kb = len(p["text"].encode("utf-8")) / 1024
        if kb > 12:
            issues["board_oversize"].append([rel, round(kb, 1)])
for slug, bs in sorted(boards.items()):
    if len(bs) > 1:
        issues["multiple_live_boards"].append([slug, sorted(bs)])

WEIGHTS = {"broken_links": 0.02, "orphans": 0.2, "no_frontmatter": 0.3, "fm_missing_fields": 0.1,
           "fm_unknown_type": 0.1, "fm_bad_date": 0.1, "stale": 0.05, "index_dead_entries": 0.2,
           "bad_log_headings": 0.2, "dup_tables": 0.5, "dup_paras": 0.5, "handoff_links": 0.1,
           "memory_slug_links": 0.1, "log_over_budget": 1.0, "bom": 0.1, "ambiguous_links": 0.05,
           "doubled_path": 0.3, "unknown_status": 0.05, "multiple_live_boards": 0.6,
           "board_oversize": 0.3}
penalty = sum(min(len(issues[k]) * w, 2.5) for k, w in WEIGHTS.items())
score = round(max(1.0, 10.0 - penalty), 1)

report = {"scanned": len(pages), "score": score, "log_kb": log_kb,
          **{k: v for k, v in sorted(issues.items())}}
out = os.path.join(os.environ.get("TEMP", "."), "wikihealth.json")
json.dump(report, open(out, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print(f"pages: {len(pages)} | health score: {score}/10 | log: {log_kb} KB | report: {out}")
for k in sorted(issues):
    if issues[k]:
        print(f"  {len(issues[k]):4} {k}")
