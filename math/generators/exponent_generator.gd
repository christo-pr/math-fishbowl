class_name ExponentGenerator
extends ProblemGenerator
## Small powers: 2⁵, 7², 4³ ...

const SUPERSCRIPTS := ["\u2070", "\u00B9", "\u00B2", "\u00B3", "\u2074", "\u2075", "\u2076", "\u2077", "\u2078", "\u2079"]

@export var base_min: int = 2
@export var base_max: int = 10
@export var exponent_min: int = 2
@export var exponent_max: int = 3
## Base 2 (and 3) are allowed to go higher so kids meet 2⁵, 2⁶.
@export var small_base_exponent_max: int = 6


func _generate(rng: RandomNumberGenerator) -> MathProblem:
	var base := rng.randi_range(base_min, base_max)
	var exp_max := small_base_exponent_max if base <= 3 else exponent_max
	var exponent := rng.randi_range(exponent_min, maxi(exponent_min, exp_max))
	var value := 1
	for _i in exponent:
		value *= base
	return MathProblem.new("%d%s" % [base, _superscript(exponent)], value)


static func _superscript(n: int) -> String:
	var out := ""
	for ch in str(n):
		out += SUPERSCRIPTS[int(ch)]
	return out
