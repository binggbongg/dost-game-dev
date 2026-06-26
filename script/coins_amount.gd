extends Node2D

@onready var coins: Label = $"CoinDisplay/Coins"
func _ready():
	PlayerProfile.coins_changed.connect(update_label)
	update_label(PlayerProfile.coins)

func update_label(val):
	coins.text =  str(val)
