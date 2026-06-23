extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released

const LAYER_CARD = 1
const LAYER_DECK = 5

@onready var card_manager_reference = $"../CardManager"
@onready var deck_manager = $"../DeckManager"
@onready var turn_manager = $"../TurnManager"

func _input(event: InputEvent) -> void:
	# GATE: Allow clicks during DRAW_PHASE (for start) and PLAYER_ACTION (for shuffle)
	var state = turn_manager.current_state
	if state != GameEnums.TurnState.PLAYER_ACTION and state != GameEnums.TurnState.DRAW_PHASE:
		return 
		
	if turn_manager.is_busy:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			left_mouse_button_clicked.emit()
			raycast_at_cursor()
		else:
			left_mouse_button_released.emit()

func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	
	if result.size() > 0:
		var collision_layer = result[0].collider.collision_layer
		
		if collision_layer == LAYER_CARD:
			# Only allow dragging if we are in the ACTION phase
			if turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION:
				var card_found = card_manager_reference.get_highest_card(result)
				if card_found:
					card_manager_reference.start_drag(card_found)
				
		elif collision_layer == LAYER_DECK:
			handle_deck_click()

func handle_deck_click():
	if turn_manager.is_busy: return
	turn_manager.is_busy = true
	
	if turn_manager.current_state == GameEnums.TurnState.DRAW_PHASE:
		# FIRST CLICK: Open the hand
		print("InputManager: Initial Draw Triggered.")
		deck_manager.player_hand.draw_starting_hand()
		
		# Wait for cards to arrive
		await get_tree().create_timer(1.5).timeout
		
		# Move to Action phase (This enables dragging)
		turn_manager.start_player_turn()
		
	elif turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION:
		# SUBSEQUENT CLICKS: Shuffle and End Turn
		print("InputManager: Shuffle/End Turn Triggered.")
		deck_manager.redraw_hand()
		await get_tree().create_timer(0.5).timeout
		turn_manager.end_player_turn()

	turn_manager.is_busy = false
