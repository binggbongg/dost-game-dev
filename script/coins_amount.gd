extends Control

# Use get_node so we can debug if the path is wrong
@onready var  coin_label: Label = $label

func _ready() -> void:
	# 1. Connect signal FIRST so we don't miss updates from the SaveManager
	if not PlayerProfile.coins_changed.is_connected(update_display):
		PlayerProfile.coins_changed.connect(update_display)
	
	# 2. Wait one frame to allow the SaveManager to finish its work
	# This ensures we don't show the "hardcoded" text or default 100 value
	await get_tree().process_frame
	
	update_display(PlayerProfile.coins)

func update_display(amount: int) -> void:
	if coin_label:
		coin_label.text = str(amount)
		print("CoinDisplay: UI updated to ", amount)
	else:
		push_error("CoinDisplay: Cannot find Label node! Check your scene hierarchy.")
