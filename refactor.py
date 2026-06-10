import re

with open(r'entities\player\player.gd', 'r', encoding='utf-8') as f:
    orig = f.read()

ui_content = orig.replace('extends CharacterBody3D', 'extends CanvasLayer\n\n@onready var player: CharacterBody3D = get_parent()\n')

ui_content = ui_content.replace('@onready var stats: CharacterStats = $Stats', '@onready var stats: CharacterStats = player.get_node("Stats")')
ui_content = ui_content.replace('@onready var inventory_comp: InventoryComponent = $Inventory', '@onready var inventory_comp: InventoryComponent = player.get_node("Inventory")')
ui_content = ui_content.replace('@onready var hotbar_comp: InventoryComponent = $Hotbar', '@onready var hotbar_comp: InventoryComponent = player.get_node("Hotbar")')
ui_content = ui_content.replace('@onready var head: Node3D = $Head', '@onready var head: Node3D = player.get_node("Head")')
ui_content = ui_content.replace('@onready var camera: Camera3D = $Head/Camera3D', '@onready var camera: Camera3D = player.get_node("Head/Camera3D")')
ui_content = ui_content.replace('$HUD/', '') 
ui_content = ui_content.replace('var hud_node = $HUD', 'var hud_node = self')

ui_content = ui_content.replace('func _physics_process(delta: float) -> void:', 'func _physics_process_DISABLED(delta: float) -> void:')
ui_content = ui_content.replace('func _process(_delta: float) -> void:', 'func _process_DISABLED(_delta: float) -> void:')
ui_content = ui_content.replace('func _unhandled_input(event: InputEvent) -> void:', 'func _unhandled_input_DISABLED(event: InputEvent) -> void:')

with open(r'entities\player\player_ui.gd', 'w', encoding='utf-8') as f:
    f.write(ui_content)

print('player_ui.gd processed successfully.')
