extends Node2D

func get_enemy():
	if get_child_count() > 0:
		print("printing combat arena children")
		print(get_children())
		
		var enemy_node = get_child(0)
		if is_instance_valid(enemy_node):
			return enemy_node
	
	print("no enemy node found")
	return null
