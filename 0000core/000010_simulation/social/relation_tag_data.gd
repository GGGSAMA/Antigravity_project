class_name RelationTagData
extends Resource

@export var tag_id: String = ""
@export var tag_name: String = ""

# 引用 RelationshipGraph 的枚举可能会引起循环引用依赖，
# 因此使用 int 并配合 @export_enum 是更好的做法
@export_enum("HOSTILE_GREEDY:0", "DISDAIN:1", "NEUTRAL:2", "FRIENDLY:3", "FAWNING:4") 
var min_stance: int = 0

@export_enum("HOSTILE_GREEDY:0", "DISDAIN:1", "NEUTRAL:2", "FRIENDLY:3", "FAWNING:4") 
var max_stance: int = 4
