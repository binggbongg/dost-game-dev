extends SpecialEffect
func execute(user: Node, targets: Array):
	var damage = 20 # Example base damage
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(damage)
			if user.has_method("heal"):
				user.heal(damage) # Lifesteal logic
	print("ASWANG: Life force drained!")
