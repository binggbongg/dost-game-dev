extends Node2D

@onready var health_bar = $HealthBar
@onready var mana_manager = $"../../PlayerInterface/GameManagers/ManaManager"
@onready var me: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	await get_tree().process_frame
		
	if PlayerProfile.selected_character != "None":
		var character_id = PlayerProfile.selected_character
		var path = "res://data/Characters/%s.tres" % character_id
		var character_data := load(path) as CharacterData
		if character_data:
			me.sprite_frames = character_data.sprite_frames
			me.play("idle")
		
	if health_bar and mana_manager:
		health_bar.initialize_bar(
			PlayerStats.max_health, 
			PlayerStats.current_health, 
			PlayerStats.health_changed,
			mana_manager.max_mana,
			mana_manager.current_mana,
			mana_manager.mana_changed)
	else:
		print("could not initialize health and bar ui --player.gd")

func start_attack_loop() -> void:
	if me and me.sprite_frames.has_animation("attack"):
		me.sprite_frames.set_animation_loop("attack", true)
		me.play("attack")

func stop_attack_loop() -> void:
	if me and me.animation == "attack":
		me.sprite_frames.set_animation_loop("attack", false)
		me.play("idle")

func play_death_animation() -> void:
	if me:
		# Safety fallback: turn off any lingering loop properties from the attack cycle
		me.sprite_frames.set_animation_loop("attack", false)
		
		if me.sprite_frames.has_animation("death"):
			# FORCE the death animation to NEVER loop
			me.sprite_frames.set_animation_loop("death", false)
			me.play("death")
			
			# Wait right here until it reaches the last frame
			await me.animation_finished
		else:
			print("Warning: No 'death' animation asset found! Faking visual freeze.")
			await get_tree().create_timer(1.0).timeout
