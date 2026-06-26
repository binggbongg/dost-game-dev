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

func apply_effect(user: Node, targets: Array):
	if effect_script:
		var effect_instance = effect_script.new() 
		if effect_instance is SpecialEffect:
			effect_instance.execute(user, targets)
			 #integrated daan for scalability incase ipush through katong multiple ennemies for future levels
