class_name TankState
extends RefCounted
## Authoritative, serializable snapshot of the whole tank.
## Only GameState mutates this. Everything here is plain data.

const MAX_COINS := 999_999_999
const MAX_FOOD := 9_999

var coins: int = 0
var food: int = 0
var last_unix: float = 0.0
var crates: Array[CrateData] = []
var fish: Array[FishData] = []


func find_fish(id: String) -> FishData:
	for f in fish:
		if f.id == id:
			return f
	return null


func find_crate(id: String) -> CrateData:
	for c in crates:
		if c.id == id:
			return c
	return null


func to_dict() -> Dictionary:
	var crate_dicts: Array[Dictionary] = []
	for c in crates:
		crate_dicts.append(c.to_dict())
	var fish_dicts: Array[Dictionary] = []
	for f in fish:
		fish_dicts.append(f.to_dict())
	return {
		"coins": coins,
		"food": food,
		"last_unix": last_unix,
		"crates": crate_dicts,
		"fish": fish_dicts,
	}


static func from_dict(d: Dictionary) -> TankState:
	var state := TankState.new()
	state.coins = clampi(int(d.get("coins", 0)), 0, MAX_COINS)
	state.food = clampi(int(d.get("food", 0)), 0, MAX_FOOD)
	state.last_unix = float(d.get("last_unix", 0.0))
	var raw_crates: Variant = d.get("crates", [])
	if raw_crates is Array:
		for entry: Variant in raw_crates:
			if entry is Dictionary:
				state.crates.append(CrateData.from_dict(entry))
	var raw_fish: Variant = d.get("fish", [])
	if raw_fish is Array:
		for entry: Variant in raw_fish:
			if entry is Dictionary:
				state.fish.append(FishData.from_dict(entry))
	return state
