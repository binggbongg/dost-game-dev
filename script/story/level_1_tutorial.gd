extends Node2D

@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer/Control   # <-- Make sure this matches your scene!

# Managers
@onready var turn_manager = $PlayerInterface/GameManagers/TurnManager
@onready var input_manager = $PlayerInterface/GameManagers/InputManager
@onready var player_hand = $PlayerInterface/GameManagers/PlayerHand

# UI
@onready var health = $CombatArena/Player/HealthBar
@onready var timer_bar = $TimerBar
@onready var timer = $TimerBar/TimeText
@onready var deck = $PlayerInterface/UI/Deck
@onready var cast_button = $PlayerInterface/UI/CastButton
@onready var undo_button = $PlayerInterface/UI/UndoButton
@onready var end_turn = $PlayerInterface/UI/EndTurn

# Slots
@onready var slot1 = $PlayerInterface/Slots/CardSlot
@onready var slot2 = $PlayerInterface/Slots/CardSlot2
@onready var slot3 = $PlayerInterface/Slots/CardSlot3

# Top Buttons
@onready var spellbook = $Buttons/spellbook
@onready var inventory = $Buttons/Inventory

var tutorial_active := false
var deck_clicked := false

func _ready():
	dimmer.hide()

	turn_manager.auto_start = false

	input_manager.deck_clicked.connect(_on_deck_clicked)

	if !PlayerProfile.tutorial_steps_completed.get("battle_tutorial", false):
		start_battle_tutorial()


func _on_deck_clicked():
	print("Deck clicked signal received!")
	deck_clicked = true

func start_battle_tutorial():
	tutorial_active = true
	var base = "res://data/StoryData/Tutorial/Level 1/"
	print("Health")
	await highlight_and_talk(health, base + "health.tres")
	print("Timer")
	await highlight_and_talk(timer, base + "timer.tres")
	print("Deck")
	await highlight_and_talk(deck, base + "Deck.tres")
	print("Start game")
	# Begin battle
	turn_manager.start_game()

	print("Waiting for deck click...")
	while !deck_clicked:
		await get_tree().process_frame
	
	print("Deck was clicked!")
	
	# --- ADD THIS DELAY ---
	# Wait for cards to fly out of the deck and settle in the hand
	await get_tree().create_timer(0.8).timeout 
	# ----------------------

	print("================")
	print("Cards in hand: ", player_hand.player_cards.size())

	# It's safer to filter out any nulls just in case
	var valid_cards = player_hand.player_cards.filter(func(c): return is_instance_valid(c))

	await highlight_group_and_talk(
		valid_cards,
		base + "playerhand.tres"
	)

	# Small buffer to prevent the "skipping" feeling
	await get_tree().create_timer(0.2).timeout 

	print("Highlighting Slots")
	await highlight_group_and_talk(
		[slot1, slot2, slot3],
		base + "slot.tres"
	)

	await highlight_and_talk(cast_button, base + "cast.tres")
	await highlight_and_talk(undo_button, base + "redo.tres")
	await highlight_and_talk(end_turn, base + "endturn.tres")
	await highlight_and_talk(spellbook, base + "spellbook.tres")
	await highlight_and_talk(inventory, base + "inventory.tres")

	PlayerProfile.tutorial_steps_completed["battle_tutorial"] = true

	get_tree().change_scene_to_file("res://scenes/levels/Level1.tscn")


func highlight_and_talk(node: CanvasItem, data_path: String):
	var copy := node.duplicate()

	highlight_layer.add_child(copy)

	if node is Control:
		copy.global_position = node.global_position
	elif node is Node2D:
		copy.global_position = node.global_position

	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await StoryManager.play_tutorial(data_path, copy)

	copy.queue_free()

	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_STOP

func highlight_group_and_talk(nodes: Array, data_path: String):
	print("Step: Starting group highlight for ", data_path)
	var copies := []
	var targets := []

	for node in nodes:
		if !is_instance_valid(node): continue
		targets.append(node)
		var copy = node.duplicate()
		highlight_layer.add_child(copy)

		if node is Control:
			copy.global_position = node.get_global_rect().position
			copy.size = node.size
		elif node is Node2D:
			copy.global_position = node.global_position
			if "z_index" in copy: copy.z_index = 100
		copies.append(copy)

	# Await the actual tutorial UI
	await StoryManager.play_group_tutorial(data_path, targets)
	print("Step: Tutorial UI closed, cleaning up copies.")

	for copy in copies:
		if is_instance_valid(copy):
			copy.queue_free()

	# Give Godot a tiny moment to breathe before next task
	await get_tree().process_frame
