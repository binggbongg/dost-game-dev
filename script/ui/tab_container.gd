extends Control

signal deck_confirmed
@export var slot_scene: PackedScene = preload("res://scenes/menus/deckslot.tscn")
@onready var save_deck: TextureButton = $SaveDeck

# Set these as constants so they are easy to change later
const MIN_DECK_SIZE = 8
const MAX_DECK_SIZE = 12

@onready var grids = {
	"all": $TabContainer/All/VScrollBar/Container,
	"kalikasan": $TabContainer/Kalikasan/VScrollBar/Container,
	"tanglaw": $TabContainer/Tanglaw/VScrollBar/Container,
	"diwa": $TabContainer/Diwa/VScrollBar/Container,
	"lahi": $TabContainer/Lahi/VScrollBar/Container
}

@onready var status_label = $StatusLabel 

func _ready():
	print(PlayerProfile.tutorial_steps_completed)
	PlayerProfile.current_deck.clear()
	# DEBUG CODE
	if PlayerProfile.owned_cards.size() == 0:
		var all_keys = CardRegistry.all_cards.keys()
		for i in range(min(15, all_keys.size())):
			PlayerProfile.add_card_to_inventory(all_keys[i])
	
	save_deck.pressed.connect(_on_save_button_pressed)
	refresh_ui()

func refresh_ui():
	for key in grids:
		if grids[key] != null:
			for child in grids[key].get_children():
				child.queue_free()
	
	for path in PlayerProfile.owned_cards:
		var data = CardRegistry.all_cards[path]
		var category_name = GameEnums.CardCategory.keys()[data.category].to_lower()
		
		if grids.has("all"): spawn_slot(path, grids["all"])
		if grids.has(category_name): spawn_slot(path, grids[category_name])

	update_deck_counter()
	
func spawn_slot(path: String, grid: GridContainer):
	var slot = slot_scene.instantiate()
	grid.add_child(slot)
	slot.setup(path)
	slot.selection_changed.connect(_on_card_toggled)

func _on_card_toggled():
	for key in grids:
		for slot in grids[key].get_children():
			if slot.has_method("update_selection_visuals"):
				slot.update_selection_visuals()
	update_deck_counter()

func update_deck_counter():
	var count = PlayerProfile.current_deck.size()
	
	# Update Label
	if status_label:
		status_label.text = "%d / %d" % [count, MAX_DECK_SIZE]
	
	# Enable/Disable Save Button based on range [8 - 12]
	if count >= MIN_DECK_SIZE and count <= MAX_DECK_SIZE:
		save_deck.disabled = false
		save_deck.modulate = Color(1, 1, 1, 1) # Normal color
	else:
		save_deck.disabled = true
		save_deck.modulate = Color(0.5, 0.5, 0.5, 0.7) # Dimmed/Grayed out

func _on_save_button_pressed():
	var count = PlayerProfile.current_deck.size()
	
	# Final validation check
	if count < MIN_DECK_SIZE or count > MAX_DECK_SIZE:
		print("Invalid Deck Size: Must be between 8 and 12.")
		return

	SaveManager.save_game()
	
	# Ensure pending_scene exists before trying to switch
	if PlayerProfile.get("pending_scene"):
		get_tree().change_scene_to_file(PlayerProfile.pending_scene)
	else:
		print("Error: No pending scene defined in PlayerProfile.")
