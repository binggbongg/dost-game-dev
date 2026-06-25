extends Node2D

const CARD_WIDTH = 175
const HAND_Y_POSITION = 890
const DEFAULT_CARD_MOVE_SPEED = 0.2

var screen_size
var player_cards: Array = []

@export var card_scene: PackedScene
@onready var card_manager = $"../CardManager"
@onready var deck_manager: Node2D = $"../DeckManager"
@onready var deck: Node2D = $"../../UI/Deck"


func _ready() -> void:
	screen_size = get_viewport_rect().size

func add_card_to_hand(card, speed):
	if card in player_cards:
		player_cards.erase(card)
	
	player_cards.append(card)
	update_hand_positions(speed)

func update_hand_positions(speed):
	player_cards = player_cards.filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion())
	var count = player_cards.size()
	if count == 0: return

	var total_width = (count - 1) * CARD_WIDTH
	var start_x = (screen_size.x / 2) - (total_width / 2)
	var y = HAND_Y_POSITION

	for i in range(count):
		var card = player_cards[i]
		
		if not is_instance_valid(card) or card.is_queued_for_deletion():
			continue
		
		var final_hand_pos = Vector2(start_x + i * CARD_WIDTH, y)
		
		card.hand_position = final_hand_pos
		if "starting_position" in card:
			card.starting_position = final_hand_pos
		
		animate_card_position(card, final_hand_pos, speed)

func animate_card_position(card, new_pos, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, speed)

func remove_card_from_hand(card):
	if card in player_cards:
		player_cards.erase(card)
		update_hand_positions(DEFAULT_CARD_MOVE_SPEED)
		

func draw_starting_hand():
	var drawn_cards = deck_manager.draw_cards(5)
	for card_data in drawn_cards:
		create_card(card_data)

func create_card(card_data):
	var card = card_scene.instantiate()
	card.card_data = card_data
	get_parent().add_child(card)
	
	# CRITICAL FIX: The DeckManager needs this to know the card is in the hand!
	card.location = GameEnums.Location.HAND
	
	card.global_position = deck.global_position
	card_manager.connect_card_signal(card)
	add_card_to_hand(card, DEFAULT_CARD_MOVE_SPEED)

func replenish_hand():
	player_cards = player_cards.filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion())
	var cards_needed = 5 - player_cards.size()
	if cards_needed > 0:
		print("Hand: Replenishing ", cards_needed, " cards.")
		var drawn_data = deck_manager.draw_cards(cards_needed)
		for data in drawn_data:
			create_card(data)
