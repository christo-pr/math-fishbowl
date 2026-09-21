extends Node2D
## Drops crates over time and keeps the crate nodes in sync with GameState.
## Data lives in GameState; this node only owns the visual/physics instances.

const CRATE_SCENE := preload("res://entities/crate/crate.tscn")
const DROP_HEIGHT := -80.0
const RESTORE_HEIGHT_ABOVE_FLOOR := 70.0

@export var crates_root: Node2D

var _nodes: Dictionary = {} # crate_id -> Crate
var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	EventBus.crate_added.connect(_on_crate_added)
	EventBus.crate_removed.connect(_on_crate_removed)
	# Restore crates that were left on the sand last session.
	for crate in GameState.state.crates:
		_instantiate(crate, true)
	_timer = GameState.config.first_crate_delay


func _process(delta: float) -> void:
	if not GameState.can_add_crate():
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer = GameState.config.crate_spawn_interval
		_spawn_random()


func get_crate_node(crate_id: String) -> Crate:
	return _nodes.get(crate_id) as Crate


func _spawn_random() -> void:
	var def := GameState.catalog.random_crate(_rng)
	if def == null:
		return
	var span := TankLayout.crate_drop_range(get_viewport_rect().size)
	var crate := CrateData.new()
	crate.id = GameState.make_id("crate")
	crate.size = def.id
	crate.x = _rng.randf_range(span.x, span.y)
	GameState.add_crate(crate)


func _on_crate_added(crate: CrateData) -> void:
	_instantiate(crate, false)


func _instantiate(crate: CrateData, restoring: bool) -> void:
	if _nodes.has(crate.id):
		return
	var def := GameState.catalog.get_crate(crate.size)
	var node := CRATE_SCENE.instantiate() as Crate
	var floor_y := TankLayout.floor_y(get_viewport_rect().size)
	node.position = Vector2(crate.x, floor_y - RESTORE_HEIGHT_ABOVE_FLOOR if restoring else DROP_HEIGHT)
	crates_root.add_child(node)
	node.setup(crate, def)
	_nodes[crate.id] = node


func _on_crate_removed(crate_id: String) -> void:
	var node := _nodes.get(crate_id) as Crate
	_nodes.erase(crate_id)
	if node:
		node.break_open()
