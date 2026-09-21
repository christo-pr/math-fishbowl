class_name DivideGenerator
extends ProblemGenerator
## dividend ÷ divisor where the dividend is built from a whole quotient (no remainders).

@export var divisor_min: int = 2
@export var divisor_max: int = 9
@export var quotient_min: int = 2
@export var quotient_max: int = 12


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var divisor := rng.randi_range(divisor_min, divisor_max)
	var quotient := rng.randi_range(quotient_min, quotient_max)
	return MathProblem.new("%d %s %d" % [divisor * quotient, DIVIDE, divisor], quotient)
