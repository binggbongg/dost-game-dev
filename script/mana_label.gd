extends RichTextLabel

@onready var mana_manager = $"../../../GameManagers/ManaManager"

func _ready() -> void:
	if mana_manager:
		if not mana_manager.mana_changed.is_connected(_on_mana_changed):
			mana_manager.mana_changed.connect(_on_mana_changed)
		
		update_mana_display(mana_manager.current_mana)
	else:
		print("Error: RichTextLabel could not find ManaManager node!")

func _on_mana_changed(new_mana: int) -> void:
	update_mana_display(new_mana)

func update_mana_display(mana_value: int) -> void:
	if mana_manager:
		text = "Mana: " + str(mana_value) + " / " + str(mana_manager.max_mana)
