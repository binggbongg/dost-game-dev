extends ItemData
class_name SpecialCardData

# Drag and drop your .gd effect script here in the Inspector
@export var effect_script: Script 

@export var damage: int = 0
@export var mana_cost: int = 0

# This helper function creates the effect and runs it
func apply_effect(user: Node, targets: Array):
	if effect_script:
		var effect_instance = effect_script.new() # Create the script in memory
		if effect_instance is SpecialEffect:
			effect_instance.execute(user, targets)
