extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2

var screen_size
var card_being_dragged
var is_hovering_on_card
var drag_offset: Vector2 = Vector2.ZERO
var hovered_card

@onready var player_hand = $"../PlayerHand"
@onready var mana_manager: Node2D = $"../ManaManager"

func _ready() -> void:
	screen_size = get_viewport_rect().size
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

func _process(_delta) -> void:
	if card_being_dragged:
		var target_pos = get_global_mouse_position() + drag_offset
		
		card_being_dragged.position = Vector2(
			clamp(target_pos.x, 0, screen_size.x), 
			clamp(target_pos.y, 0, screen_size.y)
		)

func finish_drag():
	if not card_being_dragged:
		return

	var slot = raycast_check_card_slot()
	if slot and not slot.card_in_slot and mana_manager.can_afford(card_being_dragged.card_cost):
		mana_manager.spend_mana(card_being_dragged.card_cost)
		drop_into_slot(card_being_dragged, slot)
	else:
		return_to_hand(card_being_dragged)
	
	card_being_dragged = null

func drop_into_slot(card, slot):
	# 1. Clear from old slot if it was in one
	clear_card_from_slot(card)

	# 2. Update Card Data
	set_card_to_slot(card, slot) # This sets card.location = SLOT
	
	# 3. Remove from hand array and trigger the repositioning tween
	if card in player_hand.player_cards:
		player_hand.remove_card_from_hand(card)

	# 4. Snap to slot position
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", slot.position, 0.2).set_trans(Tween.TRANS_CUBIC)
func return_to_hand(card):
	clear_card_from_slot(card)

	player_hand.add_card_to_hand(card, 0.1)
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

func on_left_click_released():
	print("signal left mouse button released")
	if card_being_dragged:
		finish_drag()

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

func start_drag(card):
	card_being_dragged = card
	card_being_dragged.z_index = 100 # Ensure it's above EVERYTHING
	drag_offset = card.global_position - get_global_mouse_position()

func highlight_card(card, hovered):
	if card == card_being_dragged:
		return
	
	if hovered:
		card.scale = Vector2(1.05, 1.05)
		# Only boost Z-index if it's in the hand. 
		# If it's in a slot, we might want to keep it at its slot depth.
		card.z_index = 20 
	else:
		card.scale = Vector2(1.0, 1.0)
		# Return to base depth based on location
		if card.location == GameEnums.Location.SLOT:
			card.z_index = 10
		else:
			card.z_index = 1

func set_card_to_hand(card):
	card.location = GameEnums.Location.HAND
	card.current_slot = null
	
func set_card_to_slot(card, slot):
	card.location = GameEnums.Location.SLOT
	card.current_slot = slot
	slot.card_in_slot = true
	
func clear_card_from_slot(card):
	if card.current_slot:
		card.current_slot.card_in_slot = false
	card.current_slot = null
	card.location = GameEnums.Location.HAND
