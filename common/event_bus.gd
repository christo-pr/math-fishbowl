extends Node
## Global signal bus (Autoload: EventBus).
## Carries typed events between systems. Holds NO game data.
## Signals travel up (GameState -> UI/entities); calls travel down.

# A bus only declares signals; emitters live elsewhere.
@warning_ignore_start("unused_signal")

# --- Economy ---
signal coins_changed(coins: int)
signal food_changed(food: int)
signal idle_rate_changed(coins_per_minute: float)
signal offline_reward(coins: int, seconds_away: int)

# --- Crates ---
signal crate_added(crate: CrateData)
signal crate_removed(crate_id: String)
signal quiz_requested(crate_id: String)

# --- Fish ---
signal fish_added(fish: FishData)
signal fish_changed(fish: FishData)
signal feed_mode_changed(active: bool)
signal fish_selection_changed(fish_id: String)
signal fish_removed(fish_id: String)

# --- System ---
## Emitted right before serializing so entities can push transforms into GameState.
signal save_requested
