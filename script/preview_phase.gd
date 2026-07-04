extends Control


@onready var status_label: Label = $SelectedSection/StatusLabel
@onready var deck_grid: GridContainer = $SelectedSection/DeckGrid
@onready var library_grid: GridContainer = $Board/MarginContainer/Hbox/ScrollArea/LibraryGrid

var slot_scene = preload("res://scenes/menus/deck_card_slot.tscn")
var current_category = "kalikasan" # Default

func _ready():
	# Test: Add a card if the player has none (just for debugging)
	if PlayerProfile.owned_cards.size() == 0:
		PlayerProfile.add_card_to_inventory(CardRegistry.get_random_card_path())
	
	refresh_all()

func refresh_all():
	render_library()
	render_deck()

func render_library():
	for n in library_grid.get_children(): n.queue_free()
	
	# Filter cards by category AND ownership
	var category_paths = CardRegistry.categories[current_category]
	
	for path in category_paths:
		if PlayerProfile.owned_cards.has(path):
			var slot = slot_scene.instantiate()
			library_grid.add_child(slot)
			slot.set_card(path)
			slot.clicked.connect(_on_card_added)

func render_deck():
	for n in deck_grid.get_children(): n.queue_free()
	
	for path in PlayerProfile.current_deck:
		var slot = slot_scene.instantiate()
		deck_grid.add_child(slot)
		slot.set_card(path)
		slot.clicked.connect(_on_card_removed)
	
	status_label.text = "Selected: " + str(PlayerProfile.current_deck.size()) + " / 10"

func _on_card_added(path):
	if PlayerProfile.current_deck.size() < 10:
		if not PlayerProfile.current_deck.has(path):
			PlayerProfile.current_deck.append(path)
			render_deck()

func _on_card_removed(path):
	PlayerProfile.current_deck.erase(path)
	render_deck()

# Category Button Functions
func _on_btn_green_pressed(): 
	current_category = "kalikasan"
	render_library()

func _on_btn_blue_pressed(): 
	current_category = "tanglaw"
	render_library()
