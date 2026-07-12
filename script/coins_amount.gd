extends Control

@onready var coin_label: Label = $Coin/label

func _ready() -> void:
	if not PlayerProfile.coins_changed.is_connected(update_display):
		PlayerProfile.coins_changed.connect(update_display)
	
	update_display(PlayerProfile.coins)

func _exit_tree() -> void:
	if PlayerProfile.coins_changed.is_connected(update_display):
		PlayerProfile.coins_changed.disconnect(update_display)

func update_display(amount: int) -> void:
	if is_instance_valid(coin_label):
		coin_label.text = str(amount)
		print("CoinDisplay: UI updated to ", amount)
	else:
		push_error("CoinDisplay: Cannot find Label node! Check your scene hierarchy.")
