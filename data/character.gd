extends Resource
class_name CharacterData

@export_group("Information")
@export var id: String
@export var display_name: String

@export_group("Visuals")
@export var sprite_frames: SpriteFrames
@export var portrait: Texture2D
@export var icon: Texture2D
@export var splash_art: Texture2D

@export_group("Animations")
@export var idle_animation := "idle"
@export var walk_animation := "walk"
@export var run_animation := "run"
@export var attack_animation := "attack"
@export var cast_animation := "cast"
@export var shock_animation := "shock"
@export var death_animation := "death"

@export_group("Effects")
@export var cast_effect: PackedScene
@export var attack_effect: PackedScene
