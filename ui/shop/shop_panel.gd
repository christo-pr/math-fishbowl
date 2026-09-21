extends Control
## Buy fish food with coins. Requests go through GameState; the panel only displays.

@onready var _dim: ColorRect = %Dim
@onready var _price_label: Label = %PriceLabel
@onready var _coins_label: Label = %CoinsLabel
@onready var _buy_one: Button = %BuyOneButton
@onready var _buy_five: Button = %BuyFiveButton
@onready var _close_button: Button = %CloseButton


func _ready() -> void:
	visible = false
	_buy_one.pressed.connect(func() -> void: _buy(1))
	_buy_five.pressed.connect(func() -> void: _buy(5))
	_close_button.pressed.connect(close)
	_dim.gui_input.connect(_on_dim_input)
	EventBus.coins_changed.connect(func(_coins: int) -> void: _refresh())
	EventBus.food_changed.connect(func(_food: int) -> void: _refresh())


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false


func _buy(count: int) -> void:
	if not GameState.try_buy_food(count):
		_shake(_coins_label)


func _refresh() -> void:
	var price := GameState.config.food_price
	_price_label.text = "%d coins each" % price
	_coins_label.text = "You have %d coins and %d food" % [GameState.state.coins, GameState.state.food]
	_buy_one.text = "Buy 1  (%d)" % price
	_buy_five.text = "Buy 5  (%d)" % (price * 5)
	_buy_one.disabled = GameState.state.coins < price
	_buy_five.disabled = GameState.state.coins < price * 5


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		close()


func _shake(target: Control) -> void:
	var origin := target.position
	var tween := create_tween()
	for offset: float in [8.0, -8.0, 5.0, -5.0, 0.0]:
		tween.tween_property(target, "position:x", origin.x + offset, 0.05)
