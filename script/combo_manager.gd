extends Node

@onready var mana_manager = get_node("../ManaManager")
@onready var player_hand = $"../PlayerHand"

func get_cards_in_slots(exclude_card: Card = null) -> Array:
	var all_nodes = get_tree().get_nodes_in_group("cards")
	var valid_cards = []

	for node in all_nodes:
		if node.is_queued_for_deletion() or node == exclude_card:
			continue

		if "location" in node and node.location == GameEnums.Location.SLOT:
			valid_cards.append(node)

	return valid_cards


func get_total_reserved_mana(exclude_card: Card = null) -> int:
	var total = 0

	for card in get_cards_in_slots(exclude_card):
		total += card.card_cost

	return total


func has_affordable_diwa_in_hand(available_mana: int) -> bool:
	for card in player_hand.player_cards:
		if card.card_category == GameEnums.CardCategory.DIWA:
			if card.card_cost <= available_mana:
				return true

	return false


# --- PART 1: PLACEMENT RULES (Visual graying out and Drag restrictions) ---

func validate_addition(new_card: Card) -> GameEnums.ComboValidationResult:
	var active_cards = get_cards_in_slots(new_card)
	var categories = active_cards.map(func(c): return c.card_category)

	# Rule Checking - Maximum Combo Size
	if active_cards.size() >= 3:
		return GameEnums.ComboValidationResult.INVALID_MAX_CARDS

	# Rule Checking - Mana Reservation
	var available_mana = mana_manager.current_mana - get_total_reserved_mana(new_card)

	if new_card.card_cost > available_mana:
		return GameEnums.ComboValidationResult.INVALID_NOT_ENOUGH_MANA

	# Rule Checking - Special Cards: Solo only.
	# Rule Checking - Special Cards: Solo only.
	if new_card.card_data is SpecialCardData:
		if active_cards.size() > 0:
			return GameEnums.ComboValidationResult.INVALID_MISSING_PIECE

	for card in active_cards:
		if card.card_data is SpecialCardData:
			return GameEnums.ComboValidationResult.INVALID_MISSING_PIECE
	# HARD RULES

	# Rule Checking - Duplicate Diwa
	if new_card.card_category == GameEnums.CardCategory.DIWA:
		if GameEnums.CardCategory.DIWA in categories:
			return GameEnums.ComboValidationResult.INVALID_DUPLICATE_DIWA

	# Rule Checking - Tanglaw Cards
	if new_card.card_category == GameEnums.CardCategory.TANGLAW:

		if categories.count(GameEnums.CardCategory.TANGLAW) >= 2:
			return GameEnums.ComboValidationResult.INVALID_TRI_TANGLAW

		if GameEnums.CardCategory.LAHI in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_TANGLAW_MIX

	# --- THE LAHI COMBO BRIDGE (The "Trio" Enforcement) ---

	var has_lahi_slot = GameEnums.CardCategory.LAHI in categories
	var has_kali_slot = GameEnums.CardCategory.KALIKASAN in categories
	var has_diwa_slot = GameEnums.CardCategory.DIWA in categories

	# Check for an affordable Diwa in hand
	var diwa_available = has_diwa_slot or has_affordable_diwa_in_hand(available_mana)

	# Rule Checking - Kalikasan Cards
	if new_card.card_category == GameEnums.CardCategory.KALIKASAN:

		if has_lahi_slot:

			# Prevent:
			# Lahi + Kalikasan + Kalikasan
			if has_kali_slot and not has_diwa_slot:
				return GameEnums.ComboValidationResult.INVALID_MISSING_PIECE

			# Lahi + Kalikasan requires Diwa
			if not diwa_available:
				return GameEnums.ComboValidationResult.INVALID_LAHI_NEEDS_DIWA

	# Rule Checking - Lahi Cards
	if new_card.card_category == GameEnums.CardCategory.LAHI:

		if GameEnums.CardCategory.TANGLAW in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_TANGLAW_MIX

		# Prevent:
		# Lahi + Diwa + Lahi + Lahi
		if categories.count(GameEnums.CardCategory.LAHI) >= 2:
			return GameEnums.ComboValidationResult.INVALID_MISSING_PIECE

		# Lahi + Lahi requires Diwa
		if has_lahi_slot and not diwa_available:
			return GameEnums.ComboValidationResult.INVALID_LAHI_NEEDS_DIWA

	return GameEnums.ComboValidationResult.VALID


