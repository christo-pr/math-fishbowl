extends Node2D
## Lays out sand, seaweed, rocks and drifting bubbles from the Kenney tank pack.
## Rebuilds on viewport resize so wider phones simply get a longer beach.

const TILE := 64.0
const ART := "res://Art/TankSpritesheet/Vector/"

const SAND_TOP := preload(ART + "terrain_sand_top_g.svg")
const SAND_FILL: Array[Texture2D] = [
	preload(ART + "terrain_sand_a.svg"),
	preload(ART + "terrain_sand_b.svg"),
	preload(ART + "terrain_sand_c.svg"),
	preload(ART + "terrain_sand_d.svg"),
]
const BACK_PLANTS: Array[Texture2D] = [
	preload(ART + "background_seaweed_a.svg"),
	preload(ART + "background_seaweed_b.svg"),
	preload(ART + "background_seaweed_c.svg"),
	preload(ART + "background_seaweed_d.svg"),
	preload(ART + "background_seaweed_e.svg"),
	preload(ART + "background_seaweed_f.svg"),
	preload(ART + "background_rock_a.svg"),
	preload(ART + "background_rock_b.svg"),
]
const FRONT_PLANTS: Array[Texture2D] = [
	preload(ART + "seaweed_green_a.svg"),
	preload(ART + "seaweed_green_b.svg"),
	preload(ART + "seaweed_green_c.svg"),
	preload(ART + "seaweed_pink_a.svg"),
	preload(ART + "seaweed_pink_b.svg"),
	preload(ART + "seaweed_orange_a.svg"),
	preload(ART + "seaweed_grass_a.svg"),
	preload(ART + "seaweed_grass_b.svg"),
	preload(ART + "rock_a.svg"),
	preload(ART + "rock_b.svg"),
]
const BUBBLES: Array[Texture2D] = [
	preload(ART + "bubble_a.svg"),
	preload(ART + "bubble_b.svg"),
	preload(ART + "bubble_c.svg"),
]

const DECOR_SEED := 20260915
const BUBBLE_COUNT := 6

var _back: Node2D
var _sand: Node2D
var _front: Node2D
var _bubbles: Node2D


func _ready() -> void:
	_back = Node2D.new()
	_sand = Node2D.new()
	_front = Node2D.new()
	_bubbles = Node2D.new()
	for layer: Node2D in [_back, _sand, _front, _bubbles]:
		add_child(layer)
	get_viewport().size_changed.connect(_rebuild)
	_rebuild()


func _rebuild() -> void:
	var size := get_viewport_rect().size
	var floor_y := TankLayout.floor_y(size)
	var rng := RandomNumberGenerator.new()
	rng.seed = DECOR_SEED

	_clear(_back)
	_clear(_sand)
	_clear(_front)
	_clear(_bubbles)

	# Sand: one wavy top row then plain fill down to the bottom edge.
	var columns := int(ceil(size.x / TILE)) + 1
	for col in columns:
		var x := col * TILE + TILE * 0.5
		_place(_sand, SAND_TOP, Vector2(x, floor_y + TILE * 0.5))
		var y := floor_y + TILE * 1.5
		while y - TILE * 0.5 < size.y:
			_place(_sand, SAND_FILL[rng.randi_range(0, SAND_FILL.size() - 1)], Vector2(x, y))
			y += TILE

	# Faded background plants sit on the sand line behind the fish.
	var back_count := maxi(4, int(size.x / 180.0))
	for i in back_count:
		var tex := BACK_PLANTS[rng.randi_range(0, BACK_PLANTS.size() - 1)]
		var sprite := _place(_back, tex, Vector2(rng.randf_range(20.0, size.x - 20.0), floor_y - TILE * 0.5 + 6.0))
		sprite.modulate = Color(1, 1, 1, 0.55)
		sprite.scale = Vector2.ONE * rng.randf_range(1.0, 1.6)

	# Bright plants and rocks in front; crates land between them.
	var front_count := maxi(5, int(size.x / 150.0))
	for i in front_count:
		var tex := FRONT_PLANTS[rng.randi_range(0, FRONT_PLANTS.size() - 1)]
		var sprite := _place(_front, tex, Vector2(rng.randf_range(20.0, size.x - 20.0), floor_y - TILE * 0.5 + 4.0))
		sprite.scale = Vector2.ONE * rng.randf_range(0.9, 1.3)
		if rng.randf() < 0.5:
			sprite.flip_h = true

	for i in BUBBLE_COUNT:
		_spawn_bubble(rng, size, floor_y, true)


func _spawn_bubble(rng: RandomNumberGenerator, size: Vector2, floor_y: float, stagger: bool) -> void:
	var tex := BUBBLES[rng.randi_range(0, BUBBLES.size() - 1)]
	var start_y := floor_y - 10.0
	if stagger:
		start_y = rng.randf_range(TankLayout.TOP_HUD_SPACE, floor_y)
	var bubble := _place(_bubbles, tex, Vector2(rng.randf_range(40.0, size.x - 40.0), start_y))
	bubble.scale = Vector2.ONE * rng.randf_range(0.35, 0.7)
	bubble.modulate = Color(1, 1, 1, 0.75)
	var duration := rng.randf_range(6.0, 11.0) * ((start_y - 40.0) / floor_y)
	var tween := bubble.create_tween()
	tween.tween_property(bubble, "position:y", 40.0, maxf(duration, 0.5)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(bubble, "position:x", bubble.position.x + rng.randf_range(-40.0, 40.0), maxf(duration, 0.5))
	tween.tween_property(bubble, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void:
		bubble.queue_free()
		if is_inside_tree():
			_spawn_bubble(rng, get_viewport_rect().size, TankLayout.floor_y(get_viewport_rect().size), false)
	)


func _place(parent: Node2D, texture: Texture2D, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = at
	parent.add_child(sprite)
	return sprite


func _clear(layer: Node2D) -> void:
	for child in layer.get_children():
		child.queue_free()
