extends TextureProgressBar
class_name UIStatusBar

@onready var text_label = $HealthBarText
@onready var mana_bar = $ManaBar

func initialize_bar(max_health, current_health, health_signal, max_mp, current_mp, mp_signal):
	max_value = max_health
	value = current_health
	update_text(current_health)
	health_signal.connect(update_health)
	
	if mana_bar:
		mana_bar.max_value = max_mp
		mana_bar.value = current_mp
		mp_signal.connect(update_mana)

func update_health(new_value):
	value = new_value
	update_text(new_value)

func update_mana(new_value):
	mana_bar.value = new_value

func update_text(current_health_value):
	if text_label:
		var current = int(current_health_value)
		var max = int(max_value)
		text_label.text = str(current) + " / " + str(max)
