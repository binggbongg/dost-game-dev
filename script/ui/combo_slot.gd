extends Control

# to change later
@export var icon_kalikasan: Texture2D
@export var icon_tanglaw: Texture2D
@export var icon_lahi: Texture2D
@export var icon_diwa: Texture2D

# We define the map inside the function to ensure export variables are captured correctly
var icon_map = {}

func display_recipe(recipe: Resource):
	# Refresh the map with current exported textures
	icon_map = {
		GameEnums.CardCategory.KALIKASAN: icon_kalikasan,
		GameEnums.CardCategory.TANGLAW: icon_tanglaw,
		GameEnums.CardCategory.LAHI: icon_lahi,
		GameEnums.CardCategory.DIWA: icon_diwa
	}

	if recipe == null:
		hide()
		return
	
	show()
	
	# Determine branch based on card count
	var is_triple = recipe.elements.size() == 3
	$Tripple.visible = is_triple
	$Double.visible = !is_triple
	
	var active_node = $Tripple if is_triple else $Double
	
	# Set Text - Name (Title) and Label (Description)
	var name_lbl = active_node.get_node_or_null("Name")
	var desc_lbl = active_node.get_node_or_null("Label")
	
	if name_lbl: 
		name_lbl.text = recipe.name
		
	if desc_lbl: 
		desc_lbl.text = recipe.description
	
	# Set Icons logic
	var cards = ["Card", "Card2", "Card3"] if is_triple else ["Card", "Card2"]
	
	for i in range(cards.size()):
		var node = active_node.get_node_or_null(cards[i])
		if node:
			# 1. Set the Texture
			var element_type = recipe.elements[i]
			node.texture = icon_map.get(element_type)
			
			# 2. --- AUTO-SCALING LOGIC ---
			# This ensures small icons upscale to fill the planned area
			node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Keeps the element icons sharp (Pixel Art friendly)
			node.texture_filter = TEXTURE_FILTER_NEAREST
			# -----------------------------
