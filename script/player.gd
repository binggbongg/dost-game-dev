extends Node2D

@onready var health_bar = $HealthBar

func _ready() -> void:
	if health_bar:
		health_bar.initialize_bar(
			PlayerStats.max_health, 
			PlayerStats.current_health, 
			PlayerStats.health_changed)
	else:
		print("could not initialize health bar ui --player.gd")
