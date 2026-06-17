extends Node2D

signal hovered
signal hovered_off

@export var card_data: CardData  
var card_name: String
var card_category:GameEnums.CardCategory
var card_rarity: GameEnums.CardRarity
var card_damage: int
var card_heal: int
var card_cost: int

func _ready() -> void:
	apply_data()

#Applies data from our resource files!
func apply_data():
	if card_data == null:
		return
	card_name = card_data.name
	card_category = card_data.category
	card_rarity = card_data.rarity
	card_damage = card_damage
	card_heal = card_heal
	card_cost = card_cost
	$Sprite2D.texture = card_data.texture

func _on_area_2d_mouse_entered() -> void:
	hovered.emit(self)

func _on_area_2d_mouse_exited() -> void:
	hovered_off.emit(self)
