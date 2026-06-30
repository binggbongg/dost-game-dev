extends Resource
class_name ComboRecipe

@export var name: String = "New Combo"
@export var description: String = ""
@export var is_forbidden: bool = false

@export var elements: Array[GameEnums.CardCategory] = []
