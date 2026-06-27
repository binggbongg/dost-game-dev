class_name EnemyMove
extends Resource

@export var name: String
@export var type: GameEnums.EnemyMoveType
@export var value: int = 0
@export_range(0.0, 1.0) var chances = 1.0
@export var cooldown: int = 0
