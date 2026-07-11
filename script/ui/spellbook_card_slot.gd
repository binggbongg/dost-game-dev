extends Control

@onready var card_art_display = get_node_or_null("Card")
@onready var title_name_label = get_node_or_null("Name")

# Stats Node Hierarchy
@onready var mana_label = get_node_or_null("CardStats/ManaCost/ManaCost")
@onready var attack_label = get_node_or_null("CardStats/Attack/AttackAmount")
@onready var heal_label = get_node_or_null("CardStats/Heal/HealAmount")
@onready var multiplier_label = get_node_or_null("CardStats/Shield/ShieldAmount") # Using this container for Multiplier

@onready var category_text = get_node_or_null("CategoryPanel/CardCategoryFull")
@onready var category_icon = get_node_or_null("CategoryPanel/Category")

@onready var effect_text = get_node_or_null("DescriptionPanel/DescriptionFull")
@onready var rarity_text = get_node_or_null("RarityPanel/CardRarityFull")

@onready var asl_animated_sprite = get_node_or_null("ASL")
@onready var asl_description_label = get_node_or_null("DescriptionPanel4/ASLDescription")

@export var texture_kalikasan: Texture2D
@export var texture_tanglaw: Texture2D
@export var texture_diwa: Texture2D
@export var texture_lahi: Texture2D

func display(card_res: Resource):
	if card_res == null:
		clear_display()
		return
		
	show()
	
	if card_art_display:
		card_art_display.texture = card_res.get("texture")
		card_art_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_art_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if title_name_label:
		title_name_label.text = str(card_res.get("name"))
		
	if effect_text:
		effect_text.text = str(card_res.get("description"))

	if asl_description_label:
		asl_description_label.text = str(card_res.get("ASLExplanation"))

	# --- Update Stats Block ---
	if mana_label:
		mana_label.text = "Mana Cost: %d" % card_res.get("mana_cost")
	if attack_label:
		attack_label.text = "Attack Power: %d" % card_res.get("damage")
	if heal_label:
		heal_label.text = "Heal Power: %d" % card_res.get("heal")
		
	# --- Changed to Multiplier (formatted to 1 decimal place, e.g., 1.5) ---
	if multiplier_label:
		var mult_val = card_res.get("multiplier") if "multiplier" in card_res else 0.0
		multiplier_label.text = "Multiplier: %.1f" % mult_val

	_update_category_ui(card_res.get("category"))
	_update_asl_animation(card_res.get("cardASL"))
	_update_rarity_text(card_res.get("rarity"))

func _update_category_ui(category_val):
	if category_text:
		category_text.text = GameEnums.CardCategory.keys()[category_val] if category_val != null else "NONE"
		
	if not category_icon: return
	match category_val:
		GameEnums.CardCategory.KALIKASAN: category_icon.texture = texture_kalikasan
		GameEnums.CardCategory.TANGLAW: category_icon.texture = texture_tanglaw
		GameEnums.CardCategory.DIWA: category_icon.texture = texture_diwa
		GameEnums.CardCategory.LAHI: category_icon.texture = texture_lahi
		_: category_icon.texture = null

func _update_asl_animation(sprite_frames_res):
	if not asl_animated_sprite: return
	
	if sprite_frames_res is SpriteFrames:
		asl_animated_sprite.sprite_frames = sprite_frames_res
		asl_animated_sprite.show()
		
		var anim_names = sprite_frames_res.get_animation_names()
		if anim_names.size() > 0:
			var active_anim = "default" if "default" in anim_names else anim_names[0]
			asl_animated_sprite.stop()
			asl_animated_sprite.set_animation(active_anim)
			asl_animated_sprite.frame = 0
			asl_animated_sprite.play(active_anim)
	else:
		asl_animated_sprite.hide()
		asl_animated_sprite.stop()

func _update_rarity_text(rarity_val):
	if not rarity_text: return
	if rarity_val == null: rarity_val = 0
	
	rarity_text.text = GameEnums.CardRarity.keys()[rarity_val]
	
	rarity_text.begin_bulk_theme_override()
	var text_color = Color.WHITE
	match rarity_val:
		GameEnums.CardRarity.Karaniwan: text_color = Color.WHITE
		GameEnums.CardRarity.Natatangi: text_color = Color(0.2, 0.6, 1.0)
		GameEnums.CardRarity.Bihira: text_color = Color(0.68, 0.45, 0.9)
		GameEnums.CardRarity.Dambana: text_color = Color(0.95, 0.25, 0.25)
		
	rarity_text.add_theme_color_override("font_color", text_color)
	rarity_text.end_bulk_theme_override()

func clear_display():
	if card_art_display: card_art_display.texture = null
	if title_name_label: title_name_label.text = ""
	if category_text: category_text.text = ""
	if rarity_text: rarity_text.text = ""
	if effect_text: effect_text.text = ""
	if asl_description_label: asl_description_label.text = ""
	if mana_label: mana_label.text = "Mana Cost: 0"
	if attack_label: attack_label.text = "Attack Power: 0"
	if multiplier_label: multiplier_label.text = "Multiplier: 0.0"
	if heal_label: heal_label.text = "Heal Power: 0"
	if asl_animated_sprite: 
		asl_animated_sprite.hide()
		asl_animated_sprite.stop()
