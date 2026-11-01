# Beyy Hub — Crack the Geode!

Native Roblox menu with collection, camp, egg and GEO-MAG upgrade automation.

## Load

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sceneton/geode/main/loader.lua?refresh=" .. tostring(os.time())))()
```

Right Ctrl opens/closes the menu. Startup automatically restores the saved default config, including its enabled automation. With no saved config, automation starts off. A queued teleport reload restores the enabled options from the preceding session instead of the config's automation toggles.

Use **Save Config** after changing settings. **Auto-load Saved Config** defaults on; turn it off and save to disable restoration on future manual loads. Older saved configs automatically migrate to this behavior. Repeated or concurrent loaders reuse the active menu.

A local cached copy can also be loaded:

```lua
loadstring(readfile("GeodeHub/loader.lua"))()
```

## Features

- **Auto Geode Pickup:** selects valid nearby mound targets, uses the equipped owned tool, respects its calculated cooldown and a configurable range up to 26 studs. Pet feedback is excluded from tool confirmation counts.
- **Auto Crack and Sell:** starts a fixed 10-second window after the first bag-count change. Later pickups do not restart it. It suspends collection, deposits, enters a free station, uses Crack All, leaves, sells, and returns to the original pickup position. A fresh bag change starts the next window.
- **Auto Upgrade GEO-MAG 3000:** buys only Pull Power and Pulse Speed with run cash, checks affordability and replicated levels, and waits during camp cycles.
- **Auto Open Haunted Egg:** opens three per request, using the current candy price (180 at inspection). Requests are sequential; Busy replies back off. It waits for sufficient candy and stops on event expiry or other errors.
- **Queue on Teleport:** reloads this hub after real Roblox teleports, with cached fallback and recent enabled settings.
- Save/Load config, diagnostics export, and Unload.

Crack All uses an existing pass or stored credits. The hub does not buy passes, credits, candy packs or Robux products. Closing the menu keeps enabled features running; Unload stops them and disables its teleport continuation.

**Full Auto Farm Wins is not implemented yet.** Boss combat, win confirmation and replay still require integration/testing. The current pickup maximum is 26 studs, even though the magnet's native client can calculate a longer reach.

## Loader and cache recovery

Loader v2 rejects empty downloads, incomplete content, missing hub markers, and compile failures before replacing a cache. It maintains a validated `GeodeHub/main.backup.lua` and reports startup errors.

This fixes a confirmed issue where an HTTP request returned success with an empty body: empty Lua compiled, overwrote the cache, and silently did nothing.

## Local files

| File | Purpose |
|---|---|
| `GeodeHub/main.lua` | Cached hub |
| `GeodeHub/main.backup.lua` | Validated fallback |
| `GeodeHub/teleport_state.json` | Recent enabled options for teleport continuation |
| `WindUI/GeodeHub/config/default.json` | Manually saved config |
| `Geode/auto_pickup_diagnostics.json` | Pickup diagnostics |
| `Geode/auto_crack_sell_diagnostics.json` | Camp-cycle diagnostics |
| `Geode/haunted_egg_diagnostics.json` | Egg requests/results |
| `Geode/magnet_upgrade_diagnostics.json` | Upgrade confirmations |

Loading a saved config can enable its saved automation toggles.

## Passive transition recorder

A separate observer records PlaceId, JobId, OnTeleport events, phase/run-start changes, and queued arrivals. It makes no gameplay requests.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/sceneton/geode/main/transition-recorder.lua?refresh=" .. tostring(os.time())))()
```

Logs: `Geode/transition_events.jsonl` and `Geode/transition_latest.json`.

Stop it with:

```lua
getgenv().GeodeTransitionRecorder.Stop()
```

A changed JobId establishes a server change. A changed RunStart in the same surviving observer/job indicates an in-server run reset. Compare the actual Play Again transition; a custom loading screen alone does not distinguish the two.

## Validation and limits

The pickup loop and camp sequence were exercised live. Egg single-triple and overlapping-triple requests were tested with permission; simultaneous requests received Busy rejections. Scheduling, candy limits, upgrades, cleanup, bag-change timing, queue lifecycle and loader recovery have focused local tests. Some controller integrations still need ordinary live observation.

The raw game dump, player state, and diagnostic logs are kept local and are not included in this repository.


