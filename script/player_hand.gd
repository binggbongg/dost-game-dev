extends Node2D

const CARD_WIDTH = 140
const HAND_Y_POSITION = 880
const DEFAULT_CARD_MOVE_SPEED = 0.3

var screen_size
var player_cards: Array = []

@export var card_scene: PackedScene
#@export var starting_cards: Array[CardData]
@onready var card_manager = $"../CardManager"
@onready var deck_manager: Node2D = $"../DeckManager"
@onready var deck: Node2D = $"../Deck"


func _ready() -> void:
	screen_size = get_viewport_rect().size
	#draw_starting_hand()
	#spawn_starting_cards()

func add_card_to_hand(card, speed):
	if card in player_cards:
		player_cards.erase(card)
	
	player_cards.append(card)
	update_hand_positions(speed)
	

func update_hand_positions(speed):
	var count = player_cards.size()
	if count == 0: return

	var total_width = (count - 1) * CARD_WIDTH
	var start_x = (screen_size.x / 2) - (total_width / 2)
	var y = HAND_Y_POSITION

	for i in range(count):
		var card = player_cards[i]
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
	# Start at the visible deck
	card.global_position = deck.global_position
	card_manager.connect_card_signal(card)
	add_card_to_hand(card, DEFAULT_CARD_MOVE_SPEED)
