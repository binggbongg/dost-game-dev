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

func play_attack_animation() -> void:
	if me and me.sprite_frames.has_animation("attack"):
		me.play("attack")
		# Disconnect old listeners to avoid multiple connections stacking up
		if me.animation_finished.is_connected(_on_attack_finished):
			me.animation_finished.disconnect(_on_attack_finished)
		me.animation_finished.connect(_on_attack_finished)

func _on_attack_finished() -> void:
	if me.animation == "attack":
		me.play("idle")
		me.animation_finished.disconnect(_on_attack_finished)
