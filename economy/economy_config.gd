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

@export_group("Tank limits")
@export var max_fish: int = 12
@export var max_crates: int = 5

@export_group("Crate spawning")
@export var first_crate_delay: float = 2.0
@export var crate_spawn_interval: float = 20.0
