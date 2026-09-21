extends Control
## Number-pad quiz for one crate. Pauses the tank while open.
## Wrong answer -> "Try again" with a fresh problem of the same band, progress kept.
## Closing -> crate stays; the next tap starts a brand-new set.

signal solved(crate_id: String)
signal closed(crate_id: String)

const KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "0", "\u232B"]
const MINUS_DISPLAY := "\u2212"
const BACKSPACE := "\u232B"
const MAX_DIGITS := 7
const RECENT_MEMORY := 12
const CORRECT_DELAY := 0.65
const WRONG_DELAY := 0.8

const COLOR_OK := Color(0.2, 0.65, 0.3)
const COLOR_WRONG := Color(0.85, 0.3, 0.3)

@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %TitleLabel
@onready var _dots: HBoxContainer = %ProgressDots
@onready var _problem_label: Label = %ProblemLabel
@onready var _answer_label: Label = %AnswerLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _keypad: GridContainer = %Keypad
@onready var _submit_button: Button = %SubmitButton
@onready var _close_button: Button = %CloseButton

var _crate_id := ""
var _def: CrateDef
var _problem: MathProblem
var _solved_count := 0
var _recent: Array[String] = []
var _entry := ""
var _busy := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	visible = false
	_rng.randomize()
	_build_keypad()
	_submit_button.pressed.connect(_on_submit)
	_close_button.pressed.connect(_on_close_pressed)


func open(crate_id: String, def: CrateDef) -> void:
	_crate_id = crate_id
	_def = def
	_solved_count = 0
	_recent.clear()
	_busy = false
	_feedback_label.text = ""
	_title_label.text = "%s  \u00B7  %s" % [def.display_name, def.band.display_name]
	visible = true
	get_tree().paused = true
	_next_problem()
	_pop_in()


func _unhandled_key_input(event: InputEvent) -> void:
	# Hardware keyboard support for desktop testing.
	if not visible or not (event is InputEventKey) or not event.pressed:
		return
	var key := event as InputEventKey
	if key.keycode >= KEY_0 and key.keycode <= KEY_9:
		_on_key(str(key.keycode - KEY_0))
	elif key.keycode >= KEY_KP_0 and key.keycode <= KEY_KP_9:
		_on_key(str(key.keycode - KEY_KP_0))
	elif key.keycode == KEY_MINUS or key.keycode == KEY_KP_SUBTRACT:
		_on_key("-")
	elif key.keycode == KEY_BACKSPACE:
		_on_key(BACKSPACE)
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		_on_submit()
	elif key.keycode == KEY_ESCAPE:
		_on_close_pressed()


# --- Flow --------------------------------------------------------------------

func _next_problem() -> void:
	_problem = _def.band.make_problem(_rng, _recent)
	_recent.append(_problem.signature)
	if _recent.size() > RECENT_MEMORY:
		_recent.pop_front()
	_problem_label.text = _problem.prompt
	_entry = ""
	_refresh_answer()
	_refresh_dots()


func _on_submit() -> void:
	if _busy or not visible:
		return
	if _entry.is_empty() or _entry == "-":
		_shake(_answer_label)
		return
	if int(_entry) == _problem.answer:
		_correct()
	else:
		_wrong()


func _correct() -> void:
	_busy = true
	_solved_count += 1
	_set_feedback("Correct!", COLOR_OK)
	_refresh_dots()
	var tween := create_tween()
	tween.tween_property(_answer_label, "scale", Vector2(1.15, 1.15), 0.1)
	tween.tween_property(_answer_label, "scale", Vector2.ONE, 0.2)
	await get_tree().create_timer(CORRECT_DELAY).timeout
	if not visible:
		return
	if _solved_count >= _def.problem_count:
		_finish(true)
		return
	_set_feedback("", COLOR_OK)
	_next_problem()
	_busy = false


func _wrong() -> void:
	_busy = true
	_set_feedback("Try again!", COLOR_WRONG)
	_shake(_answer_label)
	await get_tree().create_timer(WRONG_DELAY).timeout
	if not visible:
		return
	_set_feedback("", COLOR_OK)
	_next_problem()
	_busy = false


func _on_close_pressed() -> void:
	if not visible:
		return
	_finish(false)


func _finish(was_solved: bool) -> void:
	visible = false
	get_tree().paused = false
	_busy = false
	var id := _crate_id
	_crate_id = ""
	if was_solved:
		solved.emit(id)
	else:
		closed.emit(id)


# --- Entry -------------------------------------------------------------------

func _on_key(key: String) -> void:
	if _busy or not visible:
		return
	match key:
		BACKSPACE:
			_entry = _entry.left(_entry.length() - 1)
		"-":
			_entry = _entry.substr(1) if _entry.begins_with("-") else "-" + _entry
		_:
			var digits := _entry.trim_prefix("-")
			if digits.length() >= MAX_DIGITS:
				return
			if digits == "0":
				_entry = _entry.trim_suffix("0")
			_entry += key
	_refresh_answer()


func _refresh_answer() -> void:
	_answer_label.text = _entry.replace("-", MINUS_DISPLAY) if not _entry.is_empty() else "?"
	_answer_label.modulate.a = 1.0 if not _entry.is_empty() else 0.45


func _refresh_dots() -> void:
	for child in _dots.get_children():
		child.queue_free()
	for i in _def.problem_count:
		var dot := Label.new()
		dot.text = "\u25CF" if i < _solved_count else "\u25CB"
		dot.add_theme_font_size_override("font_size", 26)
		dot.add_theme_color_override("font_color", COLOR_OK if i < _solved_count else Color(0.55, 0.6, 0.68))
		_dots.add_child(dot)


func _set_feedback(text: String, color: Color) -> void:
	_feedback_label.text = text
	_feedback_label.add_theme_color_override("font_color", color)


# --- Juice -------------------------------------------------------------------

func _build_keypad() -> void:
	for key in KEYS:
		var button := Button.new()
		button.text = MINUS_DISPLAY if key == "-" else key
		button.custom_minimum_size = Vector2(96, 64)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 34)
		button.pressed.connect(_on_key.bind(key))
		_keypad.add_child(button)


func _pop_in() -> void:
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake(target: Control) -> void:
	var origin := target.position
	var tween := create_tween()
	for offset: float in [10.0, -10.0, 6.0, -6.0, 0.0]:
		tween.tween_property(target, "position:x", origin.x + offset, 0.05)
