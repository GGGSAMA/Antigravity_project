extends SceneTree

const RelationTagData = preload("res://0000core/simulation/factions/relation_tag_data.gd")

func _init():
	print("Generating Tag Resources...")

	# Blood Feud
	var bf = RelationTagData.new()
	bf.tag_id = "blood_feud"
	bf.tag_name = "血海深仇"
	bf.min_stance = 0 # HOSTILE_GREEDY
	bf.max_stance = 0 # HOSTILE_GREEDY
	ResourceSaver.save(bf, "res://0000core/simulation/data/relation_tags/blood_feud.tres")

	# Extreme Guilt
	var eg = RelationTagData.new()
	eg.tag_id = "extreme_guilt"
	eg.tag_name = "极度内疚"
	eg.min_stance = 3 # FRIENDLY
	eg.max_stance = 4 # FAWNING
	ResourceSaver.save(eg, "res://0000core/simulation/data/relation_tags/extreme_guilt.tres")

	# Dao Companion (for testing)
	var dc = RelationTagData.new()
	dc.tag_id = "dao_companion"
	dc.tag_name = "道侣"
	dc.min_stance = 3 # FRIENDLY
	dc.max_stance = 4 # FAWNING
	ResourceSaver.save(dc, "res://0000core/simulation/data/relation_tags/dao_companion.tres")

	print("Resources saved successfully.")
	quit()
