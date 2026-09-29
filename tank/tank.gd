extends Node2D
## Main hub scene. Wires world <-> UI through EventBus and GameState; owns no rules itself.

const DEFAULT_NAMES: Array[String] = [
	"Bubbles", "Finn", "Splash", "Coral", "Pearl", "Goldie", "Pip", "Nemo",
	"Wiggles", "Dory", "Marlin", "Sunny", "Ziggy", "Luna", "Bolt", "Momo",
]
const FULL_TANK_BONUS_DIVISOR := 2

@onready var _bounds: StaticBody2D = %Bounds
@onready var _crate_spawner: Node2D = %CrateSpawner
@onready var _hud: Control = %Hud
@onready var _quiz: Control = %QuizOverlay
@onready var _shop: Control = %ShopPanel
@onready var _name_dialog: Control = %NameFishDialog

var _pending_names: Array[String] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_build_bounds()
	get_viewport().size_changed.connect(_build_bounds)

	EventBus.quiz_requested.connect(_on_quiz_requested)
	_quiz.solved.connect(_on_crate_solved)
	_hud.shop_pressed.connect(_shop.open)
	_name_dialog.confirmed.connect(_on_name_confirmed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		# Clear the selected fish when tapped anywhere on the screen
		GameState.select_fish("")

# --- Quiz flow ---------------------------------------------------------------

func _on_quiz_requested(crate_id: String) -> void:
	if _quiz.visible or _name_dialog.visible:
		return
	var crate := GameState.get_crate(crate_id)
	if crate == null:
		return
	_shop.close()
	_quiz.open(crate_id, GameState.catalog.get_crate(crate.size))


func _on_crate_solved(crate_id: String) -> void:
	var crate := GameState.get_crate(crate_id)
	if crate == null:
		return
	var def := GameState.catalog.get_crate(crate.size)
	var crate_node: Crate = _crate_spawner.get_crate_node(crate_id)
	var spawn_at := crate_node.global_position if crate_node else Vector2(crate.x, TankLayout.floor_y(get_viewport_rect().size) - 60.0)
	spawn_at = TankLayout.clamp_to_water(get_viewport_rect().size, spawn_at)

	GameState.remove_crate(crate_id)
	GameState.add_coins(def.coin_reward)

	var fish_count := _rng.randi_range(def.fish_min, def.fish_max)
	for i in fish_count:
		if GameState.can_add_fish():
			var species := GameState.catalog.random_species(_rng)
			var offset := Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(-30.0, 30.0))
			var fish := GameState.spawn_fish(species, spawn_at + offset, _random_name())
			_pending_names.append(fish.id)
		else:
			# Tank is full: the crate still pays out.
			GameState.add_coins(maxi(1, int(def.coin_reward / float(FULL_TANK_BONUS_DIVISOR))))

	GameState.save()
	_show_next_name_dialog()


# --- Naming ------------------------------------------------------------------

func _show_next_name_dialog() -> void:
	if _pending_names.is_empty():
		return
	var fish_id: String = _pending_names.pop_front()
	var fish := GameState.state.find_fish(fish_id)
	if fish == null:
		_show_next_name_dialog()
		return
	_name_dialog.open(fish, GameState.catalog.get_species(fish.species_id))


func _on_name_confirmed(fish_id: String, new_name: String) -> void:
	GameState.rename_fish(fish_id, new_name)
	_show_next_name_dialog()


func _random_name() -> String:
	return DEFAULT_NAMES[_rng.randi_range(0, DEFAULT_NAMES.size() - 1)]


# --- Physics bounds ----------------------------------------------------------

func _build_bounds() -> void:
	for child in _bounds.get_children():
		child.queue_free()
	var size := get_viewport_rect().size
	var floor_y := TankLayout.floor_y(size)
	var wall := TankLayout.WALL_THICKNESS
	_add_box(Vector2(size.x * 0.5, floor_y + TankLayout.SAND_HEIGHT * 0.5), Vector2(size.x + wall * 2.0, TankLayout.SAND_HEIGHT))
	_add_box(Vector2(-wall * 0.5, size.y * 0.5 - 400.0), Vector2(wall, size.y + 800.0))
	_add_box(Vector2(size.x + wall * 0.5, size.y * 0.5 - 400.0), Vector2(wall, size.y + 800.0))


func _add_box(center: Vector2, extents: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = extents
	shape.shape = rect
	shape.position = center
	_bounds.add_child(shape)
