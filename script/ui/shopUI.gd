extends "res://script/ui/base_menu.gd" 

@export var slot_scene: PackedScene = preload("res://scenes/menus/shop_item_slot.tscn")
@export var shop_data: ShopData 

@onready var item_grid: GridContainer = $"HBoxContainer/Left Column/ItemGrid"
@onready var name_label = $HBoxContainer/DetailsPanel/NameLabel
@onready var desc_label = $HBoxContainer/DetailsPanel/Description
@onready var big_icon = $HBoxContainer/DetailsPanel/BigIcon
@onready var cost: Label = $HBoxContainer/DetailsPanel/Cost
@onready var purchase_button: TextureButton = $HBoxContainer/DetailsPanel/purchase_button

var selected_item_id: String = ""
var selected_price: int = 0

func _ready():
	super._ready() 
	purchase_button.pressed.connect(_on_purchase_clicked)
	
	name_label.text = ""
	desc_label.text = ""
	cost.text = ""
	
	populate_shop()

func populate_shop():
	var list = shop_data.items_for_sale if shop_data else ItemDb.items.keys()
	for item in list:
		var slot = slot_scene.instantiate()
		item_grid.add_child(slot)
		
		var final_id = ""
		if item is ItemData:
			final_id = item.item_id 
		else:
			final_id = str(item)    
		
		slot.set_item(final_id)
		slot.item_selected.connect(_on_item_selected)

func _on_item_selected(id: String):
	var data = ItemDb.get_item(id)
	if not data: return
	
	selected_item_id = id
	selected_price = data.price
	
	name_label.text = data.get("item_name") if data.get("item_name") else data.get("name")
	desc_label.text = data.description
	cost.text = str(data.price)

	var tex = data.get("icon") if data.get("icon") else data.get("texture")
	big_icon.texture = tex
	big_icon.custom_minimum_size = Vector2(250, 350)

func _on_purchase_clicked():
	if selected_item_id == "": return
	if ShopManager.buy_item(selected_item_id, selected_price):
		print("UI: Purchase Success!")
		
	else:
		print("UI: Purchase Failed!")
