extends Control

signal deck_confirmed
signal selection_changed(card_path)

const SLOT_SCENE := preload("res://scenes/menus/deckslot.tscn")

const MIN_DECK_SIZE := 8
const MAX_DECK_SIZE := 12

@onready var mana_cost: Label = $CardDescription/ManaCost
@onready var battle_effects: Label = $CardDescription/BattleEffects

@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer/Control

var tutorial_active := false

@onready var save_deck: TextureButton = $SaveDeck
@onready var status_label: Label = $StatusLabel

@onready var card_description = $CardDescription
@onready var preview_card: Card = $CardDescription/Card
@onready var preview_name: Label = $CardDescription/CardName
@onready var preview_rarity: Label = $CardDescription/RarityType
@onready var preview_description: Label = $CardDescription/Description
@onready var tab_container: TabContainer = $TabContainer

@onready var grids = {
	"all": $TabContainer/All/VScrollBar/Container,
	"kalikasan": $TabContainer/Kalikasan/VScrollBar/Container,
	"tanglaw": $TabContainer/Tanglaw/VScrollBar/Container,
	"diwa": $TabContainer/Diwa/VScrollBar/Container,
	"lahi": $TabContainer/Lahi/VScrollBar/Container
}

func _ready():

	PlayerProfile.current_deck.clear()

	tab_container.current_tab = 0

	if PlayerProfile.owned_cards.is_empty():
		var all_keys = CardRegistry.all_cards.keys()

		for i in range(min(15, all_keys.size())):
			PlayerProfile.add_card_to_inventory(all_keys[i])

	save_deck.pressed.connect(_on_save_button_pressed)

	card_description.hide()

	refresh_ui()

	# Make sure the All tab is visible before tutorial starts
	tab_container.current_tab = 0

	await get_tree().process_frame
	await get_tree().process_frame

	if !PlayerProfile.tutorial_steps_completed.get("deck_builder", false):
		await start_spellbook_tour()
func refresh_ui():

	for grid in grids.values():
		for child in grid.get_children():
			child.queue_free()

	for path in PlayerProfile.owned_cards:

		if !CardRegistry.all_cards.has(path):
			continue

		var data = CardRegistry.all_cards[path]
		var category = GameEnums.CardCategory.keys()[data.category].to_lower()

		spawn_slot(path, grids["all"])

		if grids.has(category):
			spawn_slot(path, grids[category])

	update_deck_counter()


func spawn_slot(path:String, grid:GridContainer):

	var slot = SLOT_SCENE.instantiate()

	grid.add_child(slot)

	slot.setup(path)

	slot.hovered.connect(_on_card_hovered)
	slot.selection_changed.connect(_on_card_selected)


func _on_card_hovered(card_path:String):
	show_card(card_path)


func _on_card_selected(card_path:String):

	for grid in grids.values():
		for slot in grid.get_children():
			if slot.has_method("update_selection_visuals"):
				slot.update_selection_visuals()

	update_deck_counter()

	show_card(card_path)


func show_card(card_path:String):

	if !CardRegistry.all_cards.has(card_path):
		return

	var data: CardData = CardRegistry.all_cards[card_path]

	card_description.show()

	preview_card.display_info(data)

	preview_name.text = data.name

	preview_rarity.text = "%s • %s" % [
		GameEnums.CardRarity.keys()[data.rarity],
		GameEnums.CardCategory.keys()[data.category].capitalize()
	]

	preview_rarity.show()

	preview_description.text = data.description

	mana_cost.text = "Cost: %d Mana" % data.mana_cost

	battle_effects.text = "Effects:\n"

	if data.damage > 0:
		battle_effects.text += "Damage: %d\n" % data.damage

	if data.heal > 0:
		battle_effects.text += "Heal: %d\n" % data.heal

	if data.multiplier > 0:
		battle_effects.text += "Multiplier: %.1f\n" % data.multiplier
		
		
func update_deck_counter():

	var count = PlayerProfile.current_deck.size()

	status_label.text = "%d / %d" % [count, MAX_DECK_SIZE]

	var valid = count >= MIN_DECK_SIZE and count <= MAX_DECK_SIZE

	save_deck.disabled = !valid
	save_deck.modulate = Color.WHITE if valid else Color(0.5, 0.5, 0.5, 0.7)


func _on_save_button_pressed():

	var count = PlayerProfile.current_deck.size()

	if count < MIN_DECK_SIZE or count > MAX_DECK_SIZE:
		print("Deck must contain between %d and %d cards.")
		return

	SaveManager.save_game()

	if !PlayerProfile.pending_scene.is_empty():
		print("[DECK BUILDER] Launching stored path destination: ", PlayerProfile.pending_scene)
		get_tree().change_scene_to_file(PlayerProfile.pending_scene)
	else:
		# Safety fallback if profile scene tracker was unassigned
		get_tree().change_scene_to_file("res://scenes/menus/map.tscn")


func get_first_card_slot():

	var grid = grids["all"]

	if grid.get_child_count() == 0:
		return null

	return grid.get_child(0)

func start_spellbook_tour():

	tutorial_active = true

	var base = "res://data/StoryData/Tutorial/DeckBuilder/"

	# Always start on the All tab
	tab_container.current_tab = 0
	# Category tabs
	await StoryManager.play_group_tutorial(
		base + "categories.tres",
		[
			$TabContainer/All,
			$TabContainer/Kalikasan,
			$TabContainer/Tanglaw,
			$TabContainer/Diwa,
			$TabContainer/Lahi
		]
	)
	# Wait a couple of frames so the GridContainer finishes laying out
	await get_tree().process_frame
	await get_tree().process_frame

	# Wait until at least one card exists
	while grids["all"].get_child_count() == 0:
		await get_tree().process_frame

	# Highlight the first card
	var first_card = grids["all"].get_child(0)

	if first_card:
		await highlight_and_talk(
			first_card,
			base + "cards.tres"
		)

	# Card information panel
	await highlight_and_talk(
		$CardDescription,
		base + "description_panel.tres"
	)

	# Deck counter
	await highlight_and_talk(
		$StatusLabel,
		base + "deck_counter.tres"
	)

	# Save button
	await highlight_and_talk(
		$SaveDeck,
		base + "save_button.tres"
	)

	tutorial_active = false

	PlayerProfile.tutorial_steps_completed["deck_builder"] = true

	SaveManager.save_game()

func highlight_and_talk(node: CanvasItem, data_path: String):

	if !is_instance_valid(node):
		return

	await get_tree().process_frame

	var copy := node.duplicate(Node.DUPLICATE_USE_INSTANTIATION)

	highlight_layer.add_child(copy)

	if copy is Control and node is Control:

		copy.set_anchors_preset(Control.PRESET_TOP_LEFT)

		copy.anchor_left = 0
		copy.anchor_top = 0
		copy.anchor_right = 0
		copy.anchor_bottom = 0

		copy.position = node.global_position
		copy.size = node.size
		copy.scale = node.scale
		copy.rotation = node.rotation
		copy.pivot_offset = node.pivot_offset

		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE

	copy.z_index = 9999

	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await StoryManager.play_tutorial(data_path, node)

	copy.queue_free()

	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_STOP

	await get_tree().create_timer(0.1).timeout

func _unhandled_input(event):

	if tutorial_active:
		get_viewport().set_input_as_handled()
