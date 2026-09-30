class_name Crate
extends RigidBody2D
## A physics crate. Tap it to request a quiz; GameState decides what happens next.

const TAP_WOBBLE_SCALE := 1.12
const BREAK_DURATION := 0.35

@onready var _sprite: Sprite2D = %Sprite
@onready var _shape: CollisionShape2D = %Shape
var data: CrateData
var def: CrateDef

var _base_scale := Vector2.ONE
var _breaking := false


func _ready() -> void:
	input_event.connect(_on_input_event)
	EventBus.save_requested.connect(_on_save_requested)


func setup(p_data: CrateData, p_def: CrateDef) -> void:
	data = p_data
	def = p_def
	mass = def.mass
	_sprite.texture = def.texture
	_base_scale = Vector2.ONE * def.sprite_scale
	_sprite.scale = _base_scale
	# Each instance gets its own shape so sizes never leak between crates.
	var rect := RectangleShape2D.new()
	rect.size = def.collider_size
	_shape.shape = rect


func break_open() -> void:
	if _breaking:
		return
	_breaking = true
	input_pickable = false
	freeze = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sprite, "scale", _base_scale * 1.5, BREAK_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "modulate:a", 0.0, BREAK_DURATION)
	tween.tween_property(_sprite, "rotation", deg_to_rad(20.0), BREAK_DURATION)
	tween.chain().tween_callback(queue_free)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Touch only: emulate_touch_from_mouse covers desktop testing.
	if _breaking or not (event is InputEventScreenTouch) or not event.pressed:
		return
	get_viewport().set_input_as_handled()
	_wobble()
	EventBus.quiz_requested.emit(data.id)


func _wobble() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", _base_scale * TAP_WOBBLE_SCALE, 0.08)
	tween.tween_property(_sprite, "scale", _base_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_save_requested() -> void:
	if data and not _breaking:
		GameState.sync_crate_position(data.id, global_position.x)
