extends Node2D

@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer/Control

# Managers
@onready var turn_manager = $PlayerInterface/GameManagers/TurnManager
@onready var input_manager = $PlayerInterface/GameManagers/InputManager
@onready var player_hand = $PlayerInterface/GameManagers/PlayerHand

# UI
@onready var health = $CombatArena/Player/HealthBar
@onready var timer_bar = $TimerBar
@onready var timer = $TimerBar/TimeText
@onready var deck = $PlayerInterface/UI/Deck/Sprite2D
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
	deck_clicked = true

func start_battle_tutorial():
	tutorial_active = true
	var base = "res://data/StoryData/Tutorial/Level 1/"
	
	await highlight_and_talk(deck, base + "Deck.tres")
	turn_manager.start_game()

	while !deck_clicked:
		await get_tree().process_frame
	
	await get_tree().create_timer(0.8).timeout 

	var valid_cards = player_hand.player_cards.filter(func(c): return is_instance_valid(c))
	await highlight_group_and_talk(valid_cards, base + "playerhand.tres")

	await get_tree().create_timer(0.2).timeout 

	await highlight_group_and_talk([slot1, slot2, slot3], base + "slot.tres")
	
	# Group these to ensure smooth transitions
	var steps = [
		[health, "health.tres"],
		[spellbook, "spellbook.tres"],
		[inventory, "inventory.tres"],
		[timer, "timer.tres"],
		[undo_button, "redo.tres"],
		[cast_button, "cast.tres"],
		[end_turn, "endturn.tres"]
	]

	for step in steps:
		await highlight_and_talk(step[0], base + step[1])

	PlayerProfile.tutorial_steps_completed["battle_tutorial"] = true
	
	# --- CLEANUP TUTORIAL UI BEFORE OUTRO ---
	dimmer.hide()
	# Optional: if StoryManager has a cleanup function, call it here
	# StoryManager.mechanics_ui.hide_everything() 

	var end_screen_path = "res://scenes/story/chap1outro.tscn" 
	var end_screen = load(end_screen_path).instantiate()
	get_tree().root.add_child(end_screen)
	
	await end_screen.finished
	SceneTransition.change_scene_path("res://scenes/levels/Level1.tscn")

func highlight_and_talk(node: CanvasItem, data_path: String):
	if !is_instance_valid(node): return
	
	var copy := node.duplicate()
	copy.visible = false # Prevent 1-frame flicker at (0,0)
	highlight_layer.add_child(copy)

	# Use Canvas Transform for 100% accurate visual match
	var visual_transform = node.get_global_transform_with_canvas()
	copy.global_position = visual_transform.get_origin()
	copy.scale = visual_transform.get_scale()
	
	if copy is Control:
		copy.pivot_offset = Vector2.ZERO # Fix misalignment
		copy.size = node.size

	copy.visible = true

	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# IMPORTANT: Pass 'node' (original) for math, not 'copy'
	await StoryManager.play_tutorial(data_path, node)

	copy.queue_free()
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Small delay between steps prevents "skipping" glitches
	await get_tree().create_timer(0.1).timeout

func highlight_group_and_talk(nodes: Array, data_path: String):
	var copies := []
	var targets := []

	for node in nodes:
		if !is_instance_valid(node): continue
		targets.append(node)
		
		var copy = node.duplicate()
		copy.visible = false
		highlight_layer.add_child(copy)

		var visual_transform = node.get_global_transform_with_canvas()
		copy.global_position = visual_transform.get_origin()
		copy.scale = visual_transform.get_scale()
		
		if copy is Control:
			copy.pivot_offset = Vector2.ZERO
			copy.size = node.size
		
		copy.visible = true
		copies.append(copy)

	await StoryManager.play_group_tutorial(data_path, targets)

	for copy in copies:
		if is_instance_valid(copy):
			copy.queue_free()

	await get_tree().create_timer(0.1).timeout
