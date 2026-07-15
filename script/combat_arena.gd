extends Node2D

@onready var player = $Player

func get_enemy():
	if get_child_count() > 0:
		var enemy_node = get_child(0)
		if is_instance_valid(enemy_node):
			return enemy_node
	
	print("no enemy node found")
	return null

func get_player():
	return player

func initialize_arena_enemy(enemy_resource: EnemyBehavior):
	var enemy_node = get_enemy()
	if not enemy_node:
		print("combat arena does not enemy node --combat arena")
		return
	
	if enemy_node.has_method("initialize_from_resource"):
		enemy_node.initialize_from_resource(enemy_resource)
	else:
		enemy_node.behavior_data = enemy_resource
		if enemy_node.has_method("setup_enemy"):
			enemy_node.setup_enemy()

func play_player_magic():
	player.play_magic()
