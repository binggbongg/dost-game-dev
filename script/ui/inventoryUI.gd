extends MenuBase

@export var slot_scene: PackedScene #
@onready var item_grid: GridContainer = $"HBoxContainer/Left Column/ItemGrid"
@onready var name_label = $HBoxContainer/DetailsPanel/NameLabel
@onready var desc_label = $HBoxContainer/DetailsPanel/Description
@onready var big_icon = $HBoxContainer/DetailsPanel/BigIcon
@onready var cast_button: TextureButton = $HBoxContainer/DetailsPanel/use_button 
@onready var cast_button_text: Label = $HBoxContainer/DetailsPanel/use_button/use_button_label
var selected_item_id: String = ""

func _ready():
	super._ready() 
	cast_button.pressed.connect(_on_cast_button_pressed)
	PlayerInventory.inventory_changed.connect(refresh_inventory)
	refresh_inventory()


func refresh_inventory():
	for child in item_grid.get_children():
		child.queue_free()
	
	var items = PlayerInventory.owned_items
	
	for id in items.keys():
		var slot = slot_scene.instantiate()
		item_grid.add_child(slot)
		slot.set_item(id, items[id])
		slot.item_selected.connect(_on_item_selected)
func _on_item_selected(id: String):
	var data = ItemDb.get_item(id)
	if not data: return
	
	selected_item_id = id
	
	name_label.text = data.get("item_name") if data.get("item_name") else data.get("name")
	desc_label.text = data.description
	
	var tex = data.get("icon") if data.get("icon") else data.get("texture")
	big_icon.texture = tex
	big_icon.custom_minimum_size = Vector2(250, 350)
	
	if data.stackable:
		cast_button_text.text = "USE ITEM"
	else:
		cast_button_text.text = "CAST"
	var current_mana = 0
	var mana_manager = get_tree().get_first_node_in_group("mana_manager")
	if mana_manager:
		current_mana = mana_manager.current_mana
		
	if data is SpecialCardData:
		if current_mana < data.mana_cost:
			cast_button_text.text = "NOT ENOUGH MANA"
			cast_button.disabled = true
			cast_button.modulate = Color(1, 0.3, 0.3) # Red tint
		else:
			cast_button_text.text = "CAST"
			cast_button.disabled = false
			cast_button.modulate = Color(1, 1, 1)
			
# This will now trigger because it's connected in _ready()
func _on_cast_button_pressed():
	if selected_item_id == "": return
	
	UIManager.item_cast_requested.emit(selected_item_id)
	
	# Wait a tiny bit before closing so the click isn't "passed" to the battle
	await get_tree().create_timer(0.1).timeout
	UIManager.close_menu()
