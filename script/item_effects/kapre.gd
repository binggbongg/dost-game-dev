extends SpecialEffect

func execute(user: Node, targets: Array):
	print("KAPRE: Smoking cigar... Enemy is stunned and takes fire damage!")
	for target in targets:
		if target.has_method("take_damage"):
			target.take_damage(10)
		# Add stun logic here
