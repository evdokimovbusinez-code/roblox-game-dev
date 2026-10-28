# Automation kit (CI/CD, Open Cloud, cloud tests)

Copy into a project that follows `assets/template/`. Everything here was syntax-checked (YAML/JSON/TOML parsed, Python
compiled) but NOT run against a live Roblox universe: run the pipeline once on a throwaway TEST universe before trusting it.

| File | Purpose |
|---|---|
| `.github/workflows/cicd.yml` | static checks (selene, stylua, luau-lsp) -> cloud tests on the TEST place -> deploy (publish, restart outdated servers, publish Configs); `environment: production` = human approval gate |
| `scripts/rbx.py` | stdlib-only Open Cloud helper: `test PLACE TASK`, `publish PLACE`, `restart [MIN]`, `config JSON [Immediate\|GradualRollout]`; retries on 429/5xx |
| `tasks/runTests.luau` | runs inside a Luau Execution task, boots Jest Roblox, fails the task on any red test |
| `tests/jest.config.luau`, `tests/__tests__/NumberFormat.spec.luau` | Jest config (required) and an example spec; put under `tests/` |
| `test.project.json` | Rojo project for the TEST place: adds `DevPackages`, `Tests`, `LoadStringEnabled=true` (never set that in production) |
| `asphalt.toml` | optional asset upload + generated asset-id module (`asphalt sync`) |
| `config/live.json` | example flat key -> value file pushed to Configs by `rbx.py config` |

## Setup (once)

1. Two games in Studio (File -> Publish): PROD and TEST (two universes, so tests cannot touch live DataStores). Copy their Universe/Place ids.
2. GitHub: secret `ROBLOX_API_KEY`; variables `PROD_UNIVERSE_ID`, `PROD_PLACE_ID`, `TEST_UNIVERSE_ID`, `TEST_PLACE_ID`; environment `production` with required reviewers.
3. API key (Creator Hub -> Credentials), restricted to those two universes, scopes: `universe-places:write` (note the hyphen),
   `universe.place.luau-execution-session:write` (+ read for logs), `universe:write`, `universe:read`; add `asset:read/write` for Asphalt.
   Do not IP-restrict a key that Roblox servers use. Keys expire after 60 days unused.
4. Add Jest to `wally.toml` `[dev-dependencies]`: `Jest = "roblox/jest@3.20.1"`, `JestGlobals = "roblox/jest-globals@3.20.1"`.
5. Add the CI step `luau-lsp analyze` flags as in the workflow; if you use the template stub fallback, run `scripts/analyze.sh` instead.

## Limits to remember (Oct 2026)

Luau Execution: create task 5/min per key owner, at most 10 incomplete tasks per place, 5 min per task, 450 KB logs: batch all tests into ONE task.
Place publish: 30/min, BETA. `:restartServers`: 30/min. Configs publish: 10/min (BETA). Experiments: 10/min (EXPERIMENTAL).
Full tables and curl examples: `references/builder/project-setup.md`.
