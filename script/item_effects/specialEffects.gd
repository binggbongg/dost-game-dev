extends RefCounted
class_name SpecialEffect

# This is the "Blueprint" function. Every effect script will override this.
func execute(user: Node, targets: Array):
	print("Executing base effect - override this!")
