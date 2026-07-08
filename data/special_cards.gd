extends ItemData
class_name SpecialCardData

#What type of card na siya
@export var category: GameEnums.CardCategory
@export var rarity: GameEnums.CardRarity 

#For the art nii!
@export var effect_script: Script 
@export var damage: float = 0
@export var heal : float = 0
@export var mana_cost: int = 0
var card_source: GameEnums.CardSource =GameEnums.CardSource.INVENTORY
@export var cardASL: SpriteFrames
func apply_effect(user: Node, targets: Array):
	print("apply_effect called")
	if effect_script == null:
		print("NO EFFECT SCRIPT")
		return
	print("Script:", effect_script)
	var effect_instance = effect_script.new()
	print("Created:", effect_instance)
	print("Class:", effect_instance.get_class())
	print("Is SpecialEffect:", effect_instance is SpecialEffect)
	if effect_instance is SpecialEffect:
		print("Executing effect")
		effect_instance.execute(user, targets)
	else:
		print("FAILED TYPE CHECK")
