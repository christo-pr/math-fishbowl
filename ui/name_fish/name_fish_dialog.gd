extends Control
## Shown once per new fish so the child can name it. Uses the OS keyboard via LineEdit.

signal confirmed(fish_id: String, new_name: String)

@onready var _preview: TextureRect = %Preview
@onready var _species_label: Label = %SpeciesLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _done_button: Button = %DoneButton
@onready var _center: CenterContainer = $Center

var _fish_id := ""
var _fallback_name := ""


func _ready() -> void:
	visible = false
	_done_button.pressed.connect(_confirm)
	_name_edit.text_submitted.connect(func(_text: String) -> void: _confirm())


func open(fish: FishData, species: FishSpecies) -> void:
	_fish_id = fish.id
	_fallback_name = fish.name
	_preview.texture = species.texture
	_species_label.text = species.display_name
	_name_edit.text = fish.name
	visible = true
	_name_edit.grab_focus()
	_name_edit.select_all()
	# Height is often still 0 on the same frame the keyboard starts opening.
	_apply_keyboard_inset(DisplayServer.virtual_keyboard_get_height())
		
func _confirm() -> void:
	if not visible:
		return
	_apply_keyboard_inset(0)
	var chosen := _name_edit.text.strip_edges()
	if chosen.is_empty():
		chosen = _fallback_name
	visible = false
	_name_edit.release_focus()
	confirmed.emit(_fish_id, chosen)
	

func _apply_keyboard_inset(height_px: int) -> void:
	var inset := _keyboard_inset(height_px)
	_center.offset_bottom = -inset
	# Landscape leftover space cannot hold the 120px preview plus the field.
	_preview.visible = inset <= 0.0

func _keyboard_inset(height_px: int) -> float:
	if not OS.has_feature("mobile"):
		return 0.0
	var window_height := maxi(1, DisplayServer.window_get_size().y)
	var to_canvas := get_viewport_rect().size.y / float(window_height)
	if height_px <= 0:
		# Some devices never report a height and just overlay the keyboard.
		return get_viewport_rect().size.y * 0.42
	return height_px * to_canvas
