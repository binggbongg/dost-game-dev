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

# This will now trigger because it's connected in _ready()
func _on_cast_button_pressed():
	if selected_item_id == "": 
		print("Inventory: No item selected to cast!")
		return
		
	print("Inventory: Casting/Equipping ", selected_item_id)
	UIManager.close_menu()
