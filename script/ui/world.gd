extends Node2D

@export var dialogue_resource: DialogueResource 
@onready var scene: Control = $Scene

@onready var player: AnimatedSprite2D = $Scene/Player 
@onready var enemy: Node2D = $Scene/Enemy             # This is your Karabao
@onready var gem: Sprite2D = $Gem
@onready var conversation: CanvasLayer = $Conversation
@onready var player_area: Area2D = $Scene/Player/Area2D
@onready var enemy_area: Area2D = $Scene/Enemy/Area2D

var char_data: CharacterData
var active_story_data: StoryData
var can_move: bool = false
var reached_enemy: bool = false
var float_tween: Tween

func _ready() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/bgm/cutscene.wav", true)
	setup_player_visuals()
	
	# Gray out the Karabao right away so it looks completely dead
	if enemy:
		enemy.modulate = Color(0.35, 0.35, 0.35)
	
	# Initialize Gem position at enemy body, completely invisible
	gem.visible = false
	gem.modulate.a = 0.0
	gem.position = enemy.position 
	
	player_area.area_entered.connect(_on_player_reached_enemy)

func setup_player_visuals() -> void:
	var character_id = PlayerProfile.selected_character
	var path = "res://data/Characters/%s.tres" % character_id
	
	if character_id != "None" and ResourceLoader.exists(path):
		char_data = load(path) as CharacterData
	else:
		char_data = load("res://data/Characters/boy_plain.tres") as CharacterData
	
	if char_data:
		player.sprite_frames = char_data.sprite_frames
		player.play(char_data.idle_animation)
		
		# Pass the whole SpriteFrames layout over to the Canvas Layer
		conversation.player_sprite_frames = char_data.sprite_frames

func _process(delta: float) -> void:
	if can_move and not reached_enemy:
		handle_player_movement(delta)

func handle_player_movement(delta: float) -> void:
	var velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if velocity != Vector2.ZERO:
		player.position += velocity * 250.0 * delta
		if player.animation != char_data.walk_animation:
			player.play(char_data.walk_animation)
		player.flip_h = velocity.x < 0
	else:
		if player.animation != char_data.idle_animation:
			player.play(char_data.idle_animation)

# --- CUTSCENE STEP-BY-STEP TIMELINE ---

func start_world_cutscene(data: StoryData) -> void:
	active_story_data = data
	
	# Feed the Gem's flat portrait texture into the dialogue box system
	if active_story_data:
		conversation.gem_portrait = active_story_data.portrait

	# Step 1: Player Thinks ("Is it finally over?")
	await conversation.play_sequence(dialogue_resource, "intro")
	
	# Step 2: Gem Pops up from dead enemy body with delayed reaction window
	await play_gem_spawn_anim()
	
	# Step 3: Player Reaction ("Let's move towards it.")
	await conversation.play_sequence(dialogue_resource, "see_gem")
	
	# Step 4: Show Movement Tutorial 
	var already_seen = PlayerProfile.tutorial_steps_completed.get("cut_scene", false)
	if not already_seen:
		await StoryManager.play_tutorial("res://data/StoryData/Tutorial/CutScene/player_move.tres", scene)
	
	can_move = true

func play_gem_spawn_anim() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	gem.visible = true
	
	# Configure initial bright glow intensity using self_modulate overdrive values
	gem.self_modulate = Color(1.5, 1.3, 1.5, 1.0) 
	
	var spawn_tween = create_tween().set_parallel(true)
	var target_y = enemy.position.y - 80
	
	# Glides the Gem up 80 pixels above the enemy while bringing opacity to full
	spawn_tween.tween_property(gem, "position:y", target_y, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spawn_tween.tween_property(gem, "modulate:a", 1.0, 0.5)
	
	# DELAYED SHOCK: Wait 0.25 seconds after the gem starts popping up before shifting player to shock anim
	get_tree().create_timer(1.0).timeout.connect(func():
		if player.animation != char_data.shock_animation:
			player.play(char_data.shock_animation)
	)
	
	await spawn_tween.finished
	player.play(char_data.idle_animation)
	
	# Start continuous floating loop and subtle glow pulse sequence now that it has arrived
	start_gem_idle_loop(target_y)

func start_gem_idle_loop(base_y: float) -> void:
	if float_tween:
		float_tween.kill()
		
	float_tween = create_tween().set_loops().set_parallel(true)
	
	# Subtle up and down translation loop over 1.8 seconds
	float_tween.tween_property(gem, "position:y", base_y - 8.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(gem, "position:y", base_y, 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Matching glowing pulse oscillation sequence
	float_tween.tween_property(gem, "self_modulate", Color(1.8, 1.5, 1.8, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(gem, "self_modulate", Color(1.3, 1.1, 1.3, 1.0), 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE)

func _on_player_reached_enemy(area: Area2D) -> void:
	if area == enemy_area and can_move and not reached_enemy:
		can_move = false
		reached_enemy = true
		player.play(char_data.idle_animation)
		
		# Step 5: Continue Dialogue Timeline (The long Chapter 1 Star Fragment reveal)
		await conversation.play_sequence(dialogue_resource, "chapter1_star_fragment")
		
		finish_cutscene()

func finish_cutscene() -> void:
	if float_tween:
		float_tween.kill()
		
	PlayerProfile.tutorial_steps_completed["cut_scene"] = true
	SaveManager.save_game()
	
	# Plays your loud sound effect
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	
	# Wait for 3 seconds so the player can hear the sound effect completely
	await get_tree().create_timer(3.0).timeout
	
	# Begin the fade out sequence
	var fade = create_tween()
	fade.tween_property(gem, "modulate:a", 0.0, 0.5)
	await fade.finished
	
	SceneTransition.change_scene_path("res://scenes/menus/Lounge.tscn")

# --- DEBUG TRIGGER ---
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_0:
		var test_data = load("res://data/StoryData/Post Boss/chapter_one.tres") as StoryData
		start_world_cutscene(test_data)
