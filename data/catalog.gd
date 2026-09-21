class_name Catalog
extends Resource
## Lookup table for all authored content. Add a new species/crate by creating a
## .tres and appending it here (data/catalog.tres).

@export var species: Array[FishSpecies] = []
@export var crates: Array[CrateDef] = []


func get_species(id: StringName) -> FishSpecies:
	for s in species:
		if s.id == id:
			return s
	return species[0] if not species.is_empty() else null


func get_crate(id: StringName) -> CrateDef:
	for c in crates:
		if c.id == id:
			return c
	return crates[0] if not crates.is_empty() else null


func random_species(rng: RandomNumberGenerator) -> FishSpecies:
	return _weighted_pick(species, rng, func(s: FishSpecies) -> float: return s.rarity_weight) as FishSpecies


func random_crate(rng: RandomNumberGenerator) -> CrateDef:
	return _weighted_pick(crates, rng, func(c: CrateDef) -> float: return c.spawn_weight) as CrateDef


func _weighted_pick(items: Array, rng: RandomNumberGenerator, weight_of: Callable) -> Resource:
	if items.is_empty():
		return null
	var total := 0.0
	for item: Resource in items:
		total += weight_of.call(item)
	var roll := rng.randf() * total
	for item: Resource in items:
		roll -= weight_of.call(item)
		if roll <= 0.0:
			return item
	return items.back()
