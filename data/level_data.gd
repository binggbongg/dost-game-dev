extends Resource
class_name LevelData
@export_group("Level Details")
@export_range(1,3) var level_number: int = 1 
@export_range(1,3) var phase_number: int = 1
@export_file("*.png") var background: String
@export var enemy_data: EnemyBehavior

@export var is_boss_level: bool = false
<<<<<<< HEAD
@export var post_boss_cutscene: PackedScene
=======
@export_file("*.tscn") var post_boss_cutscene: String

@export_group("Lore")
@export var enemy_name: String
@export var level_lore: String
>>>>>>> origin/gela-friday-updates
