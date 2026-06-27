extends SpecialEffect
func execute(_user: Node, targets: Array):
	for target in targets:
		if target.has_method("apply_status"):
			target.apply_status("smoke_screen", 0.5, 2) # 0.5 multiplier, 2 turns
	print("KAPRE: Enemy accuracy/damage reduced by smoke!")
