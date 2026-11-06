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

- **Auto Endless Mode:** follows a circular bottom orbit, offset 0.5 studs inside the fitted radius (2 studs inward from the previous orbit). Radius, height and camera standoff stay fixed for the whole depth, and the character stays level while firing. The mining orbit is raised 10 studs above the configured hover clearance (6 studs higher than the previous orbit). Mining uses a steady inward lower-pile aim with the previous 10-degree upward offset removed; it does not select or track individual geodes. Boss targeting keeps its own aim. Each full 360-degree lap takes 7 uninterrupted seconds. The circular path is fitted from the full generated column layout with its axis pinned to the boss, so depleted sectors cannot pull it inward. Orbit angle carries across mining depths. The mining camera sweeps with the orbit using smoothed, rate-limited turns and a steady orientation relative to the pile. Per-geode target queries and camera retargeting have been removed. Mining and boss combat use `Tools.setUse(true, "button")`, with the direct collector suspended independently of camp flags. Held fire releases for camp, native menus/perks, boss defeat, death, mode changes and shutdown; it resumes when native firing is allowed again. If firing makes no progress for 1.5 seconds while allowed, it reasserts the native hold to recover from silent input/focus resets. Recovery attempts are counted in diagnostics. Focus-loss/regain events and native input releases additionally schedule a guarded hold reassertion after 50 ms; unfocused windows receive a native button keepalive every 250 ms while firing is allowed. These calls retain native cooldown/raycast checks and do not move the OS cursor or simulate desktop clicks. Focus state, keepalives and last recovery reason are included in diagnostics. The shared boss controller receives the same protection. The controller manages cash upgrades and camp visits, targets boss weak points with normal hits between openings, and resumes mining at the next depth. Camp visits and manual cracking temporarily own movement and camera. Requires an owned GEO-MAG 3000 and waits outside Endless mode. It does not cash out, escape or replay.
- **Endless Hover Clearance:** defaults to 6.5 studs (twice the older needle character clearance of 3.25), adjustable from 2 to 20 studs. Both this setting and Auto Endless save to config and teleport continuation.
- **Automatic Q / Overcharge:** included in Auto Endless. Uses the native `MasteryHUD.useSkill()` function only during active mining with the equipped, unlocked GEO-MAG ability. It pauses for boss combat, camp, menus and perk selection. Activations are confirmed by replicated buff/cooldown state; manual Q cooldowns are respected and unconfirmed attempts back off. Base Overcharge is a five-second buff with 3x pull radius and 2x pull rate, on a 45-second cooldown; native mastery/perk stats supply the effective values. Ability status and confirmed uses are shown in the Endless tab and diagnostics. A live activation was confirmed with an active Overcharge buff and a replicated ready timestamp.
- **Auto Select Perk:** ranks Endless offers for a GEO-MAG-only run and uses the native card-pick function once the cards are ready. It handles offers already open when enabled, scores actual rarity/stack counts, and confirms choices through server events or replicated perk counts. It sends one selection per offer and does not reroll. This separate toggle defaults off and saves to config and teleport continuation.
- **Auto Geode Pickup:** selects valid nearby mound targets, uses the equipped owned tool, respects its calculated cooldown and a configurable range up to 26 studs. Pet feedback is excluded from tool confirmation counts.
- **Auto Crack and Sell:** starts a fixed 10-second window after the first bag-count change. Later pickups do not restart it. It suspends collection, deposits, enters a free station, uses Crack All, leaves, sells, and returns to the original pickup position. A fresh bag change starts the next window.
- **Auto Upgrade GEO-MAG 3000:** buys only Pull Power and Pulse Speed with run cash, checks affordability and replicated levels, and waits during camp cycles.
- **Class Mutations:** dedicated tab with owned-class selector, Normal/Lucky Scroll selection, target mutation and a 1–1000 roll limit per start (default 10). Rolls sequentially through the native Mutations remote without the animation, respecting the native minimum request interval. Stops at the target or higher, the request limit, no scrolls, unowned class, or a failed response. Keeps the better mutation through server logic. Parameters save to config; rolling starts off after reloading and is not resumed by teleport. Changing parameters applies on the next start. An in-flight request may finish after Stop; no additional requests follow.
- **Camp cycle speed:** approaches wait 0.15 seconds for movement replication, or skip that delay when already in range. Station exit waits for the server Leave acknowledgment, then advances immediately, and sale settlement can finish as soon as the cash update arrives. Active cycles poll at 30 ms; idle polling remains 100 ms. Collection/repeat delays remain configurable and unchanged.
- **Anti-AFK:** opt-in toggle under Main → AFK Protection. Connects to LocalPlayer.Idled while enabled and sends a balanced, unbound F15 key tap through VirtualInputManager, with a 20-second debounce. No polling loop, mouse clicks, camera writes or character movement. Off/unload disconnects its listener; input failures are shown in status and disable protection. Saves to config and queued teleport state. The input down/up pair was verified in the connected client; a full idle-timeout session has not been verified.
- **Auto Boss Fight:** separate opt-in toggle under Main → Boss Fight. Uses the owned GEO-MAG 3000 and native held fire in standard or Endless boss phases, moving and aiming at active weak points and resuming normal body hits between openings. Waits during mining, lobby, death, native control/menu blocks and manual camp sessions; releases its character/camera ownership when combat ends or the option is disabled. Shares the existing Auto Endless combat controller to avoid duplicate movement or attack workers. It does not enable mining/camp/upgrade automation. Saves to config and teleport continuation. Phase/ownership/cleanup tests pass; a standalone standard boss run still needs live verification.
- **Experimental loading removal:** opt-in toggle under Experimental. Hides only MTG loading/transit overlays, shortens cosmetic LightSettle/minimum-display/fade settings, and uses native Intro.forceSkip after client/character/map readiness. Preserves readiness waits and uses native intro/black-hold cleanup. Does not skip boss/results cutscenes or directly control camera/mouse properties. Settings save to config and enabled state carries through teleport continuation. Off/unload restores owned settings and surviving overlays. Current loading timing adjustment uses the native Skip button closure when executor introspection is available; status reports success. Some loading may occur before the hub starts, so first-frame elimination is not guaranteed. Experimental: a full live transition remains unverified.
- **One sale per run:** Normal Auto Crack and Sell stops after the first server-confirmed sale and returns to the pickup position, regardless of cash earned or upgrade funding. A run-scoped completion marker prevents Auto Endless, respawns and hub reloads from rearming another trip in that run. New runs are eligible again. A mid-run update migrates an already completed sale from the prior hub where its timestamp belongs to the current run. Enable **Keep Cracking & Selling** for repeated trips; its delay slider sets 1–60 seconds between completed cycles. Upgrade purchasing remains independent and can continue with the available cash.
- **Auto Escape:** waits for Escape phase and LiftOpen, then finds the current CaveMap lift and moves above its floor, adapting to each chapter. It preserves facing direction, stops camp movement first, waits for the server's Escaped flag, and retries only if displaced (up to ten moves per character/round). The toggle saves to config and teleport continuation.
- **Auto Open Haunted Egg:** opens three per request, using the current candy price (180 at inspection). Requests are sequential; Busy replies back off. It waits for sufficient candy and stops on event expiry or other errors.
- **Queue on Teleport:** reloads this hub after real Roblox teleports, with cached fallback and recent enabled settings.
- Save/Load config, diagnostics export, and Unload.

