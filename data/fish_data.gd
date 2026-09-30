class_name FishData
extends RefCounted
## Runtime + saved state of one fish. Plain data, no Node references.

enum VitalBand {CONTENT, HUNGRY, STARVING, ALMOST_DEAD, DEAD}

const MAX_STAGE := 2

# 1.0 = full, 0.0 = dead, Bands are derived.
var life: float = 1.0
var id: String = ""
var species_id: StringName = &""
var name: String = ""
var stage: int = 0
var growth: int = 0
var x: float = 0.0
var y: float = 0.0
var facing: int = 1


func to_dict() -> Dictionary:
	return {
		"id": id,
		"species": String(species_id),
		"name": name,
		"stage": stage,
		"growth": growth,
		"x": x,
		"y": y,
		"facing": facing,
		"life": life,
	}


static func from_dict(d: Dictionary) -> FishData:
	var fish := FishData.new()
	fish.id = str(d.get("id", ""))
	fish.species_id = StringName(str(d.get("species", "orange")))
	fish.name = str(d.get("name", "Fish"))
	fish.stage = clampi(int(d.get("stage", 0)), 0, MAX_STAGE)
	fish.growth = maxi(int(d.get("growth", 0)), 0)
	fish.x = float(d.get("x", 0.0))
	fish.y = float(d.get("y", 0.0))
	fish.facing = -1 if int(d.get("facing", 1)) < 0 else 1
	fish.life = clampf(float(d.get("life", 1.0)), 0.0, 1.0)
	return fish

func vital_band(hungry_below: float, starving_below: float, almost_dead_below: float) -> VitalBand:
	if life <= 0.0 or is_equal_approx(life, 0.0):
		return VitalBand.DEAD
	if life < almost_dead_below:
		return VitalBand.ALMOST_DEAD
	if life < starving_below:
		return VitalBand.STARVING
	if life < hungry_below:
		return VitalBand.HUNGRY
	return VitalBand.CONTENT

func is_alive() -> bool:
	return life > 0.0 and not is_equal_approx(life, 0.0)
