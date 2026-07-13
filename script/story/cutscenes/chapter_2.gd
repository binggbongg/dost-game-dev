extends CanvasLayer

signal cutscene_finished

@export var dialogue_resource: DialogueResource 

@onready var background: Sprite2D = $Background
@onready var scene: Control = $Scene
@onready var enemy: AnimatedSprite2D = $Scene/Enemy
@onready var player: AnimatedSprite2D = $Scene/Player 
@onready var magic_sprite: AnimatedSprite2D = $Scene/Player/MagicSprite
@onready var gem: Sprite2D = $Gem
@onready var conversation: CanvasLayer = $Conversation
@onready var skip: TextureButton = $Skip
@onready var ufo: AnimatedSprite2D = $Ufo

var char_data: CharacterData
var active_story_data: StoryData
var float_tween: Tween
var is_skipping: bool = false
var light_tween: Tween

func _ready() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/bgm/cutscene.wav", true)
	setup_player_visuals()
	
	gem.visible = false
	gem.modulate.a = 0.0
	ufo.visible = false
	ufo.modulate.a = 0.0
	magic_sprite.visible = false
	
	if enemy:
		enemy.modulate = Color(0.35, 0.35, 0.35)
		enemy.play("idle")
	
	if skip:
		skip.hide()
		skip.pressed.connect(_on_skip_pressed)

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
	
	if skip: skip.hide()
	if float_tween: float_tween.kill()
	if light_tween: light_tween.kill()
	
	if conversation:
		conversation.is_active = false
		if conversation.typewriter_tween:
			conversation.typewriter_tween.kill()
		if conversation.dialogue_box:
			conversation.dialogue_box.hide()
		conversation.line_finished.emit()
		
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	
	var skip_fade = create_tween().set_parallel(true)
	if gem: skip_fade.tween_property(gem, "modulate:a", 0.0, 0.3)
	if ufo: skip_fade.tween_property(ufo, "modulate:a", 0.0, 0.3)
	if player: skip_fade.tween_property(player, "modulate:a", 0.0, 0.3)
	await skip_fade.finished

	cutscene_finished.emit()

func start_world_cutscene(data: StoryData) -> void:
	active_story_data = data
	
	if active_story_data and conversation:
		conversation.gem_portrait = active_story_data.portrait
		
	run_cutscene_timeline()

