class_name CrateData
extends RefCounted
## Saved state of an unsolved crate sitting in the tank.

var id: String = ""
var size: StringName = &"small"
var x: float = 0.0


func to_dict() -> Dictionary:
	return {"id": id, "size": String(size), "x": x}


static func from_dict(d: Dictionary) -> CrateData:
	var crate := CrateData.new()
	crate.id = str(d.get("id", ""))
	crate.size = StringName(str(d.get("size", "small")))
	crate.x = float(d.get("x", 0.0))
	return crate
