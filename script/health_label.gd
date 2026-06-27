extends RichTextLabel


func _ready() -> void:
		PlayerStats.health_changed.connect(on_health_changed)
		on_health_changed(PlayerStats.current_health)

func on_health_changed(new_mana):
	text = "Health: " + str(PlayerStats.current_health) + " / " + str(PlayerStats.max_health)
