extends RefCounted
class_name SpecialEffect

#just a safety error check nga need siya override.
func execute(user: Node, targets: Array):
		push_error("SpecialEffect.execute() must be overridden.")
