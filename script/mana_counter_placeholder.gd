extends Label

@onready var mana_manager = $"../GameManagers/ManaManager"

func _ready():
	mana_manager.mana_changed.connect(_on_mana_changed)
	_on_mana_changed(mana_manager.current_mana)

func _on_mana_changed(new_mana: int):
	text = "Current mana: " + str(new_mana)
