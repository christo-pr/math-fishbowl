class_name OneStepEquationGenerator
extends ProblemGenerator
## Solve for x in one step: x + a = b, x − a = b, a·x = b, x ÷ a = b.

@export var x_min: int = -15
@export var x_max: int = 15
@export var constant_max: int = 20


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var x := rng.randi_range(x_min, x_max)
	var form := rng.randi_range(0, 3)
	var equation := ""
	match form:
		0:
			var a := rng.randi_range(1, constant_max)
			equation = "x + %d = %s" % [a, fmt(x + a)]
		1:
			var a := rng.randi_range(1, constant_max)
			equation = "x %s %d = %s" % [MINUS, a, fmt(x - a)]
		2:
			var a := rng.randi_range(2, 9)
			equation = "%dx = %s" % [a, fmt(a * x)]
		_:
			var a := rng.randi_range(2, 9)
			equation = "x %s %d = %s" % [DIVIDE, a, fmt(x)]
			x = x * a
	return MathProblem.new("Solve for x\n%s" % equation, x)
