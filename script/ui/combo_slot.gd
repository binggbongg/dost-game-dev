extends Control

@onready var special_panel = $SpecialCards
@onready var double_panel = $Spell_double
@onready var triple_panel = $Spell_tripple

func display_content(data: Resource):
	special_panel.hide()
	double_panel.hide()
	triple_panel.hide()
	
	if data is SpecialCardData:
		_show_special(data)
	else:
		_show_combo(data)

func _show_special(data: SpecialCardData):
	special_panel.show()
	special_panel.get_node("Name").text = data.name
	special_panel.get_node("Card").texture = data.texture
	special_panel.get_node("DescriptionPanel/DescriptionFull").text = data.description
	special_panel.get_node("FilipinoLoreFull").text = data.FilipinoLore
	
	var asl = special_panel.get_node("ASL")
	asl.sprite_frames = data.cardASL
	asl.play("default")
	special_panel.get_node("ASLLabel2").text = data.ASLExplanation

func _show_combo(data: Resource):
	# Assumes your combo resource has a property 'recipe_cards' (Array)
	var cards = data.recipe_cards if "recipe_cards" in data else []
	var target = triple_panel if cards.size() >= 3 else double_panel
	target.show()
	
	target.get_node("Name").text = data.name
	target.get_node("DescriptionPanel/DescriptionFull").text = data.description
	
	# Set textures Card, Card2, Card3
	if cards.size() >= 1: target.get_node("Card").texture = cards[0].texture
	if cards.size() >= 2: target.get_node("Card2").texture = cards[1].texture
	if cards.size() >= 3: target.get_node("Card3").texture = cards[2].texture
