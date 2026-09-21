class_name OrderOfOpsGenerator
extends ProblemGenerator
## Two-operator expressions that test PEMDAS, e.g. 3 + 4 × 2 or (3 + 4) × 2.

@export var operand_min: int = 2
@export var operand_max: int = 10
@export var use_parentheses: bool = false


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var a := rng.randi_range(operand_min, operand_max)
	var b := rng.randi_range(operand_min, operand_max)
	var c := rng.randi_range(operand_min, operand_max)
	var template := rng.randi_range(0, 2)
	if use_parentheses:
		match template:
			0:
				return MathProblem.new("(%d + %d) %s %d" % [a, b, TIMES, c], (a + b) * c)
			1:
				return MathProblem.new("%d %s (%d + %d)" % [a, TIMES, b, c], a * (b + c))
			_:
				var big := maxi(a, b)
				var small := mini(a, b)
				return MathProblem.new("(%d %s %d) %s %d" % [big, MINUS, small, TIMES, c], (big - small) * c)
	match template:
		0:
			return MathProblem.new("%d + %d %s %d" % [a, b, TIMES, c], a + b * c)
		1:
			return MathProblem.new("%d %s %d + %d" % [a, TIMES, b, c], a * b + c)
		_:
			# a × b − c, kept non-negative for the younger band
			var product := a * b
			var sub := mini(c, product)
			return MathProblem.new("%d %s %d %s %d" % [a, TIMES, b, MINUS, sub], product - sub)
