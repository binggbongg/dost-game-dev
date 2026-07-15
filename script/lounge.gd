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

@onready var level_label = $Buttons/Content/CharacterSpotlight/PLayerLevel

@onready var shop_button = $Buttons/Content/shop

var tutorial_active = false

var chapter_buttons: Array[BaseButton] = []

func _ready():
	AudioManager.play_sound_from_path("res://data/SoundData/bgm/lounge.wav", true)
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
	
	if shop_button:
		shop_button.modulate = Color(0.3, 0.3, 0.3, 0.9)
	
	# --- NEW PROGRESSION LOCK INITIALIZATION ---
	collect_and_update_chapter_locks()
	
	# Updates the current phase
	level_label.text = "Chapter " + str(PlayerProfile.get_highest_unlocked_chapter())
	
	#Temporary disabling of button
	$Buttons/Content/Settings.modulate = Color(0.3, 0.3, 0.3, 0.9)
	
	
	# --- TEMP CHAPTER 4+ HARD LOCK ---
	# Delete or comment out this function call to remove the restriction later.
	_temp_disable_high_chapters()
	
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
		[$Buttons/Content/shop, "shop.tres"]
		#[$Buttons/Content/PVP, "battle.tres"],
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
	AudioManager.play_ui_sound("click")
	SceneTransition.change_scene_path("res://scenes/menus/play.tscn")

func give_starter_packs():
	var pack_layer = get_node_or_null("PackLayer")
	if not pack_layer:
		pack_layer = CanvasLayer.new()
		pack_layer.name = "PackLayer"
		pack_layer.layer = 100
		add_child(pack_layer)

	for i in range(3):
		var pack_instance = pack_scene.instantiate()
		pack_layer.add_child(pack_instance)
		pack_instance.open_pack(true) 
		if i == 0:
			var base_path = "res://data/StoryData/Tutorial/LoungeScreen/"
			await StoryManager.play_card_pack_tutorial(
				base_path + "starter_packs_intro.tres",
				pack_instance
			)
		await pack_instance.tree_exited 
		if i < 4:
			await get_tree().create_timer(0.3).timeout


func collect_and_update_chapter_locks() -> void:
	chapter_buttons.clear()
	
	var ch1 = get_node_or_null("ChapterOne")
	if ch1 and ch1 is BaseButton:
		chapter_buttons.append(ch1)
		
	for i in range(2, 15):
		var btn = get_node_or_null(str(i))
		if btn and btn is BaseButton:
			chapter_buttons.append(btn)
			
	var current_max_unlocked = PlayerProfile.max_unlocked_chapters
	
	var current_max = PlayerProfile.max_unlocked_chapters
	
	for idx in range(chapter_buttons.size()):
		var target_btn = chapter_buttons[idx]
		var chapter_num = idx + 1
		
		# Reset any previous tweens if the node is reused
		var existing_tweens = get_tree().get_processed_tweens().filter(func(t): return t.is_valid())
		
		if chapter_num <= current_max:
			target_btn.disabled = false
			target_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			if chapter_num == current_max and chapter_num < 4:
				apply_glow(target_btn)
				
			if not target_btn.pressed.is_connected(_on_chapter_button_pressed):
				target_btn.pressed.connect(_on_chapter_button_pressed.bind(chapter_num))
		else:
			target_btn.disabled = true
			target_btn.modulate = Color(0.3, 0.3, 0.3, 0.8)

func _on_chapter_button_pressed(chapter_num: int):
	AudioManager.play_ui_sound("click")
	PlayerProfile.selected_chapter = chapter_num
	PlayerProfile.current_phase = chapter_num
		
	var path = "res://data/Levels/level_%d-%d.tres" % [PlayerProfile.current_phase, PlayerProfile.current_level]
	if ResourceLoader.exists(path):
		PlayerProfile.set_next_level(load(path))
		
	SceneTransition.change_scene_path("res://scenes/menus/map.tscn")

func apply_glow(node: CanvasItem):
	var tween = create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.8) # Brighten
	tween.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8) # Return to normal

# --- TEMPORARY FUNCTION FOR REMOVABILITY ---
func _temp_disable_high_chapters() -> void:
	# Look up the numbered buttons directly inside this function to ensure they lock down
	for i in range(4, 15):
		var btn = get_node_or_null(str(i))
		if btn and btn is BaseButton:
			btn.disabled = true
			btn.modulate = Color(0.3, 0.3, 0.3, 0.8)
