extends Node

var all_cards: Dictionary = {}

var categories = {
	"kalikasan": [],
	"tanglaw": [],
	"lahi": [],
	"diwa": []
}

func _ready():
	index_folder("res://data/Kalikasan/", "kalikasan")
	index_folder("res://data/Tanglaw/", "tanglaw")
	index_folder("res://data/Lahi/", "lahi")
	index_folder("res://data/Diwa/", "diwa")
	
	print("Database Ready: ", all_cards.size(), " cards indexed.")

func index_folder(path: String, category_name: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Only look for resource files (.tres or .res)
			if !dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				var full_path = path + file_name
				var card_res = load(full_path)
				
				if card_res is CardData: 
					all_cards[full_path] = card_res
					categories[category_name].append(full_path)
			
			file_name = dir.get_next()
	else:
		print("Warning: Could not open path: ", path)

func get_random_card_path() -> String:
	var keys = all_cards.keys()
	return keys[randi() % keys.size()]

func get_random_card_path_from(category: String) -> String:
	if categories.has(category) and categories[category].size() > 0:
		var list = categories[category]
		return list[randi() % list.size()]
	return ""
