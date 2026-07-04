extends Control

signal hovered(card_path)
signal selection_changed(card_path)

@onready var check_icon = $Button/Icon
@onready var button = $Button
@onready var card_template: Card = $Card

var card_path: String = ""

func _ready():
	button.mouse_entered.connect(_on_mouse_entered)
	button.pressed.connect(_on_button_pressed)

func setup(path: String):
	card_path = path

	var data: CardData = CardRegistry.all_cards[path]

	card_template.scale = Vector2(0.75, 0.75)
	card_template.position = custom_minimum_size / 2
	card_template.display_info(data)

	update_selection_visuals()

func _on_mouse_entered():
	hovered.emit(card_path)

func _on_button_pressed():

	if PlayerProfile.current_deck.has(card_path):
		PlayerProfile.current_deck.erase(card_path)
	else:
		if PlayerProfile.current_deck.size() >= 12:
			print("Deck Full!")
			return

		PlayerProfile.current_deck.append(card_path)

	update_selection_visuals()
	selection_changed.emit(card_path)

func update_selection_visuals():
	check_icon.visible = PlayerProfile.current_deck.has(card_path)
