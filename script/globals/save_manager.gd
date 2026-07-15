extends TaloLoadable

func _ready() -> void:
	id = "global_save_manager"
	super()
	
	await get_tree().process_frame
	sync_with_cloud()

func register_fields():
	register_field("player_name", PlayerProfile.player_name)
	register_field("selected_character", PlayerProfile.selected_character)
	register_field("player_rank", PlayerProfile.player_rank)
	register_field("coins", PlayerProfile.coins)
	
	register_field("is_profile_initialized", PlayerProfile.is_profile_initialized)
	
	register_field("max_unlocked_chapters", PlayerProfile.max_unlocked_chapters)
	register_field("high_scores", PlayerProfile.high_scores)
	
	register_field("owned_items", PlayerInventory.owned_items)
	#hi aissha
	# what the
	register_field("tutorials", PlayerProfile.tutorial_steps_completed)
	register_field("owned_cards", PlayerProfile.owned_cards)
	register_field("owned_fragments", PlayerProfile.owned_fragments)

func on_loaded(data: Dictionary):
	PlayerProfile.player_name = data.get("player_name", "NoobGamer")
	PlayerProfile.selected_character = data.get("selected_character", "None")
	PlayerProfile.player_rank = data.get("player_rank", "Starter")
	PlayerProfile.coins = int(data.get("coins", 100))
	
	PlayerProfile.is_profile_initialized = data.get("is_profile_initialized", false)
	PlayerProfile.max_unlocked_chapters = int(data.get("max_unlocked_chapters", 1))
	
	var incoming_scores = data.get("high_scores", {})
	PlayerProfile.high_scores = incoming_scores if typeof(incoming_scores) == TYPE_DICTIONARY else {}
	
	var incoming_inventory = data.get("owned_items", {})
	PlayerInventory.owned_items = incoming_inventory if typeof(incoming_inventory) == TYPE_DICTIONARY else {}
	PlayerInventory.inventory_changed.emit()

	var loaded_fragments = data.get("owned_fragments", [])
	if typeof(loaded_fragments) == TYPE_ARRAY:
		PlayerProfile.owned_fragments.assign(loaded_fragments)
	else:
		PlayerProfile.owned_fragments.clear()
	
	var incoming_cards = data.get("owned_cards", [])
	if typeof(incoming_cards) == TYPE_ARRAY:
		PlayerProfile.owned_cards.assign(incoming_cards)
	else:
		PlayerProfile.owned_cards.clear()
	
	var default_tutorials = {
		"lounge_tour": false,
		"chapter_intro": false,
		"battle_tutorial": false,
		"deck_builder": false,
		"cut_scene": false
	}
	
	var loaded_tutorials = data.get("tutorials", default_tutorials)
	PlayerProfile.tutorial_steps_completed = loaded_tutorials if typeof(loaded_tutorials) == TYPE_DICTIONARY else default_tutorials
	
	print("SaveManager (Talo): Cloud sync applied")
	print("- Coins Loaded: ", PlayerProfile.coins)
	print("- Max Chapter Unlocked: ", PlayerProfile.max_unlocked_chapters)
	print("- High Scores: ", PlayerProfile.high_scores)
	print("- Inventory: ", PlayerInventory.owned_items)

func sync_with_cloud() -> void:
	if typeof(Talo) == TYPE_NIL or Talo.identity_check(false) != OK:
		print("SaveManager (Talo): Player is not authenticated yet. Deferring sync.")
		return

	print("SaveManager (Talo): Contacting cloud service...")
	Talo.saves.get_saves()
	await Talo.saves.saves_loaded
	
	if Talo.saves.latest != null:
		print("SaveManager (Talo): Found existing cloud progress. Loading newest profile...")
		Talo.saves.choose_save(Talo.saves.latest)
	else:
		print("SaveManager (Talo): Fresh account with no saves detected. Provisioning workspace...")
		
		if Talo.saves.current == null:
			var baseline_save_data = {
				id = 0,
				name = "PlayerProfileSave",
				content = {
					"version": "godot.v2",
					"objects": []
				},
				updatedAt = Time.get_datetime_string_from_system()
			}
			Talo.saves.current = TaloGameSave.new(baseline_save_data)
		
		# Build initial fields immediately so placeholder data is serialized cleanly
		register_fields()
		await Talo.saves.create_save("PlayerProfileSave")
		print("SaveManager (Talo): Placeholder workspace baked successfully.")

func save_game():
	if Talo.saves.current == null:
		print("SaveManager Warning: Blocked a save attempt because Talo.saves.current is null (Not fully synced yet).")
		return
	
	register_fields()
	print("Preparing to push data to cloud profile -- savemanager")
	Talo.saves.update_current_save()

func save_game_async() -> void:
	if Talo.saves.current == null:
		print("SaveManager (Async): Building initial save slot...")
		await Talo.saves.create_save("PlayerProfileSave")
		print("Initial save slot created")
		return
	
	register_fields()
	print("Preparing to push data to cloud profile (Async)")
	await Talo.saves.update_current_save()

func delete_save():
	if Talo.saves.current != null:
		Talo.saves.delete_save(Talo.saves.current)
		print("SaveManager (Talo): Current save slot deleted")
