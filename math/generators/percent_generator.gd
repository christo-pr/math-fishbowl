class_name PercentGenerator
extends ProblemGenerator
## "p% of n" where n is chosen so the answer is a whole number.

@export var percents: PackedInt32Array = PackedInt32Array([10, 20, 25, 50, 75])
@export var base_max: int = 200


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var pct := percents[rng.randi_range(0, percents.size() - 1)]
	# Smallest base that keeps pct% of base an integer (all divisions here are exact).
	@warning_ignore("integer_division")
	var step := 100 / _gcd(pct, 100)
	@warning_ignore("integer_division")
	var max_multiplier := maxi(1, base_max / step)
	var base := step * rng.randi_range(1, max_multiplier)
	@warning_ignore("integer_division")
	var answer := (base * pct) / 100
	return MathProblem.new("%d%% of %d" % [pct, base], answer)


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a
