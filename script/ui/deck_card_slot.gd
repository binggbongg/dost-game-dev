# DeckSlot.gd
extends Control
signal clicked(path)
var card_path: String = ""

func set_card(path: String):
	card_path = path
	var data = CardRegistry.all_cards[path]
	var card_instance = preload("res://scenes/Card.tscn").instantiate()
	
	$Marker2D.add_child(card_instance)
	card_instance.card_data = data
	card_instance.apply_data()
	
	# Adjust this scale until it fits your orange board nicely
	card_instance.scale = Vector2(0.14, 0.14) 
	
	# Disable card collision so it doesn't block the button
	var area = card_instance.find_child("Area2D", true, false)
	if area: area.input_pickable = false

func _on_button_pressed():
	clicked.emit(card_path)
