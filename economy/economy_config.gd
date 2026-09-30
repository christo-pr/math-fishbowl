class_name EconomyConfig
extends Resource
## Tunables for coins, food, idle income and spawning (economy/economy_config.tres).

@export_group("Start")
@export var starting_coins: int = 20
@export var starting_food: int = 3

@export_group("Shop")
@export var food_price: int = 5

@export_group("Idle")
## Offline earnings never exceed this many seconds (8h default).
@export var offline_cap_seconds: int = 8 * 60 * 60

@export_group("Sushi")
@export var sushi_minutes: float = 10.0

@export_group("Tank limits")
@export var max_fish: int = 12
@export var max_crates: int = 5

@export_group("Crate spawning")
@export var first_crate_delay: float = 2.0
@export var crate_spawn_interval: float = 20.0

@export_group("Fish life")
## Hours from full (1.0) to dead (0.0) if never fed.
@export_range(1.0, 168.0, 0.5) var life_hours_full: float = 24.0
## Hours of life on pellete adds.
@export_range(1.0, 48.0, 0.1) var life_hours_per_feed: float = 6.0
## Life below this is Hungry. At or above it the fist is content.
@export_range(0.005, 0.99, 0.01) var band_hungry_below: float = 0.75
@export_range(0.005, 0.99, 0.01) var band_starving_below: float = 0.50
@export_range(0.005, 0.99, 0.01) var band_almost_dead_below: float = 0.25

func life_decay_per_second() -> float:
	return 1.0 / maxf(life_hours_full * 3600.0, 1.0)


func life_gain_per_feed() -> float:
	if life_hours_full <= 0.0:
		return 0.0
	return clampf(life_hours_per_feed / life_hours_full, 0.0, 1.0)
