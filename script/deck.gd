extends Node2D

@export var card_scene: PackedScene
@export var starting_cards: Array[CardData]

var player_deck: Array[CardData] = []

@onready var player_hand = $"../PlayerHand"
@onready var card_manager = $"../CardManager"

func _ready() -> void:
	# Duplicate the starting cards into our active runtime deck pile
	player_deck = starting_cards.duplicate()

func draw_card():
	print("drawing cards")
	# do not touch
