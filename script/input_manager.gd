extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released

const LAYER_CARD = 1
const LAYER_DECK = 5
const LAYER_CAST = 4  # Matches the Layer you set in Inspector
const LAYER_REDO = 8  # Matches the Layer you set in Inspector (bits: 1, 2, 4, 8)

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
					AudioManager.play_ui_sound("click")
					card_manager_reference.start_drag(card_found)
				
		elif collision_layer == LAYER_DECK:
			handle_deck_click()
		elif collision_layer == LAYER_CAST:
			# Get the script on the Cast node and trigger it
			var cast_node = result[0].collider.get_parent()
			if cast_node.has_method("on_click"):
				cast_node.on_click()
		elif collision_layer == LAYER_REDO:
			# Get the script on the Redo node and trigger it
			var redo_node = result[0].collider.get_parent()
			if redo_node.has_method("on_click"):
				redo_node.on_click()
func handle_deck_click():
	AudioManager.play_ui_sound("shuffle")
	if turn_manager.is_busy: return
	
	if turn_manager.current_state == GameEnums.TurnState.DRAW_PHASE:
		turn_manager.is_busy = true
		deck_manager.player_hand.draw_starting_hand()
		await get_tree().create_timer(1.2).timeout
		turn_manager.change_state(GameEnums.TurnState.PLAYER_ACTION)
		turn_manager.is_busy = false
		
	elif turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION:
		print("InputManager: SHUFFLE & PASS sequence started.")
		turn_manager.is_busy = true
		
		# 1. Clear hand and slots
		deck_manager.redraw_hand() 
		# 2. Wait for cards to fly in
		await get_tree().create_timer(1.2).timeout
		
		# 3. Lock interaction immediately so player can see cards but not move them
		card_manager_reference.refresh_hand_interaction()
		turn_manager.end_player_turn()
		turn_manager.is_busy = false
