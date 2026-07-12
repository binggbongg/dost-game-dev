extends Resource
class_name LevelData

@export_range(1,3) var level_number: int = 1 
@export_range(1,3) var phase_number: int = 1

@export_file("*.png") var background: String
@export var enemy_data: EnemyBehavior

@export var is_boss_level: bool = false
@export var post_boss_cutscene: PackedScene
