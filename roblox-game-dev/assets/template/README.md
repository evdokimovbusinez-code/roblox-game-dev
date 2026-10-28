# Roblox game template (Rojo + Wally, production skeleton)

A minimal, typed (`--!strict`) project an agent copies to start any game. It contains the parts that are expensive to get
wrong later: session-locked player data, idempotent Developer Product fulfilment, validated and rate-limited remotes,
analytics, and PolicyService gating. It has no gameplay on purpose.

Reference docs: `references/builder/project-setup.md` (toolchain, Open Cloud, CI) and
`references/builder/code-architecture.md` (why the code looks like this). CI/CD and Open Cloud scripts: `assets/automation/`.

## Layout

```
default.project.json   Rojo tree: src/shared -> ReplicatedStorage.Shared, src/server -> ServerScriptService.Server,
                       src/client -> StarterPlayerScripts.Client, Packages -> ReplicatedStorage.Packages,
                       ServerPackages -> ServerScriptService.ServerPackages
rokit.toml             pinned tools (rojo, wally, selene, stylua, luau-lsp, lune)      -> rokit install
wally.toml             ProfileStore (server-dependency); Jest and shared libs commented -> wally install
selene.toml / stylua.toml / .luaurc   lint, format, strict typing
src/shared/            Config (constants), Types (data shapes), Remotes (names + creation), NumberFormat (K/M/B)
src/server/Main.server.luau           the ONLY server Script: init() everything, then start() everything
src/server/services/   PlayerData  ProfileStore session lock, migrations, autosave, shutdown flush, replication
                       Purchases   BindReceiptHandler, idempotent grants, wait-for-save before Processed
                       Remotes     token-bucket rate limit + validators (number/integer/string/key/boolean)
                       Shop        example validated purchase with soft currency
                       Analytics   crash-proof AnalyticsService wrapper (economy, funnels, progression, custom)
                       Policy      PolicyService flags (fail closed), AgeChecked, IsVerified, text filtering
src/client/Main.client.luau           the ONLY client entry: controllers expose start()
src/client/controllers/ StateController (read-only mirror of server data), HudController (coin label)
src/client/ui/         code-only UI library (Theme, Screen, Window/WindowManager, Button, CurrencyCounter, LeftMenuStack, TopTabs,
                       OfferButtons, Toasts, RewardFlyToCounter, OfflineEarningsPopup, ...); see references/builder/ui-implementation.md
src/client/controllers/UiDemoController.luau   example HUD built from ui/ (shown by `rojo serve`; Main.client.luau SHOW_UI_DEMO = false removes it)
analysis/              STUB of ProfileStore, used only by static analysis (see below). Never shipped.
scripts/               analyze.sh, make_sourcemap.py
tools/place_scan.luau  read-only Studio scan for visual audits (not synced by Rojo; see references/builder/visual-audit.md §6)
```

## Start a game

1. Copy this folder, rename `MyGame` in `default.project.json` and `yourstudio/mygame` in `wally.toml`.
2. `rokit install` then `wally install` (restores `ServerPackages/ProfileStore`).
3. In Studio: File -> Publish once (creates the universe), enable "Enable Studio Access to API Services" for local data tests.
4. `rojo serve`, connect the Rojo plugin in Studio. `rojo build -o game.rbxl` for a file.
5. Replace the placeholder ids in `Config.Products` with real Developer Product ids and fill `GRANTS` in `Purchases.luau`.
6. Register the right-to-be-forgotten template `Player_{UserId}` (Creator Hub -> Configurations -> Data stores manager).
7. Run `scripts/analyze.sh`, `selene src`, `stylua --check src` before every commit.

## How to extend

| Task | Where |
|---|---|
| New persistent field | add to `Types.PlayerData` AND `TEMPLATE` in `PlayerData.luau`; if old data needs conversion, bump `SCHEMA_VERSION` and add `MIGRATIONS[n]`; add the key to `Config.ReplicatedKeys` if the client must see it |
| New client -> server action | add the name to `RemoteName` and `NAMES` in `shared/Remotes.luau`; in a service call `Remotes.listen(name, limit, handler)`; validate every argument with `Remotes.check.*`; the client sends an intent only |
| New Developer Product | create it (Creator Hub or `assets/automation`), add the id to `Config.Products`, add a non-yielding grant to `GRANTS`, add a reversal when you add refund handling |
| New system (quests, pets, ...) | new `services/Name.luau` with optional `init()` / `start()`, required and called in `Main.server.luau`; keep state in `profile.Data`, never in module-level tables that outlive a session |
| Loot box / gacha / trading | gate with `Policy.canUsePaidRandomItems` / `Policy.canTradePaidItems` on the server, and hide the UI too |
| Player-written text others can see | always `Policy.filterForBroadcast(player, text)` |
| High-frequency data (positions, VFX) | `UnreliableRemoteEvent` (payload <= 1000 bytes) or Zap / Blink; keep server validation |
| Live-tunable values, event switches | Roblox Configs (`ConfigService`), not constants in `Config.luau` |
| Tests | see `assets/automation` (Jest Roblox + Luau Execution); start with pure modules (economy math, migrations) |

## Not included on purpose

Server Authority simulation, game-specific screens (inventory grid, pass cards, settings; the UI library only has the shared components), trading and refund services, a world (Map/Terrain `.rbxm`), tests, Asphalt.
Each is described in the reference docs; add them when the game needs them, not before.

## Static analysis and the ProfileStore stub

`luau-lsp analyze` needs the real package source to resolve `require(ServerScriptService.ServerPackages.ProfileStore)`.
On a normal machine `wally install` provides it and the script uses `rojo sourcemap`. Where Wally/Rojo cannot run
(offline sandbox, CI image without tools) `scripts/analyze.sh` falls back to `analysis/stubs/ServerPackages/ProfileStore.luau`,
a ~40 line shim of the API surface `PlayerData.luau` uses, plus a hand-made sourcemap from `scripts/make_sourcemap.py --stubs`.
The shim is analysis-only: no Rojo project maps `analysis/`, and `.styluaignore` / `selene.toml` skip it.
`PlayerData.luau` declares its own structural types for ProfileStore and casts the module (`:: any :: ProfileStoreModule`),
so the code does not depend on the package's exported generics.

Verified on 2026-10-26 with luau-lsp (build of the 1.70 line) against `globalTypes.d.luau`: 0 diagnostics with the old solver
(default) and with `--flag:LuauSolverV2=true`. Deliberately broken code (misspelled remote name, wrong types) is reported,
so the check is real. Not verified here: `rojo build`, StyLua formatting and Selene (tools not installable offline), and a
live Studio playtest. `BindReceiptHandler` is called through an `any` cast because older Roblox type definitions lack it.
