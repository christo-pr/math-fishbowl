extends Node2D
## Holds every Fish node and mirrors GameState.state.fish.

const FISH_SCENE := preload("res://entities/fish/fish.tscn")

var _nodes: Dictionary = {} # fish_id -> Fish


func _ready() -> void:
	EventBus.fish_added.connect(_on_fish_added)
	EventBus.fish_removed.connect(_on_fish_removed)
	for fish in GameState.state.fish:
		_instantiate(fish)


func get_fish_node(fish_id: String) -> Fish:
	return _nodes.get(fish_id) as Fish


func _on_fish_added(fish: FishData) -> void:
	var node := _instantiate(fish)
	if node:
		node.play_spawn()

func _on_fish_removed(fish_id: String) -> void:
	var node := _nodes.get(fish_id) as Fish
	_nodes.erase(fish_id)
	if node:
		node.queue_free()


func _instantiate(fish: FishData) -> Fish:
	if _nodes.has(fish.id):
		return null
	var species := GameState.catalog.get_species(fish.species_id)
	var node := FISH_SCENE.instantiate() as Fish
	add_child(node)
	node.setup(fish, species)
	_nodes[fish.id] = node
	return node