# --- PART 2: CAST RULES (Controls the Cast Sprite's highlight) ---
func validate_cast() -> bool:
	var active = get_cards_in_slots()

	if active.is_empty() or active.size() > 3:
		return false

	if active.size() == 1 and active[0].card_data.get("is_special"):
		return true

	var categories = active.map(func(c): return c.card_category)
	var lahi_count = categories.count(GameEnums.CardCategory.LAHI)
	var diwa_count = categories.count(GameEnums.CardCategory.DIWA)
	var kali_count = categories.count(GameEnums.CardCategory.KALIKASAN)
	var tanglaw_count = categories.count(GameEnums.CardCategory.TANGLAW)

	if active.size() == 1:
		return true

	if active.size() == 2:
		if kali_count == 2: return true                    # KALIKASAN + KALIKASAN
		if diwa_count == 1 and kali_count == 1: return true # DIWA + KALIKASAN / KALIKASAN + DIWA
		if diwa_count == 1 and tanglaw_count == 1: return true # DIWA + TANGLAW / TANGLAW + DIWA
		return false # Disallow any other random 2-card combinations

	if active.size() == 3:
		if lahi_count > 0:
			if lahi_count == 1 and diwa_count == 1 and kali_count == 1: return true # LAHI + DIWA + KALIKASAN
			if lahi_count == 2 and diwa_count == 1: return true                    # LAHI + DIWA + LAHI
			return false

		if kali_count == 3: return true # KALIKASAN + KALIKASAN + KALIKASAN
		
		if diwa_count == 1:
			if kali_count == 2: return true # KALIKASAN + DIWA + KALIKASAN / DIWA + KALIKASAN + KALIKASAN
			if kali_count == 1 and tanglaw_count == 1: return true # KALIKASAN + DIWA + TANGLAW / TANGLAW + KALIKASAN + DIWA / DIWA + TANGLAW + KALIKASAN
			if tanglaw_count == 2: return true # DIWA + TANGLAW + TANGLAW / TANGLAW + DIWA + TANGLAW
			
		if tanglaw_count > 0:
			if kali_count == 1 and tanglaw_count == 2: return true # KALIKASAN + TANGLAW + TANGLAW
			if kali_count == 2 and tanglaw_count == 1: return true # KALIKASAN + TANGLAW + KALIKASAN

	return false 

func get_matched_recipe() -> ComboRecipe:
	var active = get_cards_in_slots()
	if not validate_cast() or active.size() < 2:
		return null
		
	# Extract the active card categories currently sitting in your grid slots
	var current_elements = active.map(func(c): return c.card_category)
	current_elements.sort() 

	var recipe_paths: Array[String] = [
		"res://data/ComboRecipe/baluti_ng_luntian.tres",
		"res://data/ComboRecipe/bana_na_panata.tres",
		"res://data/ComboRecipe/bantay_ng_langit.tres",
		"res://data/ComboRecipe/basbas_ng_liwanag.tres",
		"res://data/ComboRecipe/galit_ng_gubat.tres",
		"res://data/ComboRecipe/hukbo_ng_alamat.tres",
		"res://data/ComboRecipe/katarungan_ng_tala.tres",
		"res://data/ComboRecipe/lukob_ng_bituin.tres",
		"res://data/ComboRecipe/pagngitngit_ng_kalikasan.tres",
		"res://data/ComboRecipe/Pintig_ng_Sanlibutan.tres",
		"res://data/ComboRecipe/yakap_ng_daigdig.tres"
	]

	for path in recipe_paths:
		if not ResourceLoader.exists(path): continue
		var recipe = load(path) as ComboRecipe
		if recipe:
			var recipe_elements = recipe.elements.duplicate()
			recipe_elements.sort()
			
			# If the card patterns match up perfectly, return this exact recipe resource!
			if current_elements == recipe_elements:
				return recipe

	return null

func calculate_combo_output(active_cards: Array) -> Dictionary:
	var base_damage: float = 0.0
	var base_healing: float = 0.0
	var global_multiplier: float = 1
	
	for card in active_cards:
		if not is_instance_valid(card) or not card.card_data:
			continue
		
		var data = card.card_data as CardData
		
		match card.card_category:
			GameEnums.CardCategory.KALIKASAN:
				base_damage += data.damage
			GameEnums.CardCategory.TANGLAW:
				base_healing += data.heal
			GameEnums.CardCategory.DIWA:
				base_damage += data.damage
				base_healing += data.heal
				if data.multiplier > 0:
					global_multiplier += (data.multiplier - 1.0)
			GameEnums.CardCategory.LAHI:
				global_multiplier += combo_for_lahi(active_cards)
				base_damage += data.damage
				base_healing += data.heal
	
	var final_damage = base_damage * global_multiplier
	var final_healing = base_healing * global_multiplier

	return {
		"damage": int(round(final_damage)),
		"healing": int(round(final_healing))
	}

func combo_for_lahi(active_cards) -> int:
	var categories = active_cards.map(func(c): return c.card_category)
	var lahi_count = categories.count(GameEnums.CardCategory.LAHI)
	#var kalikasan_count = categories.count(GameEnums.CardCategory.KALIKASAN)
	#var diwa_count = categories.count(GameEnums.CardCategory.DIWA)
	#var tanglaw_count = categories.count(GameEnums.CardCategory.TANGLAW)
	
	# special condition for the specific lahi combos
	# lahi combos:
	# lahi diwa lahi
	# lahi diwa kalikasan
	# lahi diwa tanglaw
	
	if lahi_count == 0: return 1
	
	var matched_recipes = get_matched_recipe()
	if matched_recipes:
		var file_name = matched_recipes.resource_path.get_file().to_lower()
		if "hukbo_ng_alamat" in file_name:
			print("Hukbo ng Alamat combo matched! Multiplier/Bonus: 3")
			return 3
		elif lahi_count == 1:
			print("Standard recipe with Lahi matched. Multiplier/Bonus: 2")
			return 2
	
	return 1
