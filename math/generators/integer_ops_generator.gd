class_name IntegerOpsGenerator
extends ProblemGenerator
## Signed-integer arithmetic: 5 − (−3), (−4) × 6, −7 + 2 ...

@export var min_value: int = -20
@export var max_value: int = 20
@export var allow_multiply: bool = true


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var a := rng.randi_range(min_value, max_value)
	var b := rng.randi_range(min_value, max_value)
	# Make sure at least one operand is negative, otherwise it is not an integer exercise.
	if a >= 0 and b >= 0:
		if rng.randf() < 0.5:
			a = -maxi(a, 1)
		else:
			b = -maxi(b, 1)
	var op := rng.randi_range(0, 2 if allow_multiply else 1)
	match op:
		0:
			return MathProblem.new("%s + %s" % [fmt(a), fmt(b, true)], a + b)
		1:
			return MathProblem.new("%s %s %s" % [fmt(a), MINUS, fmt(b, true)], a - b)
		_:
			var small_a := clampi(a, -12, 12)
			var small_b := clampi(b, -12, 12)
			return MathProblem.new("%s %s %s" % [fmt(small_a, true), TIMES, fmt(small_b, true)], small_a * small_b)
