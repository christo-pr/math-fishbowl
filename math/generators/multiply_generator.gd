class_name MultiplyGenerator
extends ProblemGenerator
## a × b with a in [a_min, a_max] and b in [b_min, b_max].

@export var a_min: int = 2
@export var a_max: int = 12
@export var b_min: int = 2
@export var b_max: int = 12


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var a := rng.randi_range(a_min, a_max)
	var b := rng.randi_range(b_min, b_max)
	if rng.randf() < 0.5:
		var tmp := a
		a = b
		b = tmp
	return MathProblem.new("%d %s %d" % [a, TIMES, b], a * b)