Crack All uses an existing pass or stored credits. The hub does not buy passes, credits, candy packs or Robux products. Closing the menu keeps enabled features running; Unload stops them and disables its teleport continuation.

**Standard Auto Farm Wins is not implemented yet.** Standard win replay still requires integration/testing. Auto Endless was tested live at 6.5-stud clearance: it completed one hover lap, sent 37 boss hit requests (8 targeting weak points), advanced from depth 45 to 46, and resumed Mining. Stopping restored character rotation. Sustained unattended operation and camp handoff during this mode still need longer live verification. Auto Escape was separately confirmed with the server's `Escaped=true` flag and is disabled in Endless mode. Escape polling, Endless movement and max-upgrade crack/sell shutdown run independently of menu status updates. The current pickup maximum is 26 studs, even though the magnet's native client can calculate a longer reach.

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
| `Geode/auto_endless_diagnostics.json` | Endless phase, hover/lap and boss-hit diagnostics |
| `Geode/auto_perk_diagnostics.json` | Offered card rankings, reasons, selection/confirmation events and current ranking context |

Loading a saved config can enable its saved automation toggles.

### GEO-MAG perk priorities

These are heuristic priorities for reaching more Endless depths, rather than a guaranteed optimum. Shortcut, recurring Oil Flask sustain, Eternal Flame and Wide Sweep are high priorities. Boss-damage and crack-power cards receive a modest priority boost (+8 base points early, +12 from depth 20, capped at 98 for the boss component). Strong boss cards can outrank ordinary mining picks; emergency oil and Shortcut retain priority. Rarity/stack count, existing modifiers and the square-root crack-power curve still affect their order. Emergency oil takes priority when less than a minute of effective burn time remains. Extra recurring oil is downgraded when the existing income covers the recently measured depth pace.

