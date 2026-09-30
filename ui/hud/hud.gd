extends Control
## Heads-up display. Updates only on EventBus signals, never per frame.

signal shop_pressed

const BASE_MARGIN := 16.0
const TOAST_SECONDS := 2.6

@onready var _safe_area: MarginContainer = %SafeArea
@onready var _coins_label: Label = %CoinsLabel
@onready var _idle_label: Label = %IdleLabel
@onready var _feed_button: Button = %FeedButton
@onready var _shop_button: Button = %ShopButton
@onready var _reset_button: Button = %ResetButton
@onready var _reset_dialog: ConfirmationDialog = %ResetDialog
@onready var _toast: Label = %Toast
@onready var _sushi_button: Button = %SushiButton
@onready var _sushi_dialog: ConfirmationDialog = %SushiDialog

var _toast_tween: Tween


func _ready() -> void:
	EventBus.coins_changed.connect(_on_coins_changed)
	EventBus.food_changed.connect(_on_food_changed)
	EventBus.feed_mode_changed.connect(_on_feed_mode_changed)
	EventBus.idle_rate_changed.connect(_on_idle_rate_changed)
	EventBus.offline_reward.connect(_on_offline_reward)
	EventBus.fish_selection_changed.connect(_on_fish_selection_changed)
	_feed_button.toggled.connect(_on_feed_toggled)
	_shop_button.pressed.connect(func() -> void: shop_pressed.emit())
	_reset_button.visible = OS.is_debug_build()
	_reset_button.pressed.connect(_on_reset_pressed)
	_reset_dialog.confirmed.connect(_on_reset_confirmed)
	_sushi_button.pressed.connect(_on_sushi_pressed)
	_sushi_dialog.confirmed.connect(_on_sushi_confirmed)
	get_viewport().size_changed.connect(_apply_safe_area)

	_apply_safe_area()
	_on_coins_changed(GameState.state.coins)
	_on_food_changed(GameState.state.food)
	_on_idle_rate_changed(GameState.idle_coins_per_minute())
	_on_feed_mode_changed(GameState.feed_mode)
	_on_fish_selection_changed(GameState.selected_fish_id)


func show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 0.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func() -> void: _toast.visible = false)


func _on_coins_changed(coins: int) -> void:
	_coins_label.text = format_number(coins)


func _on_food_changed(food: int) -> void:
	_feed_button.text = "Food  %d" % food
	_feed_button.disabled = false


func _on_idle_rate_changed(per_minute: float) -> void:
	_idle_label.visible = per_minute > 0.0
	_idle_label.text = "+%s / min" % _trim(per_minute)


func _on_feed_mode_changed(active: bool) -> void:
	_feed_button.set_pressed_no_signal(active)
	_feed_button.modulate = Color(0.75, 1.0, 0.75) if active else Color.WHITE


func _on_reset_pressed() -> void:
	_reset_dialog.popup_centered()


func _on_reset_confirmed() -> void:
	GameState.reset_progress()
	get_tree().call_deferred("reload_current_scene")


func _on_feed_toggled(pressed: bool) -> void:
	if pressed and GameState.state.food <= 0:
		_feed_button.set_pressed_no_signal(false)
		shop_pressed.emit()
		return
	GameState.set_feed_mode(pressed)

func _on_fish_selection_changed(fish_id: String) -> void:
	_sushi_button.disabled = fish_id.is_empty()

func _on_sushi_pressed() -> void:
	var fish := GameState.state.find_fish(GameState.selected_fish_id)
	if fish == null:
		return
	var payout := GameState.sushi_payout(fish)
	_sushi_dialog.dialog_text = "Turn %s into sushi for %s coins?" % [fish.name, format_number(payout)]
	_sushi_dialog.popup_centered()

func _on_sushi_confirmed() -> void:
	var gained := GameState.make_fish_sushi(GameState.selected_fish_id)
	Audio.play(Audio.Cue.SUSHI, true)
	if gained > 0:
		show_toast("Sushi! +%s coins" % format_number(gained))

func _on_offline_reward(coins: int, seconds_away: int) -> void:
	# Deferred so the HUD is fully laid out before the toast tween runs.
	call_deferred("show_toast", "Welcome back! Your fish earned %s coins in %s" % [format_number(coins), _format_duration(seconds_away)])


## Insets the HUD away from notches / rounded corners. The safe area is only
## meaningful when the window fills the screen (phones/tablets); on desktop the
## rect is screen-relative, so we keep the plain base margin there.
func _apply_safe_area() -> void:
	var insets := Vector4.ZERO # left, top, right, bottom in window pixels
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		var window := DisplayServer.window_get_size()
		insets = Vector4(
			maxf(0.0, safe.position.x),
			maxf(0.0, safe.position.y),
			maxf(0.0, window.x - safe.end.x),
			maxf(0.0, window.y - safe.end.y)
		)
	var window_width := maxi(1, DisplayServer.window_get_size().x)
	var to_canvas := get_viewport_rect().size.x / float(window_width)
	_safe_area.add_theme_constant_override("margin_left", int(BASE_MARGIN + insets.x * to_canvas))
	_safe_area.add_theme_constant_override("margin_top", int(BASE_MARGIN + insets.y * to_canvas))
	_safe_area.add_theme_constant_override("margin_right", int(BASE_MARGIN + insets.z * to_canvas))
	_safe_area.add_theme_constant_override("margin_bottom", int(BASE_MARGIN + insets.w * to_canvas))


static func format_number(value: int) -> String:
	var text := str(absi(value))
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		out = text[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if value < 0 else "") + out


static func _trim(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


static func _format_duration(seconds: int) -> String:
	if seconds < 60:
		return "%d s" % seconds
	var minutes := int(floor(seconds / 60.0))
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %d min" % [int(floor(minutes / 60.0)), minutes % 60]
