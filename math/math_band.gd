class_name MathBand
extends Resource
## A difficulty level: a named bag of generators. Crates point at one band.

const MAX_RETRIES := 10

@export var id: StringName = &"grade5"
@export var display_name: String = "Grade 5"
@export var generators: Array[ProblemGenerator] = []


## Picks a random generator and returns a problem whose signature is not in `avoid`.
func make_problem(rng: RandomNumberGenerator, avoid: Array[String] = []) -> MathProblem:
	if generators.is_empty():
		push_error("MathBand %s has no generators" % id)
		return MathProblem.new("1 + 1", 2)
	var problem: MathProblem = null
	for _attempt in MAX_RETRIES:
		var generator := generators[rng.randi_range(0, generators.size() - 1)]
		problem = generator.generate(rng)
		if problem != null and not avoid.has(problem.signature):
			return problem
	return problem
