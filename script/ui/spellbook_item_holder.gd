extends Control

signal card_selected(card_resource: Resource)

@onready var name_label = get_node_or_null("CardItems/ItemName_CardName_LevelNumber")
@onready var rarity_label = get_node_or_null("CardItems/ItemCategory_CardRarity_LevelNumber")
@onready var cost_label = get_node_or_null("CardItems/ItemCost_Description_Score")
@onready var card_art_texture = get_node_or_null("CardItems/ItemTexture")
@onready var category_icon = get_node_or_null("CardItems/CardType_TypeIcon_BattleSymbol")
@onready var click_button = get_node_or_null("CardItems/Button")

@export var texture_kalikasan: Texture2D
@export var texture_tanglaw: Texture2D
@export var texture_diwa: Texture2D
@export var texture_lahi: Texture2D

var card_data: Resource

func _ready():
	if click_button:
		click_button.pressed.connect(_on_button_pressed)

func setup_item(card_res: Resource):
	card_data = card_res
	
	if name_label: 
		name_label.text = str(card_res.get("name"))
		
	if cost_label: 
		cost_label.text = "MANA COST: %s" % str(card_res.get("mana_cost"))
		
	if card_art_texture:
		card_art_texture.texture = card_res.get("texture")
		
	_update_category_icon(card_res.get("category"))
	_setup_rarity_display(card_res.get("rarity"))
	
	# Adjust the colored tab dynamically to sit flush right at the end of the text
	if name_label and category_icon:
		await get_tree().process_frame
		if is_instance_valid(name_label) and is_instance_valid(category_icon):
			var text_font = name_label.get_theme_font("font")
			var text_size = name_label.get_theme_font_size("font_size")
			var calculated_width = text_font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
			

func _update_category_icon(category_val):
	if not category_icon: return
	match category_val:
		GameEnums.CardCategory.KALIKASAN: category_icon.texture = texture_kalikasan
		GameEnums.CardCategory.TANGLAW: category_icon.texture = texture_tanglaw
		GameEnums.CardCategory.DIWA: category_icon.texture = texture_diwa
		GameEnums.CardCategory.LAHI: category_icon.texture = texture_lahi
		_: category_icon.texture = null

func _setup_rarity_display(rarity_val):
	if not rarity_label: return
	if rarity_val == null: rarity_val = 0
	
	rarity_label.text = GameEnums.CardRarity.keys()[rarity_val].to_upper()
	
	var text_color = Color.WHITE
	match rarity_val:
		GameEnums.CardRarity.Karaniwan: text_color = Color.WHITE
		GameEnums.CardRarity.Natatangi: text_color = Color(0.2, 0.6, 1.0) # Vibrant Natatangi Blue
		GameEnums.CardRarity.Bihira: text_color = Color(0.68, 0.45, 0.9)  # Vibrant Bihira Purple
		GameEnums.CardRarity.Dambana: text_color = Color(0.95, 0.25, 0.25) # Dark Dambana Red
		
	# Bypasses theme settings entirely and directly tints the node
	rarity_label.self_modulate = text_color


func _on_button_pressed():
	if card_data:
		card_selected.emit(card_data)
