extends RichTextLabel

@onready var mana_manager = $"../../GameManagers/ManaManager"

func _ready() -> void:
	if mana_manager:
		mana_manager.mana_changed.connect(_on_mana_changed)
		_on_mana_changed(mana_manager.current_mana)

func _on_mana_changed(new_mana):
	text = "Mana: " + str(new_mana) + " / " + str(mana_manager.max_mana)
