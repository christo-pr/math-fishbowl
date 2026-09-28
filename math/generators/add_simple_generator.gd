class_name AddSimpleGenerator
extends ProblemGenerator
## a + b with whole numbers in [min_value, max_value].

@export var min_value: int = 10
@export var max_value: int = 99


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var a := rng.randi_range(min_value, max_value)
	var b := rng.randi_range(min_value, max_value)
	
	return MathProblem.new("%d + %d" % [a, b], a + b)
