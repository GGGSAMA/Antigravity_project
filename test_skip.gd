extends SceneTree
func _init():
	print("Testing time skip...")
	var tm = load("res://0001globals/time_manager.gd").new()
	root.add_child(tm)
	tm.request_time_skip(240)
	print("Done!")
	quit()

