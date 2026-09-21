class_name FishSpecies
extends Resource
## Authoring data for one fish type (.tres in data/species/).

@export var id: StringName = &"orange"
@export var display_name: String = "Orange Fish"
@export var texture: Texture2D
## Extra scale on top of the stage scale (long fish look better slightly smaller).
@export_range(0.5, 2.0, 0.05) var base_scale: float = 1.0
## Rarer species get a lower weight when a crate picks a fish.
@export_range(0.1, 10.0, 0.1) var rarity_weight: float = 1.0
## Coins per minute produced at stage 0, 1, 2.
@export var idle_coins_per_minute: Array[float] = [0.5, 1.0, 2.0]
## Feedings required to leave stage 0 and stage 1.
@export var feeds_to_grow: Array[int] = [3, 6]


func idle_rate_for_stage(stage: int) -> float:
	if idle_coins_per_minute.is_empty():
		return 0.0
	return idle_coins_per_minute[clampi(stage, 0, idle_coins_per_minute.size() - 1)]


func feeds_needed(stage: int) -> int:
	if stage >= feeds_to_grow.size():
		return 0
	return feeds_to_grow[stage]
