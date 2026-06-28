# MissingEnchants

> Step into a dungeon, raid, or M+. Get a heads-up if anything is missing an enchant or a gem.

A lightweight addon for **World of Warcraft Retail (Midnight)** that scans your equipped gear when you enter an instance and tells you, in chat and in a popup, every enchantable slot without an enchant and every empty gem socket. No more pulling the boss and realizing your bracers were bare.

---

## Features

- **Automatic scan on instance entry** — triggered by `PLAYER_ENTERING_WORLD` + `IsInInstance`, configurable to also run in the open world
- **Enchant check** — covers Chest, Wrist, Legs, Feet, Hands, both Rings, Cloak, Main Hand, and Off Hand
- **Gem socket check** — flags items with empty sockets across every equippable slot
- **Locale-independent detection** — reads `enchantID` and gem positions directly from the item link, so it works on every client language
- **Chat + popup** — both on by default and independently toggleable
- **Manual slash command** — `/missingench` (alias `/menc`) runs the scan anywhere, anytime
- **Settings panel** — toggle each check, switch off the popup, change the scan delay, all from Interface options

## Slash commands

```
/missingench         Run a manual scan
/menc                Same (short alias)
/menc config         Open the settings panel
```

## How it works

- **Enchants** — the addon parses your item link and reads the encoded `enchantID`. A value of `0` means the slot is unenchanted.
- **Gems** — it counts total sockets via `C_Item.GetItemStats` (the `EMPTY_SOCKET_*` keys) and compares against the gems present in the item link.

Both methods are deterministic and don't depend on tooltip text, so they work in every locale.

## Installation

- **CurseForge / WowUp / Wago** — search for **MissingEnchants**
- **Manual** — copy the `MissingEnchants` folder into `World of Warcraft\_retail_\Interface\AddOns\`

## Supported version

Retail — **Midnight** (Interface 12.0.7+).

## Source & issues

GitHub: <https://github.com/gfrascarelli1996/MissingEnchants>
Open an issue if you find a bug or want to suggest a feature.

## License

MIT — free to fork, modify, redistribute. See [LICENSE](LICENSE).

---

## Support development

MissingEnchants is free and always will be. If it saves you a wipe and you want to say thanks, a coffee is appreciated:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/hadorn96)
