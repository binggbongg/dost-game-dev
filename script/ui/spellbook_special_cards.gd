extends Control

signal card_selected(res)

@onready var name_label = $"Special Cards/ItemName_CardName_LevelNumber"
@onready var cost_label = $"Special Cards/ItemCost_Description_Score"
@onready var item_icon = $"Special Cards/ItemTexture"
@onready var mana_icon = $"Special Cards/ManaCostIcon"
@onready var btn = $"Special Cards/Button"

var item_res

func _ready():
	if not btn.pressed.is_connected(_on_pressed):
		btn.pressed.connect(_on_pressed)

func setup_item(res):
	item_res = res
	name_label.text = res.name
	item_icon.texture = res.texture
	
	if "mana_cost" in res:
		cost_label.text = "MANA COST: " + str(res.mana_cost)
	else:
		cost_label.text = ""

func _on_pressed():
	card_selected.emit(item_res)