func run_cutscene_timeline() -> void:
	player.play(char_data.attack_animation)
	
	await get_tree().create_timer(0.2).timeout
	if is_skipping: return
	
	magic_sprite.visible = true
	magic_sprite.play("default") 
	await magic_sprite.animation_finished
	magic_sprite.visible = false
	if is_skipping: return
	
	if player.is_playing() and player.animation == char_data.attack_animation:
		await player.animation_finished
	player.play(char_data.idle_animation)
	if is_skipping: return
	
	if enemy:
		enemy.play("dead")
	
	await conversation.play_sequence(dialogue_resource, "intro")
	if is_skipping: return

	if enemy and enemy.is_playing() and enemy.animation == "dead":
		await enemy.animation_finished
	if is_skipping: return
	
	if skip: skip.show() 
	await play_gem_spawn_anim()
	if is_skipping: return
	
	await conversation.play_sequence(dialogue_resource, "see_gem")
	if is_skipping: return
	
	player.play(char_data.walk_animation)
	var walk_tween = create_tween()
	var target_x = gem.global_position.x - 120.0
	player.flip_h = player.global_position.x > target_x
	walk_tween.tween_property(player, "global_position:x", target_x, 2.2)
	await walk_tween.finished
	player.play(char_data.idle_animation)
	if is_skipping: return
	
	await conversation.play_sequence(dialogue_resource, "chapter2_star_fragment")
	if is_skipping: return
	
	if float_tween: float_tween.kill()
	var absorb_tween = create_tween().set_parallel(true)
	absorb_tween.tween_property(gem, "global_position", player.global_position + Vector2(0, -40), 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	absorb_tween.tween_property(gem, "self_modulate", Color(2.5, 2.0, 2.5, 1.0), 0.8)
	absorb_tween.tween_property(gem, "scale", Vector2.ZERO, 0.8)
	absorb_tween.tween_property(gem, "modulate:a", 0.0, 0.8)
	await absorb_tween.finished
	if is_skipping: return
	
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	
	if conversation.has_method("play_sequence"):
		conversation.is_active = true
		conversation.dialogue_box.show()
		
		var dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, "chapter2_abduction")
		while dialogue_line != null and conversation.is_active:
			if is_skipping: break
			
			if dialogue_line.text.contains("What is that light?") or dialogue_line.text.contains("Run!"):
				if not light_tween:
					light_tween = create_tween().set_loops()
					light_tween.tween_property(player, "modulate", Color(1.8, 2.2, 2.5, 1.0), 0.4).set_trans(Tween.TRANS_SINE)
					light_tween.tween_property(player, "modulate", Color(1.3, 1.6, 1.8, 1.0), 0.4).set_trans(Tween.TRANS_SINE)
			
			conversation.display_line(dialogue_line.character, dialogue_line.text)
			await conversation.line_finished
			
			if not conversation.is_active or is_skipping: break
			dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, dialogue_line.next_id)
			
		conversation.dialogue_box.hide()
		conversation.is_active = false
		conversation.conversation_finished.emit()

	if is_skipping: return
	if skip: skip.hide() 
	if light_tween: light_tween.kill()
	
	ufo.visible = true
	ufo.modulate.a = 0.0
	ufo.global_position = Vector2(player.global_position.x, player.global_position.y - 450)
	ufo.play("default") 
	
	var ufo_tween = create_tween().set_parallel(true)
	ufo_tween.tween_property(ufo, "modulate:a", 1.0, 0.5)
	ufo_tween.tween_property(ufo, "global_position:y", player.global_position.y - 180, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await ufo_tween.finished
	if is_skipping: return
	
	player.play(char_data.shock_animation)
	var abduct_tween = create_tween().set_parallel(true)
	abduct_tween.tween_property(player, "modulate", Color(5.0, 5.0, 5.0, 1.0), 0.3)
	abduct_tween.chain().tween_property(player, "global_position:y", ufo.global_position.y + 20, 1.2).set_trans(Tween.TRANS_LINEAR)
	abduct_tween.parallel().tween_property(player, "scale", Vector2.ZERO, 1.2)
	abduct_tween.parallel().tween_property(player, "modulate:a", 0.0, 1.2)
	await abduct_tween.finished
	player.visible = false
	if is_skipping: return
	
	var blackout_tween = create_tween().set_parallel(true)
	if background: blackout_tween.tween_property(background, "modulate", Color.BLACK, 0.8)
	if ufo: blackout_tween.tween_property(ufo, "modulate", Color.BLACK, 0.8)
	await blackout_tween.finished
	if is_skipping: return
	
	await conversation.play_sequence(dialogue_resource, "unknown_transmission")
	
	cutscene_finished.emit()

func play_gem_spawn_anim() -> void:
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/flutter.mp3", false, 5.0)
	gem.visible = true
	gem.self_modulate = Color(1.5, 1.3, 1.5, 1.0) 
	
	if enemy:
		gem.position = enemy.position
		
	var spawn_tween = create_tween().set_parallel(true)
	var target_y = gem.position.y - 80.0
	
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
	if float_tween: float_tween.kill()
		
	float_tween = create_tween().set_loops().set_parallel(true)
	float_tween.tween_property(gem, "position:y", base_y - 8.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	float_tween.tween_property(gem, "position:y", base_y, 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	float_tween.tween_property(gem, "self_modulate", Color(1.8, 1.5, 1.8, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(gem, "self_modulate", Color(1.3, 1.1, 1.3, 1.0), 0.9).set_delay(0.9).set_trans(Tween.TRANS_SINE)
