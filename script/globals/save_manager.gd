extends Node

const SAVE_PATH = "user://savegame.json"
func _ready():
	await get_tree().process_frame
	load_game()
#para ni ang data kay mo persist the next time the player comes back, we can add this sa exit buttons, saves, etc.
func save_game():
	var save_data = {
		"profile": {
			"player_name": PlayerProfile.player_name,
			"selected_character": PlayerProfile.selected_character,
			"player_rank": PlayerProfile.player_rank,
			"coins": PlayerProfile.coins,
		},
		"inventory": PlayerInventory.owned_items 
	}
	
	var json_string = JSON.stringify(save_data)
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file:
		file.store_line(json_string)
		print("SaveManager: Game Saved successfully to ", SAVE_PATH)
	else:
		print("SaveManager: Error opening file to save!")
#mao ni ang method tawgon inig start!
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("SaveManager: No save file found. Starting fresh.")
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var data = json.get_data()
		apply_save_data(data)
		print("SaveManager: Game Loaded successfully.")
		return true
	else:
		print("SaveManager: Error parsing JSON!")
		return false


#this method is called sa above function, this will set everything para ready na tanan (player profile & inventory)
func apply_save_data(data: Dictionary):
	if data.has("profile"):
		var p = data["profile"]
		# We use self. to be 100% sure the signals fire
		PlayerProfile.player_name = p.get("player_name", "Default")
		PlayerProfile.selected_character = p.get("selected_character", "None")
		PlayerProfile.player_rank = p.get("player_rank", "Starter")
		PlayerProfile.coins = int(p.get("coins", 0)) # Force Integer
		print("SaveManager: Loaded Coins: ", PlayerProfile.coins)
	
	if data.has("inventory"):
		PlayerInventory.owned_items = data["inventory"]
		PlayerInventory.inventory_changed.emit()
		print("SaveManager: Loaded Inventory: ", PlayerInventory.owned_items)

#back to uno, for those hard resets 
func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("SaveManager: Save file deleted.")
		
#testing delete latur
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		save_game()
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		load_game()
