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
# Add this to your existing CardRegistry.gd

# Inside CardRegistry.gd

func generate_pack_paths(is_new_player: bool) -> Array[String]:
	var pack: Array[String] = []
	for i in range(5):
		pack.append(roll_for_single_card(is_new_player))
	return pack

func roll_for_single_card(is_new_player: bool) -> String:
	var roll = randf() * 100.0
	var target_rarity: GameEnums.CardRarity
	
	if is_new_player:
		target_rarity = GameEnums.CardRarity.Karaniwan if roll < 80.0 else GameEnums.CardRarity.Natatangi
	else:
		if roll < 1.0: target_rarity = GameEnums.CardRarity.Dambana
		elif roll < 6.0: target_rarity = GameEnums.CardRarity.Bihira
		elif roll < 25.0: target_rarity = GameEnums.CardRarity.Natatangi
		else: target_rarity = GameEnums.CardRarity.Karaniwan

	var pool = []
	for path in all_cards:
		if all_cards[path].rarity == target_rarity:
			pool.append(path)
	
	# DEBUG PRINT: This will tell us why the pool might be empty
	if pool.size() == 0:
		print("DEBUG: No cards found for rarity: ", GameEnums.CardRarity.keys()[target_rarity], ". Using fallback.")
		return all_cards.keys().pick_random() # Pick ANY card so it doesn't break
		
	return pool.pick_random()
	
