class_name MathProblem
extends RefCounted
## One generated exercise. Answers are always integers so grading is exact.

var prompt: String
var answer: int
## Used to avoid showing the same operands twice in a row.
var signature: String


func _init(p_prompt: String, p_answer: int) -> void:
	prompt = p_prompt
	answer = p_answer
	signature = p_prompt
