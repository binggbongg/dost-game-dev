extends Node2D

@onready var cam = $Camera2D
@onready var map = $Map
@onready var buttons_container = $Buttons/Content
@onready var tutorial_layer = $TutorialLayer
@onready var dimmer = $TutorialLayer/Dimmer
@onready var highlight_layer = $HighlightLayer/Control 

var tutorial_active = false

func _ready():
	await get_tree().process_frame
	center_camera()
	dimmer.hide()
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
		tutorial_active = false
		PlayerProfile.tutorial_steps_completed["lounge_tour"] = true

func highlight_and_talk(node: Control, data_path: String):
	# Store original info
	var old_parent = node.get_parent()
	var old_index = node.get_index()
	var old_pos = node.global_position
	
	node.reparent(highlight_layer)
	node.global_position = old_pos 
	print("Starting tutorial:", node.name)
	print("Data path:", data_path)

	await StoryManager.play_tutorial(data_path, node)

	print("Finished tutorial:", node.name)
	node.reparent(old_parent)
	old_parent.move_child(node, old_index)
	node.modulate = Color.WHITE


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
	
