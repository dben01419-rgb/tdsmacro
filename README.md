# Strategies X TDS

Strategies X is a TDS strategy runner with compatibility support for the common short-form strategy API.

## Load the library

```lua
getgenv().Gatlify = false

local TDS = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dben01419-rgb/tdsmacro/main/TDS/MainSource.lua",
    true
))()
```

## Supported strategy format

The compatibility API supports `Loadout`, `Mode`, `GameInfo`, `Place`, `Upgrade`, `Ability`, `SetOption`, `VoteSkip`, `Ready`, `UnlockTimeScale`, and `TimeScale`.

Untimed short-form actions are not treated as wave `0`. They run as soon as possible, wait indefinitely for required tower instances, and retry until the game accepts each action:

```lua
TDS:Loadout("Farm", "Hacker", "DJ Booth", "Mercenary Base", "Cowboy")
TDS:Mode("Fallen")
TDS:GameInfo("Simplicity", {HiddenEnemies = true})
TDS:Ready()

TDS:Place("Farm", 10, 1, 10)
TDS:Upgrade(1)
TDS:SetOption(1, "Track", "Green")
```

Wave-header scripts using `-- [ Wave N ] --` are transformed by the `DevTest` loader. Direct `MainSource.lua` consumers should use explicit timing arguments when wave timing matters.

## Optional Gatlify

Enable it before loading the library:

```lua
getgenv().Gatlify = true
```

The option is disabled by default.
