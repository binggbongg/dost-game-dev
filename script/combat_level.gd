extends Node2D
class_name CombatLevel

@export var current_level_data: LevelData

@onready var upper_bg = $UpperBackground
@onready var battle_manager = $BattleManager

func _ready() -> void:
	if current_level_data:
		load_level_config(current_level_data)
	else:
		print("no combat level configuration --combat level")
	
	if battle_manager and battle_manager.has_signal("battle_won"):
		battle_manager.battle_won.connect(_on_battle_manager_won)
	
	PlayerStats.player_died.connect(_on_player_dies)

func load_level_config(data):
	if data.background and upper_bg:
		upper_bg.texture = load(data.background)
	
	if battle_manager and data.enemy_data:
		battle_manager.setup_enemy(data.enemy_data)
	else:
		print("missing enemy data or battle manager -- combat level")
	

func _on_battle_manager_won():
	print("CombatLevel: level victory!")
	if current_level_data and current_level_data.is_boss_level:
		trigger_boss_defeat_cutscene()
	else:
		proceed_next_stage()

func proceed_next_stage():
	print("combat level: proceeding back to map area")
	get_tree().change_scene_to_file("res://scenes/menus/map.tscn")

func trigger_boss_defeat_cutscene():
	if current_level_data and not current_level_data.post_boss_cutscene.is_empty():
		print('launching cut scene')
		get_tree().change_scene_to_file(current_level_data.post_boss_cutscene)
	else:
		proceed_next_stage()

func _on_player_dies():
	print("Combat Level: Player dead, you lose")
	
	# change the file to an actual game over scene
	get_tree().change_scene_to_file("res://scenes/menus/map.tscn")
