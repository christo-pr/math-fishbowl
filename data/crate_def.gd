class_name CrateDef
extends Resource
## Authoring data for one crate size (.tres in data/crates/).

@export var id: StringName = &"small"
@export var display_name: String = "Small Crate"
@export var texture: Texture2D
@export var band: MathBand
@export_range(1, 10) var problem_count: int = 2
@export var coin_reward: int = 10
@export_range(0, 5) var fish_min: int = 1
@export_range(0, 5) var fish_max: int = 1
## How often this size is chosen by the spawner (relative weight).
@export_range(0.0, 100.0) var spawn_weight: float = 50.0
@export_range(0.3, 3.0, 0.05) var sprite_scale: float = 1.0
@export var collider_size: Vector2 = Vector2(52, 52)
@export_range(0.5, 20.0, 0.5) var mass: float = 1.0
