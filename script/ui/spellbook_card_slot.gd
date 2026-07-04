extends Control

signal selection_changed

@onready var check_icon = $Button/Icon # Change to your checkmark node path
@onready var card_template = $Card     # Your card template scene node

var card_path: String = ""

func update_selection_visuals():
	# Sync visual checkmark with the PlayerProfile deck
	check_icon.visible = PlayerProfile.current_deck.has(card_path)

func _on_button_pressed():
	if PlayerProfile.current_deck.has(card_path):
		PlayerProfile.current_deck.erase(card_path)
	else:
		if PlayerProfile.current_deck.size() < 12:
			PlayerProfile.current_deck.append(card_path)
		else:
			print("Deck Full!")

	print(PlayerProfile.current_deck)
	print("Deck size:", PlayerProfile.current_deck.size())

	update_selection_visuals()
	selection_changed.emit()
	
func setup(path: String):
	card_path = path
	var data = CardRegistry.all_cards[path]
	card_template.scale = Vector2(0.75, 0.75) 
	card_template.position = custom_minimum_size / 2
	if card_template.has_method("apply_data"):
		card_template.card_data = data
		card_template.apply_data()
	update_selection_visuals()
