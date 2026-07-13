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
	PlayerProfile.high_scores = data.get("high_scores", {})
	
	PlayerInventory.owned_items = data.get("owned_items", {})
	PlayerInventory.inventory_changed.emit()
	PlayerProfile.owned_cards = data.get("owned_cards", [])
	var loaded_fragments = data.get("owned_fragments", [])
	PlayerProfile.owned_fragments.assign(loaded_fragments)
	PlayerProfile.tutorial_steps_completed = data.get("tutorials", false)
	
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
		print("SaveManager (Talo): Critical initialization gate - Fresh account with no saves detected!")
		print("SaveManager (Talo): Provisioning immediate empty container placeholder to satisfy plugin references...")
		
		# 🛡️ SAFE GUARD: To prevent Talo's plugin from breaking on a 'Nil' check,
		# we initialize an empty, valid TaloGameSave instance into the current session slot.
		# This assigns an ID of 0 so Talo's background loop processes it safely.
		if Talo.saves.current == null:
			# 🛠️ FIX: Match exact keys and casing expected by TaloGameSave._init()
			var baseline_save_data = {
				id = 0,
				name = "PlayerProfileSave",
				content = {
					"version": "godot.v2",
					"objects": []
				},
				updatedAt = Time.get_datetime_string_from_system() # ✨ Fixed camelCase key!
			}
			# Safely instantiate the class with the corrected dictionary layout
			Talo.saves.current = TaloGameSave.new(baseline_save_data)
		
		# ⏳ Now that the slot is safely populated, tell the cloud server to store it permanently
		await Talo.saves.create_save("PlayerProfileSave")
		print("SaveManager (Talo): Placeholder workspace baked successfully.")

func save_game():
	if Talo.saves.current == null:
		print("SaveManager Warning: Blocked a save attempt because Talo.saves.current is null (Not fully synced yet).")
		return
	
	print("Preparing to push data to cloud profile -- savemanager")
	Talo.saves.update_current_save()

func save_game_async() -> void:
	if Talo.saves.current == null:
		print("SaveManager (Async): Building initial save slot...")
		await Talo.saves.create_save("PlayerProfileSave")
		print("Initial save slot created")
		return
	
	print("Preparing to push data to cloud profile (Async)")
	await Talo.saves.update_current_save()

func delete_save():
	if Talo.saves.current != null:
		Talo.saves.delete_save(Talo.saves.current)
		print("SaveManager (Talo): Current save slot deleted")
