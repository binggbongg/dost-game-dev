extends Node2D

@onready var cam = $Camera2D
@onready var map = $Map
@onready var buttons_container = $Buttons/Content
@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer/Control 
@onready var player_name: Label = $Buttons/Content/CharacterSpotlight/PlayerName
@onready var me: AnimatedSprite2D = $Buttons/Content/CharacterSpotlight/Character

var tutorial_active = false

func _ready():
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
	var view = get_viewport_rect().size
	var m_rect = map.get_global_rect()
	cam.position.x = m_rect.position.x + (view.x / 2)
	cam.position.y = m_rect.end.y - (view.y / 2)
	limit_camera_view()


func start_lounge_tour():
	tutorial_active = true
	var base_path = "res://data/StoryData/Tutorial/LoungeScreen/"
	
	var tour_steps = [
		[$Buttons/Content/CharacterSpotlight, "characterspotlight.tres"],
		[$Buttons/Content/Lore, "lore.tres"],
		[$Buttons/Content/Trophy, "leaderboard.tres"],
		[$Buttons/Content/CoinDisplay, "coins.tres"],
		[$Buttons/Content/Settings, "settings.tres"],
		[$Buttons/Content/spellbook, "spellbook.tres"],
		[$Buttons/Content/shop, "shop.tres"],
		[$Buttons/Content/PVP, "battle.tres"],
		[$ChapterOne, "chapter.tres"],
	]

	for step in tour_steps:
		await highlight_and_talk(step[0], base_path + step[1])
	
	# MOVE THESE HERE - Outside the loop
	tutorial_active = false
	PlayerProfile.tutorial_steps_completed["lounge_tour"] = true
func highlight_and_talk(node: CanvasItem, data_path: String):
	if !is_instance_valid(node): return
	
	# 1. Wait a frame to ensure camera movement from the previous click is stopped
	await get_tree().process_frame 
	
	var copy := node.duplicate()
	copy.visible = false # Hide immediately to prevent 1-frame flicker at (0,0)
	highlight_layer.add_child(copy)

	# 2. Get the screen position relative to the MOVING camera
	var visual_transform = node.get_global_transform_with_canvas()
	copy.global_position = visual_transform.get_origin()
	copy.scale = visual_transform.get_scale()
	
	# 3. Force the pivot to zero so the copy doesn't shift
	if copy is Control:
		copy.pivot_offset = Vector2.ZERO
	
	copy.visible = true

	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 4. Pass the original node to the system for spotlight math
	await StoryManager.play_tutorial(data_path, node)

	copy.queue_free()

	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 5. Brief pause before next step to make the transition look smooth
	await get_tree().create_timer(0.1).timeout
func limit_camera_view():
	var view = get_viewport_rect().size
	var m_rect = map.get_global_rect()
	cam.position.x = clamp(cam.position.x, m_rect.position.x + (view.x / 2), m_rect.end.x - (view.x / 2))
	cam.position.y = clamp(cam.position.y, m_rect.position.y + (view.y / 2), m_rect.end.y - (view.y / 2))

func _unhandled_input(event):
	if tutorial_active: return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		cam.position -= event.relative / cam.zoom
		limit_camera_view()
	
