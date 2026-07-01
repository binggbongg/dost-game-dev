extends TaloLoadable

func _ready() -> void:
	register_field_details()
	await get_tree().process_frame
	sync_with_cloud()

func register_field_details():
	register_field("player_name", PlayerProfile.player_name)
	register_field("selected_character", PlayerProfile.selected_character)
	register_field("player_rank", PlayerProfile.player_rank)
	register_field("coins", PlayerProfile.coins)
	
	register_field("max_unlocked_chapters", PlayerProfile.max_unlocked_chapters)
	register_field("high_scores", PlayerProfile.high_scores)
	
	register_field("owned_items", PlayerInventory.owned_items)

func on_loaded(data: Dictionary):
	PlayerProfile.player_name = data.get("player_name", "NoobGamer")
	PlayerProfile.selected_character = data.get("selected_character", "None")
	PlayerProfile.player_rank = data.get("player_rank", "Starter")
	PlayerProfile.coins = data.get("coins", "100")
	
	PlayerProfile.max_unlocked_chapters = int(data.get("max_unlocked_chapters", 1))
	PlayerProfile.high_scores = data.get("high_scores", {})
	
	PlayerInventory.owned_items = data.get("owned_items", {})
	PlayerInventory.inventory_changed.emit()
	
	print("SaveManager (Talo): Cloud sync applied")
	print("- Coins Loaded: ", PlayerProfile.coins)
	print("- Max Chapter Unlocked: ", PlayerProfile.max_unlocked_chapters)
	print("- High Scores: ", PlayerProfile.high_scores)
	print("- Inventory: ", PlayerInventory.owned_items)

func sync_with_cloud() -> void:
	print("SaveManager (Talo): Contacting cloud service...")
	Talo.saves.get_saves()
	await Talo.saves.saves_loaded
	
	if Talo.saves.latest != null:
		print("SaveManager (Talo): Found existing cloud progress. Loading newest profile...")
		Talo.saves.choose_save(Talo.saves.latest)
	else:
		print("SaveManager (Talo): No active save found. Creating initial workspace profile.")
		Talo.saves.create_save("PlayerProfileSave")

func save_game():
	print("Preparing to push data to cloud profile")
	Talo.saves.update_current_save()

func delete_save():
	if Talo.saves.current != null:
		Talo.saves.delete_save(Talo.saves.current)
		print("SaveManager (Talo): Current save slot deleted")
