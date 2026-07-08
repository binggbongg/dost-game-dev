extends Control

@onready var  coin_label: Label = $label

func _ready() -> void:
	if not PlayerProfile.coins_changed.is_connected(update_display):
		PlayerProfile.coins_changed.connect(update_display)
		await get_tree().process_frame
	
	update_display(PlayerProfile.coins)

func update_display(amount: int) -> void:
	if coin_label:
		coin_label.text = str(amount)
		print("CoinDisplay: UI updated to ", amount)
	else:
		push_error("CoinDisplay: Cannot find Label node! Check your scene hierarchy.")
