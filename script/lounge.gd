extends Node2D

@onready var cam = $Camera2D
@onready var map = $Map
@onready var buttons_container = $Buttons/Content
@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer/Control 
@onready var player_name: Label = $Buttons/Content/CharacterSpotlight/PlayerName
@onready var me: AnimatedSprite2D = $Buttons/Content/CharacterSpotlight/Character
@onready var back: TextureButton = $Buttons/Content/Back
@export var pack_scene: PackedScene 
var tutorial_active = false

func _ready():
	back.pressed.connect(func(): back_button_pressed())
	await get_tree().process_frame
	center_camera()
	dimmer.hide()
	if PlayerProfile.player_name != "Default Player":
		player_name.text = PlayerProfile.player_name
	if PlayerProfile.selected_character != "None":
		var character_id = PlayerProfile.selected_character
		var path = "res://data/Characters/%s.tres" % character_id
		var character_data := load(path) as CharacterData
		if character_data:
			me.sprite_frames = character_data.sprite_frames
			me.play("idle")
	if not PlayerProfile.tutorial_steps_completed.get("lounge_tour", false):
		start_lounge_tour()

func center_camera():
	var view = get_viewport().get_visible_rect().size
	var actual_size = map.size * map.scale

	cam.position = Vector2(
		map.position.x + actual_size.x / 2 - 150,
		map.position.y + actual_size.y - view.y / 2
	)

	limit_camera_view()

func start_lounge_tour():
	tutorial_active = true
	var base_path = "res://data/StoryData/Tutorial/LoungeScreen/"

	var first_steps = [
		[$Buttons/Content/CharacterSpotlight, "characterspotlight.tres"],
		[$Buttons/Content/Lore, "lore.tres"],
		[$Buttons/Content/Trophy, "leaderboard.tres"],
		[$Buttons/Content/CoinDisplay/Coin, "coins.tres"],
		[$Buttons/Content/Settings, "settings.tres"],
		[$Buttons/Content/spellbook, "spellbook.tres"],
		[$Buttons/Content/shop, "shop.tres"],
		[$Buttons/Content/PVP, "battle.tres"],
	]

	for step in first_steps:
		await highlight_and_talk(step[0], base_path + step[1])

	await give_starter_packs()

	await highlight_and_talk(
		$ChapterOne,
		base_path + "chapter.tres"
	)

	tutorial_active = false
	PlayerProfile.tutorial_steps_completed["lounge_tour"] = true
	SaveManager.save_game()
func highlight_and_talk(node: CanvasItem, data_path: String):
	if !is_instance_valid(node): return
	
	await get_tree().process_frame 
	
	var copy := node.duplicate()
	copy.visible = false
	highlight_layer.add_child(copy)

	var visual_transform = node.get_global_transform_with_canvas()
	copy.global_position = visual_transform.get_origin()
	copy.scale = visual_transform.get_scale()
	
	if copy is Control:
		copy.pivot_offset = Vector2.ZERO
	
	copy.visible = true
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	await StoryManager.play_tutorial(data_path, node)
	copy.queue_free()
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().create_timer(0.1).timeout

func limit_camera_view():
	var view = get_viewport().get_visible_rect().size

	var actual_size = map.size * map.scale

	var left = map.position.x
	var top = map.position.y
	var right = left + actual_size.x
	var bottom = top + actual_size.y

	cam.position.x = clamp(
		cam.position.x,
		left + view.x / 2,
		right - view.x / 2
	)

	cam.position.y = clamp(
		cam.position.y,
		top + view.y / 2,
		bottom - view.y / 2
	)
func _unhandled_input(event):
	if tutorial_active: return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		cam.position -= event.relative / cam.zoom
		limit_camera_view()
	
func back_button_pressed():
	SceneTransition.change_scene_path("res://scenes/menus/play.tscn")
func give_starter_packs():
	var pack_layer = get_node_or_null("PackLayer")
	if not pack_layer:
		pack_layer = CanvasLayer.new()
		pack_layer.name = "PackLayer"
		pack_layer.layer = 100
		add_child(pack_layer)

	for i in range(5):
		var pack_instance = pack_scene.instantiate()
		pack_layer.add_child(pack_instance)
		
		# 1. Open the pack visuals
		pack_instance.open_pack(true) 
		
		# 2. TUTORIAL INTEGRATION
		# If this is the very first pack, we highlight it and play the dialogue
		if i == 0:
			var base_path = "res://data/StoryData/Tutorial/LoungeScreen/"
			# We pass 'pack_instance' as the node to highlight.
			# This makes the pack stay bright while the character talks!
			await highlight_and_talk(pack_instance, base_path + "starter_packs_intro.tres")
		
		# 3. Wait for the player to finish swiping all 5 cards
		await pack_instance.tree_exited 
		
		# Small delay before the next pack pops up
		if i < 4:
			await get_tree().create_timer(0.3).timeout
	
