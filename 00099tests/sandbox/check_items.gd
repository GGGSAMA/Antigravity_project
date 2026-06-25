extends SceneTree
func _init():
    var ItemDatabase = load("res://0000core/data/item_database.gd")
    ItemDatabase._load_if_empty()
    for item_id in ItemDatabase.ITEMS:
        var meta = ItemDatabase.ITEMS[item_id]
        if "物品" in str(meta.get("name")):
            print("Found 物品 in item name: ", item_id, " -> ", meta.get("name"))
    quit()
