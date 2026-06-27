class_name LoreGenerator
extends RefCounted

static var npc_names_data: Dictionary = {}
static var sect_names_data: Dictionary = {}

static func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("LoreGenerator: File not found: ", path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) == OK:
		var result = json.get_data()
		if typeof(result) == TYPE_DICTIONARY:
			return result
	else:
		push_error("LoreGenerator: Failed to parse JSON: ", path)
	return {}

static func generate_sect_name() -> String:
	if sect_names_data.is_empty():
		sect_names_data = _load_json("res://00050data/lore/sect_names.json")

	if not sect_names_data.is_empty():
		var prefixes = sect_names_data.get("prefixes", ["太玄", "青云"])
		var suffixes = sect_names_data.get("suffixes", ["宗", "门"])
		return prefixes.pick_random() + suffixes.pick_random()
	return "无名宗"

static func generate_npc_name() -> String:
	if npc_names_data.is_empty():
		npc_names_data = _load_json("res://00050data/lore/npc_names.json")

	if not npc_names_data.is_empty():
		var surnames = npc_names_data.get("surnames", ["李", "王"])
		var males = npc_names_data.get("male_given_names", ["凡", "天"])
		var females = npc_names_data.get("female_given_names", ["雪", "月"])
		var names = males + females # 混合男女名
		return surnames.pick_random() + names.pick_random()
	return "无名氏"
