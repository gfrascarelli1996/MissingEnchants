# Changelog

## 1.0.0

- First release
- Automatic scan when entering a dungeon, raid, or M+ (`PLAYER_ENTERING_WORLD` + `IsInInstance`)
- Enchant detection via item link parsing (locale-independent, no tooltip text)
- Empty gem socket detection via `C_Item.GetItemStats` + gems in the item link
- Chat report + dismissable popup, both independently toggleable
- Slash command `/missingench` (alias `/menc`) for manual scan anywhere
- Settings panel via `Settings.RegisterAddOnCategory` to toggle enchant check, gem check, popup, chat, instance-only scope, and scan delay
- Compatible with Midnight 12.0.7 (Interface 120007)
