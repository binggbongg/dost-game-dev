extends TextureProgressBar
class_name UIHealthBar

@onready var text_label = $HealthBarText

func initialize_bar(max_health, current_health, health_signal):
	max_value = max_health
	value = current_health
	update_text(current_health)
	health_signal.connect(update)

func update(new_value):
	value = new_value
	update_text(new_value)

func update_text(current_health_value):
	if text_label:
		var current = int(current_health_value)
		var max = int(max_value)
		text_label.text = str(current) + " / " + str(max)
