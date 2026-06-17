extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4

@onready var card_manager_reference = $"../CardManager"
@onready var deck_reference = $"../Deck"

# do not touch
func _input(event: InputEvent) -> void:
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
		var result_collision_mask = result[0].collider.collision_layer
		if result_collision_mask == COLLISION_MASK_CARD:
			# card is clicked
			var card_found = result[0].collider.get_parent()
			if card_found:
				card_manager_reference.start_drag(card_found)
		elif result_collision_mask == COLLISION_MASK_DECK:
			# deck is clicked
			deck_reference.draw_card()
