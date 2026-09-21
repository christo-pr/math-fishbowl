class_name AddSubGenerator
extends ProblemGenerator
## a + b / a − b with whole numbers in [min_value, max_value].

@export var min_value: int = 10
@export var max_value: int = 99
@export var allow_subtraction: bool = true
## When false, subtraction operands are ordered so the result is never negative.
@export var allow_negative_result: bool = false


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var a := rng.randi_range(min_value, max_value)
	var b := rng.randi_range(min_value, max_value)
	var subtract := allow_subtraction and rng.randf() < 0.5
	if not subtract:
		return MathProblem.new("%d + %d" % [a, b], a + b)
	if not allow_negative_result and b > a:
		var tmp := a
		a = b
		b = tmp
	return MathProblem.new("%d %s %d" % [a, MINUS, b], a - b)
