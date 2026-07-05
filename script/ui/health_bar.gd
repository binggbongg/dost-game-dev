extends TextureProgressBar
class_name UIStatusBar

@onready var text_label = $HealthBarText
@onready var mana_bar = $ManaBar

func initialize_bar(max_health, current_health, health_signal, max_mp, current_mp, mp_signal):
	max_value = max_health
	value = current_health
	update_text(current_health)
	
	if not health_signal.is_connected(update_health):
		health_signal.connect(update_health)
	
	if mana_bar:
		mana_bar.max_value = max_mp if max_mp > 0 else 12
		mana_bar.value = current_mp if current_mp > 0 else 12
		
		if not mp_signal.is_connected(update_mana):
			mp_signal.connect(update_mana)
			
		update_mana(mana_bar.value)

func update_health(new_value):
	value = new_value
	update_text(new_value)

func update_mana(new_value):
	if mana_bar:
		mana_bar.value = new_value

func update_text(current_health_value):
	if text_label:
		var current = int(current_health_value)
		var max_val = int(max_value)
		text_label.text = str(current) + " / " + str(max_val)
