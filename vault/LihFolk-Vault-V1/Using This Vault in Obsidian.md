---
tags: [index, obsidian, guide]
---
# Using This Vault in Obsidian

How to open, search, speed up and pull answers out of this vault, by hand or with an AI agent. Start with [[00 Start Here]] for what is inside.

## Open it
- **As its own vault (recommended):** Obsidian > *Open folder as vault* > pick the vault folder. It already ships with settings tuned for its size (see below).
- **Inside an existing vault:** copy the folder in. Links use note names, so they still work, but copy the exclusion settings below into your own vault or Obsidian will index every texture and model.

## Zero installs
Obsidian is the only thing to install. The look (dark violet theme, animated welcome tab, cosmic graph, coloured folders) is plain CSS snippets that load on their own. The Celestial Vault add-on (animated parallax sky, welcome page, daily journal, moon calendar) ships switched on: when you first open the vault, Obsidian asks whether you trust the author; choose "Trust author and enable plugins" to get it, or restricted mode to keep only the CSS look. You can change your mind later under Settings > Community plugins. When the add-on is on, the CSS welcome tab steps aside so the two never overlap. Snippets can be switched off under Settings > Appearance > CSS snippets (celestial-lite, celestial-fx, graph-cosmic, vault-folder-colors).

## Keep it fast (already set up)
About 36 GB of this vault is assets: 869 texture sets and 997 HDRIs (section 20), CC0 models (section 30), and the raw `SKILL.md` files (section 31). Obsidian does not need to index any of that. The shipped `.obsidian/app.json` adds those folders to **Settings > Files and links > Excluded files**:

```
20 CC0 Library/
30 Models and Environment Kits/
31 AI Skills for Roblox/skills/
```

Excluded files stay on disk and still open from your file explorer; they just stay out of search, the graph, the quick switcher and link suggestions. If you merged the vault into your own, add the same three lines there.

More speed tips (rule of thumb):
- Leave **Detect all file extensions** off, so `.luau`, `.fbx` and `.hdr` files are not listed.
- The first open indexes about 450 notes and a few hundred images; give it a minute.
- On phones, sync only the notes: exclude the asset folders from Obsidian Sync or your sync tool, which keeps the mobile copy under 100 MB.

## Find things
- **Quick switcher (Ctrl/Cmd+O):** type part of a title. Titles are unique and descriptive, so this is the fastest way in.
- **Search (Ctrl/Cmd+Shift+F):** `tag:#anti-exploit`, `path:"23 Debugging"`, `"BindToClose"` (exact phrase), `line:(ProcessReceipt retry)`. Combine them: `path:"24 Worked Builds" "DataStore"`.
- **Hubs:** each section has a start-here note (for example [[Anti-Exploit Start Here]], [[Debugging Start Here]], [[Worked Builds Start Here]], [[Luau Cookbook Start Here]]).
- **Backlinks pane:** open a note and check what links to it; that is often the practical example of the concept.
- **Labels:** inside a note, "Roblox docs" means checked against official documentation (as of October 2026), "measured" means numbers from one production game, and "rule of thumb" is experience. Anything unconfirmed is collected in [[Open Questions - Whole Vault]].

## Useful core settings
- **Bookmarks:** bookmark the hubs you use most.
- **Graph view:** filter with `-path:"08 Animation"` to see the rest of the vault, or `path:"22"` for one section. Turn on "Existing files only".
- **Outline pane:** long notes (2,000 to 5,000 words) have clear headings; the outline lets you jump to the checklist at the end.

Community plugins are optional. None are required, and the vault ships with none enabled. Popular choices are Omnisearch (better full-text search) and Dataview (queries over tags and front matter). Install them only from Obsidian's own community plugin browser.

## Pulling answers with AI
The vault is plain Markdown, which suits AI tools well, and it is set up so an AI uses it by itself:

- `AGENTS.md` and `CLAUDE.md` at the root tell any agent that opens the folder how to search it, and to do so for every Roblox task without being asked.
- `VAULT_INDEX.md` lists every note in one line (title, path, tags, first sentence) so an agent can skim the whole vault in one read and grep it for API names.
- **Zero install in Claude Code:** open this vault folder itself in Claude Code (or the Code tab of the Claude app). The ten Roblox skills and six Obsidian skills are already in the hidden `.claude/skills` folder, so they load automatically as project skills together with `CLAUDE.md`. Check with `/skills`.
- **Claude app chat or claude.ai:** these cannot read a folder. Upload the zips in `31 AI Skills for Roblox/upload` under Settings > Capabilities > Skills, and add the notes you need to a Project.
- `install-ai.ps1` / `install-ai.sh` install the ten skills into your user folder so they also work in your other projects (for example your game's own folder) from section 31 into Claude Code with this vault's path filled in. Their descriptions trigger on Roblox work automatically, so the AI consults the vault in any project. `-Global` adds a one-paragraph note to your global CLAUDE.md as well.
- Rebuild the index after adding notes: `py _tools/build_index.py .` from the vault folder; `py _tools/link_graph.py .` refreshes the Connected notes lines. Or ask your agent to run them.

1. **Point an agent at the folder.** A coding agent with file access (Claude Code, Cursor and others) can read the vault directly. Give it the vault path and ask it to start at `00 Start Here.md`.
2. **Install the research skill.** [[AI Skills Start Here]] (section 31) includes `roblox-vault-research`, which tells an agent how to search this vault: hubs first, then titles and tags, prefer "Roblox docs" labels, name the notes it used, and check Open Questions. The other skills there (secure remotes, DataStore safety, monetization compliance, performance, debugging, UI, asset import, system builder) each list the notes they rely on.
3. **Obsidian-aware tools.** Community MCP servers and plugins can expose a vault to an AI client. Treat them like any plugin: check the source before installing, and give them read-only access where possible.
4. **Paste a note.** For a chat tool without file access, open the note, copy it and ask your question about it. One focused note beats ten loosely related ones.

Prompt pattern that works well (rule of thumb):

> Read `22 Anti-Exploit and Security/Threat Modeling a Roblox Game.md` and `03 Architecture and Networking/Remote Abuse Patterns and Rate Limiting in Practice.md`. Then review my RemoteEvent handlers below against them. Quote which rule each problem breaks.

Always verify AI output against the notes and the Roblox docs. The vault's own code is "reviewed, not run" unless a note says otherwise: test it in Studio before you ship.

## Keeping your copy current
Roblox changes quickly. Anything marked "as of October 2026" (prices, payouts, limits, betas) is worth rechecking. If you find a change, edit the note and add a line to [[Open Questions - Whole Vault]] so the next reader knows.
