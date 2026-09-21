extends Node
## Autoload: GameState. Owns the authoritative TankState and all rules that mutate it.
## UI and entities call the request methods below and react to EventBus signals.
## No sprites, no scene references live here.

enum FeedResult { FED, GREW, FULL, NO_FOOD, NOT_FOUND }

const MAX_IDLE_FPS_BACKGROUND := 5

var catalog: Catalog = preload("res://data/catalog.tres")
var config: EconomyConfig = preload("res://economy/economy_config.tres")
var state: TankState
var feed_mode: bool = false

var _idle_per_second: float = 0.0
var _coin_fraction: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	OS.low_processor_usage_mode = true
	_rng.randomize()

	state = SaveService.load_state()
	if state == null:
		state = TankState.new()
		state.coins = config.starting_coins
		state.food = config.starting_food
	_recompute_idle_rate()
	_apply_offline_progress()
	state.last_unix = Time.get_unix_time_from_system()


func _process(delta: float) -> void:
	if _idle_per_second <= 0.0:
		return
	_coin_fraction += _idle_per_second * delta
	if _coin_fraction >= 1.0:
		var whole := int(floor(_coin_fraction))
		_coin_fraction -= whole
		_set_coins(state.coins + whole)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			save()
			Engine.max_fps = MAX_IDLE_FPS_BACKGROUND
		NOTIFICATION_APPLICATION_RESUMED:
			Engine.max_fps = 0
			_apply_offline_progress()
			state.last_unix = Time.get_unix_time_from_system()
		NOTIFICATION_WM_CLOSE_REQUEST:
			save()


# --- Persistence -------------------------------------------------------------

func save() -> void:
	EventBus.save_requested.emit()
	state.last_unix = Time.get_unix_time_from_system()
	SaveService.save_state(state)


## Testing helper: drop the save files and replace the live tank with a fresh start.
## Does not write a new file; the next natural save does that.
func reset_progress() -> void:
	set_feed_mode(false)
	_coin_fraction = 0.0
	state = TankState.new()
	state.last_unix = Time.get_unix_time_from_system()
	_set_coins(config.starting_coins)
	_set_food(config.starting_food)
	_recompute_idle_rate()
	SaveService.delete_save()


func make_id(prefix: String) -> String:
	return "%s_%d_%08x" % [prefix, int(Time.get_unix_time_from_system()), randi()]


# --- Economy -----------------------------------------------------------------

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	_set_coins(state.coins + amount)


func try_spend(amount: int) -> bool:
	if amount < 0 or state.coins < amount:
		return false
	_set_coins(state.coins - amount)
	return true


func try_buy_food(count: int) -> bool:
	var cost := config.food_price * count
	if count <= 0 or not try_spend(cost):
		return false
	_set_food(state.food + count)
	save()
	return true


func set_feed_mode(active: bool) -> void:
	if active and state.food <= 0:
		active = false
	if feed_mode == active:
		return
	feed_mode = active
	EventBus.feed_mode_changed.emit(feed_mode)


func idle_coins_per_minute() -> float:
	return _idle_per_second * 60.0


# --- Crates ------------------------------------------------------------------

func can_add_crate() -> bool:
	return state.crates.size() < config.max_crates


func add_crate(crate: CrateData) -> void:
	state.crates.append(crate)
	EventBus.crate_added.emit(crate)


func remove_crate(crate_id: String) -> void:
	var crate := state.find_crate(crate_id)
	if crate == null:
		return
	state.crates.erase(crate)
	EventBus.crate_removed.emit(crate_id)


func get_crate(crate_id: String) -> CrateData:
	return state.find_crate(crate_id)


func sync_crate_position(crate_id: String, x: float) -> void:
	var crate := state.find_crate(crate_id)
	if crate:
		crate.x = x


# --- Fish --------------------------------------------------------------------

func can_add_fish() -> bool:
	return state.fish.size() < config.max_fish


func spawn_fish(species: FishSpecies, at: Vector2, default_name: String) -> FishData:
	var fish := FishData.new()
	fish.id = make_id("fish")
	fish.species_id = species.id
	fish.name = default_name
	fish.x = at.x
	fish.y = at.y
	fish.facing = 1 if _rng.randf() < 0.5 else -1
	state.fish.append(fish)
	_recompute_idle_rate()
	EventBus.fish_added.emit(fish)
	return fish


func rename_fish(fish_id: String, new_name: String) -> void:
	var fish := state.find_fish(fish_id)
	if fish == null:
		return
	var clean := new_name.strip_edges().left(14)
	if clean.is_empty():
		return
	fish.name = clean
	EventBus.fish_changed.emit(fish)
	save()


func feed_fish(fish_id: String) -> FeedResult:
	var fish := state.find_fish(fish_id)
	if fish == null:
		return FeedResult.NOT_FOUND
	if state.food <= 0:
		set_feed_mode(false)
		return FeedResult.NO_FOOD
	var species := catalog.get_species(fish.species_id)
	if fish.stage >= FishData.MAX_STAGE:
		return FeedResult.FULL

	_set_food(state.food - 1)
	fish.growth += 1
	var result := FeedResult.FED
	if fish.growth >= species.feeds_needed(fish.stage):
		fish.stage += 1
		fish.growth = 0
		result = FeedResult.GREW
		_recompute_idle_rate()
	EventBus.fish_changed.emit(fish)
	if state.food <= 0:
		set_feed_mode(false)
	save()
	return result


func sync_fish_transform(fish_id: String, pos: Vector2, facing: int) -> void:
	var fish := state.find_fish(fish_id)
	if fish:
		fish.x = pos.x
		fish.y = pos.y
		fish.facing = facing


# --- Internals ---------------------------------------------------------------

func _set_coins(value: int) -> void:
	state.coins = clampi(value, 0, TankState.MAX_COINS)
	EventBus.coins_changed.emit(state.coins)


func _set_food(value: int) -> void:
	state.food = clampi(value, 0, TankState.MAX_FOOD)
	EventBus.food_changed.emit(state.food)


func _recompute_idle_rate() -> void:
	var per_minute := 0.0
	for fish in state.fish:
		var species := catalog.get_species(fish.species_id)
		if species:
			per_minute += species.idle_rate_for_stage(fish.stage)
	_idle_per_second = per_minute / 60.0
	EventBus.idle_rate_changed.emit(per_minute)


func _apply_offline_progress() -> void:
	if state.last_unix <= 0.0 or _idle_per_second <= 0.0:
		return
	var away := Time.get_unix_time_from_system() - state.last_unix
	var seconds := clampf(away, 0.0, float(config.offline_cap_seconds))
	var earned := int(floor(seconds * _idle_per_second))
	if earned > 0:
		_set_coins(state.coins + earned)
		EventBus.offline_reward.emit(earned, int(seconds))
