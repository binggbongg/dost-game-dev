extends Node

@onready var combo_manager = $"../ComboManager"
@onready var mana_manager = $"../ManaManager"
@onready var turn_manager = $"../TurnManager"
@onready var enemy_manager = $"../EnemyManager"
@onready var player_stats = $"../PlayerStats"
#@onready var discard_manager = $"../DiscardManager" # later

func cast():
	if !combo_manager.validate_cast():
		return
	var cards = combo_manager.get_cards_in_slots()
