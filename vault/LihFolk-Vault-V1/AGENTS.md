# Instructions for AI agents

This folder is a knowledge base about making Roblox games: about 700 Markdown notes plus asset libraries.
Use it on your own initiative whenever a task touches Roblox. The user should not have to ask.

## How to use it

1. **Skim `VAULT_INDEX.md` first.** One line per note: `title | path | tags | first sentence`. Grep it for the API names,
   services and topic words in the task (`ProcessReceipt`, `UpdateAsync`, `RemoteEvent`, `hitbox`, `ScreenGui`, `Bones`).
2. **Open only the best two or three notes.** Read the headings, then the relevant parts. Most notes end with
   "Common mistakes" and a "Checklist": the fastest way to get the rules.
3. **Follow `[[links]]` and the "Connected notes" line** at the end of a note only if the first note is not enough.
4. **Weigh the labels.** "Roblox docs (as of October 2026)" = checked against official docs. "Measured" = numbers from one
   shipped game. "Rule of thumb" = experience. Unconfirmed claims are in `Open Questions - Whole Vault.md`.
   Platform facts change: if something sounds dated, say so.
5. **Cite what you used** in one line (note titles), so the user can read further.

## Where things are

- `00 Start Here.md`: map of all 46 sections and reading paths.
- Section hubs: every section has a `... Start Here.md` note.
- `24 Worked Builds`, `29 Luau Cookbook`, `43 Genre Systems End to End`: complete code to adapt (reviewed, mostly not run: test it).
- `22 Anti-Exploit and Security`, `23 Debugging Deep Dives`: use for any remote, currency, purchase or bug work.
- `46 Resource Library`: about 3,600 curated outside links by topic.
- `31 AI Skills for Roblox/skills/`: ten agent skills (remotes, DataStores, monetization, performance, debugging, UI,
  assets, system builder, anti-exploit, vault research). When this vault is the open project they are already loaded from `.claude/skills`; `install-ai.ps1` / `install-ai.sh` install them for other projects.
- Do not grep `20 CC0 Library/` or `30 Models and Environment Kits/` for prose: they hold thousands of asset files.
  Use them when the task needs a texture, HDRI or model (all CC0, free for any use).

## Ground rules

- Server-authoritative code, validated remotes, safe DataStores: the vault's security and data notes are the standard.
- Do not invent API members. If the vault and the official docs disagree, trust the docs and mention it.
