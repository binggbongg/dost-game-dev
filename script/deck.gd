extends Node2D

@export var card_scene: PackedScene
@export var starting_cards: Array[CardData]

const CARD_DRAW_SPEED = 0.2
var player_deck: Array[CardData] = []

@onready var player_hand = $"../PlayerHand"
@onready var card_manager = $"../CardManager"
@onready var text_label = $RichTextLabel

func _ready() -> void:
	player_deck = starting_cards.duplicate()
	text_label.text = str(player_deck.size())

func draw_card():
	if player_deck.size() == 0:
		print("deck has no cards")
		return
	
	var data_drawn = player_deck.pop_front()
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
		text_label.visible = false
	
	text_label.text = str(player_deck.size())
	var new_card = card_scene.instantiate()
	new_card.card_data = data_drawn
	new_card.position = global_position
	
	if card_manager:
		card_manager.add_child(new_card)
		card_manager.connect_card_signal(new_card)
	
	if player_hand:
		player_hand.add_card_to_hand(new_card, CARD_DRAW_SPEED)
