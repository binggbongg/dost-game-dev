extends Node

var items = {} 

func _ready():
	load_items_from_directory("res://data/Items/")
	load_items_from_directory("res://data/Special/")

func get_item(id: String) -> ItemData:
	return items.get(id)

func get_all_items() -> Array:
	return items.values()

#func load_items_from_directory(path: String):
	#var dir = DirAccess.open(path)
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
				#var clean_path = path + file_name.replace(".remap", "")
				#var item = load(clean_path)
				#if item is ItemData:
					#items[item.item_id] = item
			#file_name = dir.get_next()

func load_items_from_directory(path: String):
	var files = ResourceLoader.list_directory(path)
	for file_name in files:
		if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var clean_path = path.path_join(file_name.replace(".remap", ""))
			var item = load(clean_path)
			if item is ItemData:
				items[item.item_id] = item
