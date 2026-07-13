extends CanvasLayer
signal cutscene_finished
@export var dialogue_resource: DialogueResource 
@onready var scene: Control = $Scene

# have this skip the dialgoue and play the part where the gem join the player before scene ends
@onready var skip: TextureButton = $Skip

@onready var player: AnimatedSprite2D = $Scene/Player 
@onready var enemy: Node2D = $Scene/Enemy          
@onready var gem: Sprite2D = $Gem
@onready var conversation: CanvasLayer = $Conversation
@onready var player_area: Area2D = $Scene/Player/Area2D
@onready var enemy_area: Area2D = $Scene/Enemy/Area2D

var char_data: CharacterData
var active_story_data: StoryData
var can_move: bool = false
var reached_enemy: bool = false
var float_tween: Tween
var is_skipping: bool = false

func _ready() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/bgm/cutscene.wav", true)
	setup_player_visuals()
	
	# 🛠️ LOGIC UPDATE: Hide the skip/exit button right away at start
	if skip:
		skip.hide()
		skip.pressed.connect(_on_skip_pressed)
	
	# --- ZOOM EFFECT SETUP ---
	if scene:
		scene.pivot_offset = get_viewport().get_visible_rect().size / 2.0
		scene.scale = Vector2(0.7, 0.7)
		
		var zoom_tween = create_tween()
		zoom_tween.tween_property(scene, "scale", Vector2(1.0, 1.0), 1.5)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
	# -------------------------

	if enemy:
		enemy.modulate = Color(0.35, 0.35, 0.35)
	
	gem.visible = false
	gem.modulate.a = 0.0
	if enemy:
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

# --- SKIP LOGIC ---
func _on_skip_pressed() -> void:
	if is_skipping: return
	is_skipping = true
	print("[Cutscene] Skipping directly to final sound and ending...")
	
	can_move = false
	reached_enemy = true
	if skip:
		skip.hide()
		
	if float_tween:
		float_tween.kill()
		
	if conversation:
		conversation.is_active = false
		if conversation.typewriter_tween:
			conversation.typewriter_tween.kill()
		if conversation.dialogue_box:
			conversation.dialogue_box.hide()
		conversation.line_finished.emit()

	# 🛠️ INSTANT POSITIONING (No overlap, keeps player at the foot on the left side)
	if enemy and player:
		player.position = Vector2(enemy.position.x - 145.0, enemy.position.y)
		player.play(char_data.idle_animation)
		player.flip_h = false

	if gem:
		gem.visible = false
		gem.modulate.a = 0.0
		
	# Play the final collection sound bit directly, bypass all waiting elements entirely
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	
	cutscene_finished.emit()

# --- CUTSCENE STEP-BY-STEP TIMELINE ---

func start_world_cutscene(data: StoryData) -> void:
	active_story_data = data
	
	if active_story_data and conversation:
		conversation.gem_portrait = active_story_data.portrait

	# Intro plays out naturally first without a skip option visible
	await conversation.play_sequence(dialogue_resource, "intro")
	await play_gem_spawn_anim()

	await conversation.play_sequence(dialogue_resource, "see_gem")
	if skip:
		skip.show()
	
	var already_seen = PlayerProfile.tutorial_steps_completed.get("cut_scene", false)
	if not already_seen:
		await StoryManager.play_tutorial("res://data/StoryData/Tutorial/CutScene/player_move.tres", scene)
	if is_skipping: return
	
	can_move = true

func play_gem_spawn_anim() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	gem.visible = true
	gem.self_modulate = Color(1.5, 1.3, 1.5, 1.0) 
	
	var spawn_tween = create_tween().set_parallel(true)
	var target_y = enemy.position.y - 80
	
	spawn_tween.tween_property(gem, "position:y", target_y, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spawn_tween.tween_property(gem, "modulate:a", 1.0, 0.5)
	
	get_tree().create_timer(1.0).timeout.connect(func():
		if not is_skipping and player.animation != char_data.shock_animation:
			player.play(char_data.shock_animation)
	)
	
	await spawn_tween.finished
	if is_skipping: return
	
	player.play(char_data.idle_animation)
	start_gem_idle_loop(target_y)

func start_gem_idle_loop(base_y: float) -> void:
	if float_tween:
		float_tween.kill()
		
	float_tween = create_tween().set_loops().set_parallel(true)
	float_tween.tween_property(gem, "position:y", base_y - 8.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(gem, "position:y", base_y, 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	float_tween.tween_property(gem, "self_modulate", Color(1.8, 1.5, 1.8, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(gem, "self_modulate", Color(1.3, 1.1, 1.3, 1.0), 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE)

func _on_player_reached_enemy(area: Area2D) -> void:
	if area == enemy_area and can_move and not reached_enemy:
		can_move = false
		reached_enemy = true
		player.play(char_data.idle_animation)
		
		# 🛠️ POSITIONAL SNAP FIX: Keeps the player strictly 145 pixels back to the left (stopped right at the foot)
		player.position = Vector2(enemy.position.x - 185.0, enemy.position.y)
		
		if skip:
			skip.hide()
		
		await conversation.play_sequence(dialogue_resource, "chapter1_star_fragment")
		if is_skipping: return
		
		finish_cutscene()

func finish_cutscene() -> void:
	if float_tween:
		float_tween.kill()
	
	if skip:
		skip.hide()
	
	var fly_tween = create_tween().set_parallel(true)
	fly_tween.tween_property(gem, "position", player.position + Vector2(0, -40), 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fly_tween.tween_property(gem, "self_modulate", Color(2.5, 2.0, 2.5, 1.0), 1.2)
	
	await fly_tween.finished
	if is_skipping: return
	
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	
	await get_tree().create_timer(3.0).timeout
	if is_skipping: return
	
	var fade = create_tween()
	fade.tween_property(gem, "modulate:a", 0.0, 0.5)
	await fade.finished
	if is_skipping: return
	
	cutscene_finished.emit()
