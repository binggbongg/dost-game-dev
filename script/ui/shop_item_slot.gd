extends Control

signal item_selected(item_id)

const CARD_SCENE = preload("res://scenes/Card.tscn")
const ITEM_SCENE = preload("res://scenes/ItemDisplay.tscn")
@onready var price: Label = $Price/Price

var item_id: String = ""

func set_item(id: String):
	item_id = id
	var data = ItemDb.get_item(id)
	if not data: return
	
	# Clear old children
	for child in $Marker2D.get_children():
		child.queue_free()

	var visual_node = CARD_SCENE.instantiate()
	$Marker2D.add_child(visual_node)
	

	visual_node.scale = Vector2(0.25, 0.25) 
	visual_node.position = Vector2.ZERO 

	if visual_node.has_method("apply_data"):
		visual_node.card_data = data
		visual_node.apply_data()

	# Disable Area2D so it doesn't block UI clicks
	price.text = str(data.price)
	var area = visual_node.find_child("Area2D", true, false)
	if area:
		area.input_pickable = false
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		item_selected.emit(item_id)
