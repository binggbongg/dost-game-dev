extends Node2D
class_name Card 
signal hovered
signal hovered_off

const DEFAULT_CARD_SCALE = 0.8

@onready var card_name: Label = $Area2D/CardName

@export var card_data: CardData  
var card_category:GameEnums.CardCategory
var card_rarity: GameEnums.CardRarity
var card_damage: int
var card_heal: int
var card_cost: int

var hand_position
#para ma track where ang kana nga card
var location = GameEnums.Location.DECK
var current_slot = null

func _ready() -> void:
	apply_data()
	add_to_group("cards")
	modulate = Color(1, 1, 1, 1)

#Applies data from our resource files!
func apply_data():
	if card_data == null:
		return
	card_name.text = card_data.name + " - " +  GameEnums.CardRarity.keys()[card_data.rarity] + "- "+  str(card_data.mana_cost)
	card_category = card_data.category
	card_rarity = card_data.rarity
	card_damage = card_data.damage
	card_heal = card_data.heal
	card_cost = card_data.mana_cost
	$Sprite2D.texture = card_data.texture

func _on_area_2d_mouse_entered() -> void:
	hovered.emit(self)

func _on_area_2d_mouse_exited() -> void:
	hovered_off.emit(self)
	
func reset_state():
	location = GameEnums.Location.DECK
	if current_slot:
		current_slot.card_in_slot = false
	current_slot = null
	
func set_location(new_location: GameEnums.Location):
	location = new_location
	scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
	if location == GameEnums.Location.SLOT:
		z_index = 10
	elif location == GameEnums.Location.HAND:
		z_index = 1
		
func set_interaction_state(enabled: bool):
	if enabled:
		modulate = Color(1, 1, 1, 1) # Normal
		$Area2D.monitorable = true
	else:
		modulate = Color(0.3, 0.3, 0.3, 0.7) # Darkened/Grayed out
		$Area2D.monitorable = false # Prevents dragging
