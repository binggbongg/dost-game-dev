# Attach this to the root node "Spells" (Image 5 & 6)
extends Control
signal spell_selected(res: Resource)

var current_res: Resource

# Fixed paths based on Image 5
@onready var triple_panel = $SpellItem_Tripple
@onready var double_panel = $SpellItem_Double

func setup_spell(res: Resource):
	current_res = res
	var cards = res.recipe_cards if "recipe_cards" in res else []
	
	# Logic to choose which panel to show
	triple_panel.visible = (cards.size() >= 3)
	double_panel.visible = (cards.size() == 2)
	
	var active = triple_panel if cards.size() >= 3 else double_panel
	active.get_node("ItemCost_Description_Score").text = res.name
	
	# Update textures
	if cards.size() >= 1: active.get_node("ItemTexture").texture = cards[0].texture
	if cards.size() >= 2: active.get_node("ItemTexture2").texture = cards[1].texture
	if cards.size() >= 3: active.get_node("ItemTexture3").texture = cards[2].texture

func _on_button_pressed():
	spell_selected.emit(current_res)
