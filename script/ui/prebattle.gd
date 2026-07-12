extends Control

signal transition_finished

@onready var player_portrait: TextureRect = $PlayerPortrait
@onready var enemy_portrait: TextureRect = $EnemyPortrait
@onready var vs: TextureRect = $VS
@onready var click: Label = $Click

const DEFAULT_PORTRAIT_PATH = "res://data/Characters/default_girl.tres"
const PREBATTLE_SFX_PATH = "res://data/SoundData/sfx/prebattle.ogg"

# Track when input is allowed
var can_skip: bool = false

func _ready() -> void:
	# Hide the click prompt completely at the start
	click.modulate.a = 0.0
	
	setup_portraits()
	run_cinematic_intro()
	start_screen_timer()

func _input(event: InputEvent) -> void:
	# Check if the player clicks or presses a key after the 3-second window
	if can_skip and (event is InputEventMouseButton or event is InputEventKey):
		if event.is_pressed():
			can_skip = false # Prevent double triggers
			transition_finished.emit()

func setup_portraits() -> void:
	var player_char_id = PlayerProfile.selected_character
	var player_path = DEFAULT_PORTRAIT_PATH
	
	if player_char_id != "None" and player_char_id != "":
		player_path = "res://data/Characters/%s.tres" % player_char_id
		
	var player_data = load(player_path) as CharacterData
	if player_data and player_data.portrait: 
		player_portrait.texture = player_data.portrait
	else:
		var default_data = load(DEFAULT_PORTRAIT_PATH) as CharacterData
		if default_data and default_data.portrait:
			player_portrait.texture = default_data.portrait

	var level_data = PlayerProfile.get_current_level_data()
	if level_data and level_data.enemy_data:
		var enemy_data = level_data.enemy_data
		if enemy_data.enemy_portait:
			enemy_portrait.texture = enemy_data.enemy_portait

func run_cinematic_intro() -> void:
	var screen_width = get_viewport_rect().size.x
	
	var p_target_x = player_portrait.position.x
	var e_target_x = enemy_portrait.position.x
	
	player_portrait.position.x = -player_portrait.size.x
	enemy_portrait.position.x = screen_width + enemy_portrait.size.x
	
	vs.pivot_offset = vs.size / 2
	vs.scale = Vector2(4.0, 4.0)
	vs.modulate.a = 0.0
	
	var intro_tween = create_tween().set_parallel(true)
	
	intro_tween.tween_property(player_portrait, "position:x", p_target_x, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	intro_tween.tween_property(enemy_portrait, "position:x", e_target_x, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	var vs_tween = create_tween()
	vs_tween.tween_interval(0.25)
	
	vs_tween.tween_property(vs, "modulate:a", 1.0, 0.15)
	vs_tween.tween_property(vs, "scale", Vector2(1.0, 1.0), 0.25)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	vs_tween.tween_callback(func():
		AudioManager.play_sound_from_path(PREBATTLE_SFX_PATH, false, 0.0)
	)

func start_screen_timer() -> void:
	await get_tree().create_timer(3.0).timeout
	can_skip = true
	
	var text_tween = create_tween().set_loops()
	text_tween.tween_property(click, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	text_tween.tween_property(click, "modulate:a", 0.2, 0.6).set_trans(Tween.TRANS_SINE)
