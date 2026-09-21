class_name ProblemGenerator
extends Resource
## Base class for every exercise type. Subclass, override _generate(), then add an
## instance to a MathBand .tres. Keep generators pure: rng in, MathProblem out.

const MINUS := "\u2212"   # −
const TIMES := "\u00D7"   # ×
const DIVIDE := "\u00F7"  # ÷


func generate(rng: RandomNumberGenerator) -> MathProblem:
	return _generate(rng)


func _generate(_rng: RandomNumberGenerator) -> MathProblem:
	push_error("%s must override _generate()" % get_script().resource_path)
	return MathProblem.new("1 + 1", 2)


## Formats a value for display, wrapping negatives in parentheses when it follows an operator.
static func fmt(value: int, wrap_negative: bool = false) -> String:
	if value < 0:
		var text := MINUS + str(-value)
		return "(%s)" % text if wrap_negative else text
	return str(value)
