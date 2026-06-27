extends SpecialEffect
func execute(user: Node, _targets: Array):
	if user.has_method("heal"):
		var heal_amount = user.max_health * 0.5
		user.heal(heal_amount)
		print("DIWATA: Healed user for ", heal_amount)
