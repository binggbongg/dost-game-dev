extends Node

var items = {} 

func _ready():
	load_items_from_directory("res://data/Items/")
	load_items_from_directory("res://data/Special/")

func get_item(id: String) -> ItemData:
	return items.get(id)

func get_all_items() -> Array:
	return items.values()

func load_items_from_directory(path: String):
	var files = ResourceLoader.list_directory(path)
	print("[ItemDb] ", path, " -> ", files)   # TEMP
	for file_name in files:
		if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
			var clean_path = path.path_join(file_name.replace(".remap", ""))
			var item = load(clean_path)
			if item is ItemData:
				items[item.item_id] = item
	print("[ItemDb] total items loaded: ", items.size())  
