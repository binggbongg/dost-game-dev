extends Label

func _ready():
	PlayerProfile.coins_changed.connect(_update_label)
	_update_label(PlayerProfile.coins)

func _update_label(val):
	text =  str(val)
