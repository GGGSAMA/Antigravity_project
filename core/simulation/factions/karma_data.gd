extends Resource
class_name KarmaData

# 关系双轴字典: { target_id: {"intimacy": 0.0, "hatred": 0.0, "labels": ["Master", "DaoCompanion"]} }
@export var relationships: Dictionary = {}

# 添加单向仇恨 (例如被杀后产生，或者被偷窃后产生)
func add_hatred(target_id: String, amount: float) -> void:
	if not relationships.has(target_id):
		relationships[target_id] = {"intimacy": 0.0, "hatred": 0.0, "labels": []}
	relationships[target_id]["hatred"] = clamp(relationships[target_id]["hatred"] + amount, 0.0, 100.0)

# 增加亲密度 (送礼，双修等)
func add_intimacy(target_id: String, amount: float) -> void:
	if not relationships.has(target_id):
		relationships[target_id] = {"intimacy": 0.0, "hatred": 0.0, "labels": []}
	relationships[target_id]["intimacy"] = clamp(relationships[target_id]["intimacy"] + amount, 0.0, 100.0)

# 添加硬连接标签 (师徒，夫妻等)
func add_label(target_id: String, label: String) -> void:
	if not relationships.has(target_id):
		relationships[target_id] = {"intimacy": 0.0, "hatred": 0.0, "labels": []}
	if not relationships[target_id]["labels"].has(label):
		relationships[target_id]["labels"].append(label)

# 检查对某个目标的仇恨值
func get_hatred(target_id: String) -> float:
	if relationships.has(target_id):
		return relationships[target_id]["hatred"]
	return 0.0

# 检查对某个目标的亲密度
func get_intimacy(target_id: String) -> float:
	if relationships.has(target_id):
		return relationships[target_id]["intimacy"]
	return 0.0

# 提取利益相关者 (亲友或仇人)
func get_interested_parties() -> Array:
	var interested = []
	for target_id in relationships.keys():
		var data = relationships[target_id]
		# 亲密度大于50，或仇恨度大于50，或有硬标签的，才算利益相关者
		if data["intimacy"] > 50.0 or data["hatred"] > 50.0 or data["labels"].size() > 0:
			interested.append(target_id)
	return interested
