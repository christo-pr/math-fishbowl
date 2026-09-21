extends Control
## Shown once per new fish so the child can name it. Uses the OS keyboard via LineEdit.

signal confirmed(fish_id: String, new_name: String)

@onready var _preview: TextureRect = %Preview
@onready var _species_label: Label = %SpeciesLabel
@onready var _name_edit: LineEdit = %NameEdit
@onready var _done_button: Button = %DoneButton

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


func _confirm() -> void:
	if not visible:
		return
	var chosen := _name_edit.text.strip_edges()
	if chosen.is_empty():
		chosen = _fallback_name
	visible = false
	_name_edit.release_focus()
	confirmed.emit(_fish_id, chosen)
