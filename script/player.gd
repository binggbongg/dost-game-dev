extends Node2D

@onready var health_bar = $HealthBar
@onready var mana_manager = $"../../PlayerInterface/GameManagers/ManaManager"

func _ready() -> void:
	await get_tree().process_frame
	
	if health_bar and mana_manager:
		health_bar.initialize_bar(
			PlayerStats.max_health, 
			PlayerStats.current_health, 
			PlayerStats.health_changed,
			mana_manager.max_mana,
			mana_manager.current_mana,
			mana_manager.mana_changed)
	else:
		print("could not initialize health and bar ui --player.gd")
