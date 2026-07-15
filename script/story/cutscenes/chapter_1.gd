extends CanvasLayer

signal cutscene_finished

@export var dialogue_resource: DialogueResource 

@onready var scene: Control = $Scene
@onready var skip: TextureButton = $Skip
@onready var player: AnimatedSprite2D = $Scene/Player 
@onready var enemy: Node2D = $Scene/Enemy          
@onready var gem: Sprite2D = $Gem
@onready var conversation: CanvasLayer = $Conversation

var char_data: CharacterData
var active_story_data: StoryData
var float_tween: Tween
var is_skipping: bool = false

func _ready() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/bgm/cutscene.wav", true)
	setup_player_visuals()
	
	if skip:
		skip.hide()
		skip.pressed.connect(_on_skip_pressed)

	if enemy:
		enemy.modulate = Color(0.35, 0.35, 0.35)
	
	gem.visible = false
	gem.modulate.a = 0.0

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

func _on_skip_pressed() -> void:
	if is_skipping: return
	is_skipping = true
	
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

	if player:
		player.play(char_data.idle_animation)
		
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	
	if gem:
		var skip_fade = create_tween()
		skip_fade.tween_property(gem, "modulate:a", 0.0, 0.4)
		await skip_fade.finished

	cutscene_finished.emit()

func start_world_cutscene(data: StoryData) -> void:
	active_story_data = data
	
	if active_story_data and conversation:
		conversation.gem_portrait = active_story_data.portrait

	if skip:
		skip.show()
	

	await conversation.play_sequence(dialogue_resource, "intro")
	if is_skipping: return
	
	await play_gem_spawn_anim()
	if is_skipping: return

	await conversation.play_sequence(dialogue_resource, "see_gem")
	if is_skipping: return
	
	player.play(char_data.walk_animation)
	var walk_tween = create_tween()
	var target_x = enemy.global_position.x - 380.0
	player.flip_h = player.global_position.x > target_x
	walk_tween.tween_property(player, "global_position:x", target_x, 3.5)
	await walk_tween.finished
	
	player.play(char_data.idle_animation)
	if is_skipping: return
	
	if skip:
		skip.hide()
	
	await conversation.play_sequence(dialogue_resource, "chapter1_star_fragment")
	if is_skipping: return
	
	finish_cutscene()

func play_gem_spawn_anim() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	gem.visible = true
	gem.self_modulate = Color(1.5, 1.3, 1.5, 1.0) 
	
	if enemy:
		gem.global_position = enemy.global_position - Vector2(220, 0)
	
	var spawn_tween = create_tween().set_parallel(true)
	var target_y = gem.global_position.y - 30.0
	
	spawn_tween.tween_property(gem, "global_position:y", target_y, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
	float_tween.tween_property(gem, "global_position:y", base_y - 6.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(gem, "global_position:y", base_y, 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	float_tween.tween_property(gem, "self_modulate", Color(1.8, 1.5, 1.8, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(gem, "self_modulate", Color(1.3, 1.1, 1.3, 1.0), 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE)

func finish_cutscene() -> void:
	if float_tween:
		float_tween.kill()
	
	if skip:
		skip.hide()
	
	var fly_tween = create_tween().set_parallel(true)
	fly_tween.tween_property(gem, "global_position", player.global_position + Vector2(0, -40), 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	fly_tween.tween_property(gem, "self_modulate", Color(2.5, 2.0, 2.5, 1.0), 1.2)
	
	await fly_tween.finished
	if is_skipping: return
	
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	
	await get_tree().create_timer(1.5).timeout
	if is_skipping: return
	
	var fade = create_tween()
	fade.tween_property(gem, "modulate:a", 0.0, 0.5)
	await fade.finished
	if is_skipping: return
	
	cutscene_finished.emit()
