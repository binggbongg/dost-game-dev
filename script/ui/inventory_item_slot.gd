# inventory_item_slot.gd
extends Control

signal item_selected(item_id)

const CARD_SCENE = preload("res://scenes/Card.tscn")

@onready var marker = $Marker2D
@onready var quantity_label = $Price/QuantityLabel # Path from your screenshot

var item_id: String = ""

func set_item(id: String, quantity: int):
	item_id = id
	var data = ItemDb.get_item(id)
	if not data: return
	
	# Clear old card if it exists
	for child in marker.get_children():
		child.queue_free()

	# Instantiate the actual Card scene (same as Shop)
	var visual_node = CARD_SCENE.instantiate()
	
	# Add child to marker
	marker.add_child(visual_node)
	
	# Match the Shop's scale/position logic

	visual_node.position = Vector2.ZERO 

	# Apply the data
	if visual_node.has_method("apply_data"):
		visual_node.card_data = data
		visual_node.apply_data()

	# Update Quantity Label (Path corrected based on your image)
	if quantity_label:
		if data.get("stackable"):
			quantity_label.text = "x" + str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
			
	# Disable the card's internal click detection so it doesn't block the Slot
	var area = visual_node.find_child("Area2D", true, false)
	if area: area.input_pickable = false

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		item_selected.emit(item_id)
