class_name Fish
extends Area2D
## A named pet fish: wanders the water rect, flips to face its heading,
## and reacts to taps (pet or feed). Reads FishData; only GameState writes it.

const STAGE_SCALE: Array[float] = [0.7, 1.0, 1.35]
const PICK_RADIUS := 30.0
const MIN_SPEED := 40.0
const MAX_SPEED := 85.0
const ARRIVE_DISTANCE := 12.0
const BOB_AMPLITUDE := 3.0
const BOB_SPEED := 2.4
const FLOAT_TEXT_RISE := 46.0

const PELLET_TEXTURE := preload("res://entities/food/food_pellet.svg")

@onready var _sprite: Sprite2D = %Sprite
@onready var _shape: CollisionShape2D = %Shape
@onready var _name_label: Label = %NameLabel

var data: FishData
var species: FishSpecies

var _target := Vector2.ZERO
var _speed := 60.0
var _bob_time := 0.0
var _water := Rect2()
var _rng := RandomNumberGenerator.new()
var _facing := 1


func _ready() -> void:
	_rng.randomize()
	input_event.connect(_on_input_event)
	EventBus.fish_changed.connect(_on_fish_changed)
	EventBus.save_requested.connect(_on_save_requested)
	get_viewport().size_changed.connect(_update_water)
	_update_water()


func setup(p_data: FishData, p_species: FishSpecies) -> void:
	data = p_data
	species = p_species
	_facing = data.facing
	_sprite.texture = species.texture
	_sprite.flip_h = _facing < 0
	_name_label.text = data.name
	position = TankLayout.clamp_to_water(get_viewport_rect().size, Vector2(data.x, data.y))
	_apply_stage(false)
	_pick_target()


func play_spawn() -> void:
	var final_scale := _sprite.scale
	_sprite.scale = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", final_scale, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_float_text("New fish!", Color(0.15, 0.55, 0.9))


func _process(delta: float) -> void:
	_bob_time += delta * BOB_SPEED
	var to_target := _target - position
	if to_target.length() < ARRIVE_DISTANCE:
		_pick_target()
		return
	var step := to_target.normalized() * _speed * delta
	position += step
	if absf(step.x) > 0.01:
		_facing = 1 if step.x > 0.0 else -1
		_sprite.flip_h = _facing < 0
	_sprite.position.y = sin(_bob_time) * BOB_AMPLITUDE


# --- Interaction -------------------------------------------------------------

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not (event is InputEventScreenTouch) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	if GameState.feed_mode:
		_feed()
	else:
		_pet()


func _pet() -> void:
	_squash()
	_float_text("\u2665", Color(0.95, 0.35, 0.45))


func _feed() -> void:
	var result: GameState.FeedResult = GameState.feed_fish(data.id)
	match result:
		GameState.FeedResult.FED:
			_drop_pellet()
		GameState.FeedResult.GREW:
			_drop_pellet()
			_float_text("Grew!", Color(0.2, 0.7, 0.3))
		GameState.FeedResult.FULL:
			_float_text("Fully grown", Color(0.5, 0.5, 0.5))
		_:
			pass


func _on_fish_changed(changed: FishData) -> void:
	if data == null or changed.id != data.id:
		return
	_name_label.text = data.name
	var target_scale := _stage_scale()
	if not _sprite.scale.is_equal_approx(target_scale):
		_apply_stage(true)


func _on_save_requested() -> void:
	if data:
		GameState.sync_fish_transform(data.id, position, _facing)


# --- Visuals -----------------------------------------------------------------

func _stage_scale() -> Vector2:
	return Vector2.ONE * species.base_scale * STAGE_SCALE[clampi(data.stage, 0, STAGE_SCALE.size() - 1)]


func _apply_stage(animate: bool) -> void:
	var target := _stage_scale()
	var circle := CircleShape2D.new()
	circle.radius = PICK_RADIUS * target.x
	_shape.shape = circle
	_name_label.position.y = 26.0 + 14.0 * target.x
	if animate:
		var tween := create_tween()
		tween.tween_property(_sprite, "scale", target * 1.2, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(_sprite, "scale", target, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		_sprite.scale = target


func _squash() -> void:
	var base := _stage_scale()
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector2(base.x * 1.25, base.y * 0.8), 0.1)
	tween.tween_property(_sprite, "scale", base, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _drop_pellet() -> void:
	var pellet := Sprite2D.new()
	pellet.texture = PELLET_TEXTURE
	pellet.scale = Vector2.ONE * 0.4
	pellet.position = Vector2(0, -70)
	add_child(pellet)
	var tween := create_tween()
	tween.tween_property(pellet, "position", Vector2.ZERO, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_squash)
	tween.tween_property(pellet, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(pellet.queue_free)


func _float_text(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(160, 40)
	label.position = Vector2(-80, -60)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - FLOAT_TEXT_RISE, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


# --- Wandering ---------------------------------------------------------------

func _update_water() -> void:
	_water = TankLayout.water_rect(get_viewport_rect().size)
	if _target == Vector2.ZERO:
		_pick_target()


func _pick_target() -> void:
	if _water.size == Vector2.ZERO:
		return
	_target = Vector2(
		_rng.randf_range(_water.position.x, _water.end.x),
		_rng.randf_range(_water.position.y, _water.end.y)
	)
	_speed = _rng.randf_range(MIN_SPEED, MAX_SPEED)
