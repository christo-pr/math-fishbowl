extends Node
## Autoload: SaveService. Versioned JSON at user://, atomic temp+rename, rolling .bak.
## Knows nothing about gameplay; it only moves a TankState to/from disk.

const SAVE_VERSION := 1
const SAVE_PATH := "user://tank_save.json"
const BACKUP_PATH := "user://tank_save.json.bak"
const TEMP_PATH := "user://tank_save.json.tmp"


func save_state(state: TankState) -> Error:
	var data := state.to_dict()
	data["version"] = SAVE_VERSION

	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: cannot open temp file (%s)" % error_string(FileAccess.get_open_error()))
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		return ERR_CANT_OPEN
	if dir.file_exists(SAVE_PATH):
		dir.copy(SAVE_PATH, BACKUP_PATH)
	var err := dir.rename(TEMP_PATH, SAVE_PATH)
	if err != OK:
		push_error("SaveService: rename failed (%s)" % error_string(err))
	return err


## Returns null when no usable save exists (fresh start).
func load_state() -> TankState:
	for path: String in [SAVE_PATH, BACKUP_PATH]:
		var data := _read_json(path)
		if data.is_empty():
			continue
		data = _migrate(data)
		return TankState.from_dict(data)
	return null


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(BACKUP_PATH)


## Removes the live save, its backup, and any leftover temp file.
func delete_save() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_error("SaveService: cannot open user:// (%s)" % error_string(DirAccess.get_open_error()))
		return
	for path: String in [SAVE_PATH, BACKUP_PATH, TEMP_PATH]:
		if not dir.file_exists(path):
			continue
		var err := dir.remove(path)
		if err != OK:
			push_error("SaveService: failed to delete %s (%s)" % [path, error_string(err)])


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveService: %s is not valid JSON, skipping" % path)
		return {}
	return parsed


func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_warning("SaveService: save is from a newer build (v%d), loading best-effort" % version)
	for step in range(version, SAVE_VERSION):
		data = _migrate_step(data, step)
	data["version"] = SAVE_VERSION
	return data


## Add a `match` arm per schema bump: from_version -> from_version + 1.
func _migrate_step(data: Dictionary, from_version: int) -> Dictionary:
	match from_version:
		0:
			pass # pre-versioned saves already match v1
	return data
