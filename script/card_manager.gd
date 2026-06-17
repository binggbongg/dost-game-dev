extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

var screen_size
var card_being_dragged
var is_hovering_on_card
var drag_offset: Vector2 = Vector2.ZERO
var hovered_card

@export var card_scene: PackedScene
@export var starting_cards: Array[CardData]

func _ready() -> void:
	screen_size = get_viewport_rect().size
	spawn_starting_cards()
	
func spawn_starting_cards():
	var count = starting_cards.size()

	var spacing = 140
	var total_width = (count - 1) * spacing

	var start_x = (screen_size.x / 2) - (total_width / 2)
	var y = screen_size.y - 200  # move above bottom slots

	for i in range(count):
		var data = starting_cards[i]

		var card = card_scene.instantiate()
		card.card_data = data
		add_child(card)

		card.position = Vector2(start_x + i * spacing, y)
		connect_card_signal(card) 
		
		

func _process(_delta) -> void:
	if card_being_dragged:
		var target_pos = get_global_mouse_position() + drag_offset
		
		card_being_dragged.position = Vector2(
			clamp(target_pos.x, 0, screen_size.x), 
			clamp(target_pos.y, 0, screen_size.y)
		)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			var card = raycast_check_card()
			if card:
				start_drag(card)
		else:
			finish_drag()

func start_drag(card):
	card_being_dragged = card
	card_being_dragged.z_index = 10
	drag_offset = card.global_position - get_global_mouse_position()

func finish_drag():
	if card_being_dragged:
		card_being_dragged.z_index = 1
		var card_slot_found = raycast_check_card_slot()
		
		if card_slot_found and not card_slot_found.card_in_slot:
			card_being_dragged.position = card_slot_found.position
			card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
			card_slot_found.card_in_slot = true
	card_being_dragged = null

func raycast_check_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_highest_card(result)
		
	return null

func raycast_check_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		return result[0].collider.get_parent()
		
	return null

func get_highest_card(cards):
	if(cards == null):
		print("no cards found")
		return
	
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_idx = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_idx:
			highest_z_card = current_card
			highest_z_idx = current_card.z_index
	
	return highest_z_card

func connect_card_signal(card):
	card.connect("hovered", on_hovered_card)
	card.connect("hovered_off", on_hovered_card_off)

func on_hovered_card(card):
	if card_being_dragged:
		return
	
	if !hovered_card and hovered_card != card:
		highlight_card(hovered_card, true)
		
	is_hovering_on_card = true
	highlight_card(card, true)

func on_hovered_card_off(card):
	highlight_card(card, false)
	var new_card_hovered = raycast_check_card()
	
	if new_card_hovered and new_card_hovered != card:
		highlight_card(new_card_hovered, true)
	else:
		is_hovering_on_card = false

func highlight_card(card, hovered):
	if card == card_being_dragged:
		return
	
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		card.z_index = 2
	else:
		card.scale = Vector2(1.0, 1.0)
		card.z_index = 1
