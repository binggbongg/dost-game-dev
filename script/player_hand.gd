extends Node2D

@export var card_scene: PackedScene
@export var starting_cards: Array[CardData]

@onready var card_manager = $"../CardManager"

var screen_size
var player_cards: Array = [] # To keep track of card entities currently in hand

func _ready() -> void:
	screen_size = get_viewport_rect().size
	spawn_starting_cards()

func spawn_starting_cards():
	var count = starting_cards.size()
	if count == 0: return

	var spawn_start_pos = Vector2(screen_size.x / 2, screen_size.y + 150)

	for i in range(count):
		var data = starting_cards[i]
		var card = card_scene.instantiate()
		card.card_data = data
		
		if card_manager:
			card_manager.add_child(card)
			card_manager.connect_card_signal(card) 
		else:
			add_child(card)

		# Start them out at the hidden spawn point
		card.position = spawn_start_pos
		player_cards.append(card)
	
	# Once all cards are registered in the array, arrange them!
	update_hand_positions()

func update_hand_positions():
	var count = player_cards.size()
	if count == 0: return

	var spacing = 140
	var total_width = (count - 1) * spacing
	var start_x = (screen_size.x / 2) - (total_width / 2)
	var y = screen_size.y - 200 

	for i in range(count):
		var card = player_cards[i]
		
		# Calculate the position based on its current index in the active hand array
		var final_hand_pos = Vector2(start_x + i * spacing, y)
		
		# Update its saved home coordinates
		card.hand_position = final_hand_pos
		if "starting_position" in card:
			card.starting_position = final_hand_pos
			
		# Animate it to its fresh position
		animate_card_position(card, final_hand_pos)

func remove_card_from_hand(card):
	if card in player_cards:
		player_cards.erase(card)
		update_hand_positions()
 
func animate_card_position(card, new_pos):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, 0.1)
	