Speed perks use the active firing path's estimated timing floor: measured frame timing during Auto Endless native held fire, or the direct pickup loop's 50 ms floor otherwise. Bag perks are downgraded with unlimited capacity. Crack-power bonuses are evaluated through the boss damage square-root curve. Cash/value is more useful before GEO-MAG upgrades are maxed. Ability duration, cooldown, size and damage perks gain priority when automatic Overcharge is unlocked and active; ability cooldown perks are downgraded at the configured cooldown minimum. The ranking export includes the current order and the actual reasoning for each offered card.

The native selection path was checked live: an Epic Tempered card was selected over Gem Finder and Bottomless Luck and confirmed by the server. No rerolls were used.

The whole-pile scan measured five contour radii of approximately 33.5, 28.0, 21.9, 15.6 and 9.8 studs. Auto Endless now uses only the bottom contour (about 33.5 studs in that snapshot). Radius varies with angle, depth shape and depletion. The character path sits above the fitted slice by the configured hover clearance. Geometry tests covered all 1,577 columns in a live snapshot, with 13,387 generated blueprint cell locations and 3,785 deduplicated visible targets. Blueprint positions include already-mined cells; runtime planning uses remaining stack counts.

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

## Version 1.10.17 — updated native boss combat

Auto Boss Fight and the boss portion of Auto Endless use the native FIGHT slot (Weapon), whose style follows the game's BestCracker setting. Mining still uses GEO-MAG. The updated game locks collecting tools during boss combat; the previous controller repeatedly tried to equip Magnet and could never begin its attack loop.

Boss positioning now reads all configured weak-point slots, their replicated seat distances, and boss-specific shell seats. Normal-hit positioning uses the boss definition's HitRadius or its named HitParts through the native BossReach helper. Standoff is capped inside the current weapon style's reach plus the native boss reach allowance. Native Tools.setUse still owns attack cadence, combos, and hit validation; no extra hit remote spam is introduced.

Live compatibility tests on 6 November 2026: depth 5 Mother Geode HP 3887.87 to 0 within a six-second test (11 native Weapon hit events, 6 weak-point events); depth 10 Frostbound Mother HP 5821 to 0 within a six-second test (9 native Weapon hit events, 6 weak-point events). Those are local native hit-event counts plus observed server HP reduction, not individual server acknowledgments for every event. Irregular named boss shapes such as Warden/Scarab/Wyrm were inspected in the current client code and covered by target-planner tests; those shapes were not live-tested in this run.

The delivered bundle compiles at optimization levels 0 and 2. Focused boss-target, Endless lifecycle, held-fire, and hub integration checks pass. Diagnostic exports include selected boss tool, name/skin, target kind, weak-point ID and reach. The live hub was not reloaded for publication; the short test controllers were removed and the original controller restored.
