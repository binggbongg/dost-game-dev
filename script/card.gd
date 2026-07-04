extends Node2D
class_name Card 
signal hovered
signal hovered_off

const DEFAULT_CARD_SCALE = 0.16
const SPECIAL_CARD_SCALE = 0.2
@onready var card_name: Label = $Area2D/CardName
var card_source: GameEnums.CardSource
@export var card_data: Resource  
var card_category:GameEnums.CardCategory
var card_rarity: GameEnums.CardRarity
var card_damage: int
var card_heal: int
var card_cost: int
var can_drag := true
var hand_position
#para ma track where ang kana nga card
var location = GameEnums.Location.DECK
var current_slot = null
@onready var mana_cost: Label = $Area2D/ManaCost/ManaCost
@onready var power_highlight: Label = $Area2D/CardPowerHighlight/PowerHighlight
@onready var power_highlight_icon: TextureRect = $Area2D/CardPowerHighlight/PowerHighlightIcon

func _ready() -> void:
	apply_data()
	
	add_to_group("cards")
	modulate = Color(1, 1, 1, 1)

func apply_data():
	if card_data == null:
		return
		
	var d_name = card_data.get("item_name") if card_data.get("item_name") else card_data.get("name")
	var d_texture = card_data.get("icon") if card_data.get("icon") else card_data.get("texture")
	
	card_name.text = str(d_name) + " - "  + str(card_data.mana_cost)
	card_category = card_data.category
	card_rarity = card_data.rarity
	card_damage = card_data.damage
	card_heal = card_data.heal
	card_cost = card_data.mana_cost
	mana_cost.text = str(card_data.mana_cost)
	card_source = card_data.card_source
	power_highlighter()
	# --- UPDATED SCALING LOGIC FOR YOUR TEXTURERECT ---
	# Even though it's named "Sprite2D", it's a TextureRect (Green Icon)
	var art_node = $Sprite2D 
	
	if d_texture:
		art_node.texture = d_texture
		art_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art_node.texture_filter = TEXTURE_FILTER_NEAREST
		

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

func power_highlighter():
	if(card_data.category == GameEnums.CardCategory.KALIKASAN):
			power_highlight.text = str(card_data.damage)
			power_highlight_icon.texture = load("res://assets/ui/spellbook/spellbook_green_bookmark.png")
	elif (card_data.category == GameEnums.CardCategory.TANGLAW):
			power_highlight.text = str(card_data.heal)
			power_highlight_icon.texture = load("res://assets/ui/spellbook/spellbook_blue_bookmark.png")
	elif (card_data.category == GameEnums.CardCategory.DIWA):
			power_highlight.text = str(card_data.multiplier)
			power_highlight_icon.texture = load("res://assets/ui/spellbook/spellbook_yellow_bookmark.png")
	else: 
			power_highlight.text = str(card_data.damage)
			power_highlight_icon.texture = load("res://assets/ui/spellbook/spellbook_red_bookmark.png")

func display_info(data: CardData):
	card_data = data
	apply_data()
	scale = Vector2(0.8, 0.8)
