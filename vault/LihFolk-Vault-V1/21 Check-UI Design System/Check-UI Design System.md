---
tags: [ui, design-system, luau, ai-skill, check-ui]
---
# Check-UI Design System

A ready-made design system and Luau component library for cartoon and simulator UI in Roblox: chunky 3D buttons, a signature close button, headers with two-tier shadows, a checkerboard fade, rotating sunbursts, a multi-device scaling engine and 1,022 pre-uploaded HD icons. It is built around five menus every simulator needs: Shop, Codes, Rebirth, Settings and Daily Rewards.

![[all_menus_harmonized.png]]

**License:** MIT, free to use, change and share in any game, paid or free. It is included here unchanged. The full documentation is in [[Check-UI README]], the exact numbers (sizes, colours, bevels, tweens) are in [[Check-UI Design System Spec]], and the AI agent instructions are in [[Check-UI AI Skill]].

## What is in this folder

| Path | What |
|---|---|
| `src/CheckUITheme.luau` | Colours, gradients, fonts, sizes |
| `src/CheckUIComponents.luau` | `createWindow`, `createStandardButton`, close button, headers, cards, toggles... |
| `src/CheckUIIcons.luau` | 1,022 icons as `rbxassetid://` ids, grouped by category, with `Icons.Search("sword")` |
| `src/CheckUIController.luau` | Opens and closes menus, scaling, sunburst rotation |
| `examples/` | Complete Shop, Daily Rewards, Rebirth, standard button and all-menus examples |
| `assets/` | Showcase renders |

## Install it in Roblox Studio
1. In the Explorer, add a **Folder** named `CheckUI` under **ReplicatedStorage**.
2. Inside it, add four **ModuleScripts** named exactly `CheckUITheme`, `CheckUIComponents`, `CheckUIIcons` and `CheckUIController`.
3. Open each `.luau` file from `src/` in a text editor, copy everything and paste it into the ModuleScript with the same name. The modules find each other with `script.Parent`, so the names must match.
4. Use them from a LocalScript in StarterGui or StarterPlayerScripts:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CheckUI = require(ReplicatedStorage.CheckUI.CheckUIComponents)
local Theme = require(ReplicatedStorage.CheckUI.CheckUITheme)
local Icons = require(ReplicatedStorage.CheckUI.CheckUIIcons)
```

5. Start from the file in `examples/` closest to the menu you need, then change the text, icons and actions.

**Rojo users:** put `src/` at `ReplicatedStorage/CheckUI` in your project file and the modules sync with the right names.

**Measured:** the four modules were installed under these names in a production game in October 2026. All four required without errors, and `Icons.Search("sword")` returned 6 icons.

## Install it as an AI skill
So your coding agent builds every menu to this standard by default:
- **Claude Code:** copy this whole folder to `~/.claude/skills/check-ui-clean-roblox/`, rename `Check-UI AI Skill.md` back to `SKILL.md`, and restart Claude Code. Ask for "a Daily Rewards menu" and it follows the spec. See [[AI Code Assistants for Luau]].
- **Other agents (Cursor, Antigravity...):** put `SKILL.md` in that tool's skills or rules folder, as described in [[Check-UI README]].

## Known issue: the font (Roblox docs, as of October 2026)
`CheckUITheme` uses `Enum.Font.GothamBlack`. Roblox removed the Gotham fonts, so it now draws as Montserrat. To keep the heavy cartoon look, change the `Font` line in `CheckUITheme` to `Enum.Font.BuilderSansExtraBold`, or to a `FontFace` such as Fredoka One. See [[Text Fonts and Rich Text]].

## Check every menu before you ship (from the Check-UI rules)
- [ ] Buttons have a 3 to 4 px bottom bevel and a dark shadow edge, with no flat buttons.
- [ ] Buttons use the right state colour: lime for CLAIM / BUY / REDEEM, silver for CLAIMED / DISABLED, crimson for LOCKED, gold for SKIP.
- [ ] Hover (1.06) and press (0.94) tweens scale from the centre: `AnchorPoint` is 0.5, 0.5 and a child `UIScale` does the scaling.
- [ ] The close button is the 38 x 38 3D square, the same on every menu.
- [ ] Icons come from `CheckUIIcons` at their own aspect ratio, with no stretching.
- [ ] Sunbursts stop rotating while their menu is hidden.
- [ ] The menu fits a phone (scale about 0.52) and a large desktop (about 1.18). Test both in the Device Emulator.
- [ ] Every price shown matches the Creator Dashboard (see [[Developer Products and ProcessReceipt]]), and paid random items show their odds before purchase (see [[Roblox Policies Ratings and Compliance]]).

Related: [[UI Design Systems]], [[Menu Archetypes - Shop Settings Codes Rewards]], [[Responsive UI for Phone Tablet Console and PC]], [[ScreenGui Fundamentals]], [[Safe Areas and Insets]], [[UI Asset Pipeline]].

## Connected notes
<!-- auto-links:start -->
[[Check-UI Release Notes]] · [[Skill - Roblox UI Builder]] · [[AI Skills Start Here]] · [[Third-Party Skill - Obsidian Skills]] · [[Skill - Roblox System Builder]] · [[Cookbook - UI]]
<!-- auto-links:end -->
