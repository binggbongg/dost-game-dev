extends Control
signal card_selected(res: SpecialCardData)

var current_res: SpecialCardData

# Fixed paths based on Image 4 (pointing through the "Special Cards" container)
@onready var name_label = $"Special Cards/ItemName_CardName_LevelNumber"
@onready var info_label = $"Special Cards/ItemCost_Description_Score"
@onready var texture_rect = $"Special Cards/ItemTexture"

func setup_item(res: SpecialCardData):
	current_res = res
	name_label.text = res.name
	info_label.text = "Mana Cost: " + str(res.mana_cost)
	texture_rect.texture = res.texture

func _on_button_pressed():
	card_selected.emit(current_res)
