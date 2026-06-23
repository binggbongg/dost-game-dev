extends Node

@onready var player_hand = $"../PlayerHand"
func get_cards_in_slots() -> Array:
	var all_nodes = get_tree().get_nodes_in_group("cards")
	var valid_cards = []
	
	for node in all_nodes:
		# SAFETY CHECK: 
		# 1. Does the node have the variable 'location'?
		# 2. Is that location set to SLOT?
		if "location" in node and node.location == GameEnums.Location.SLOT:
			valid_cards.append(node)
			
	return valid_cards
# --- PART 1: PLACEMENT RULES (Can I drop this card?) ---

func validate_addition(new_card: Card) -> GameEnums.ComboValidationResult:
	# SAFETY CHECK: If for some reason player_hand is missing, don't crash
	if player_hand == null:
		print("Error: ComboManager cannot find PlayerHand node!")
		return GameEnums.ComboValidationResult.VALID

	var active_cards = get_cards_in_slots()
	var categories = active_cards.map(func(c): return c.card_category)
	
	# RULE 4: TANGLAW (Max 2, Never with Lahi)
	if new_card.card_category == GameEnums.CardCategory.TANGLAW:
		if categories.count(GameEnums.CardCategory.TANGLAW) >= 2:
			return GameEnums.ComboValidationResult.INVALID_TRI_TANGLAW
		if GameEnums.CardCategory.LAHI in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_TANGLAW_MIX

	# RULE 3: DIWA (Max 1)
	if new_card.card_category == GameEnums.CardCategory.DIWA:
		if GameEnums.CardCategory.DIWA in categories:
			return GameEnums.ComboValidationResult.INVALID_DUPLICATE_DIWA
		if GameEnums.CardCategory.TANGLAW in categories:
			pass # Diwa + Tanglaw is allowed for damage pairing

	# RULE 1 & 2: LAHI + DIWA + KALIKASAN interaction
	if new_card.card_category == GameEnums.CardCategory.LAHI:
		if GameEnums.CardCategory.TANGLAW in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_TANGLAW_MIX
		
		# Multi-Lahi check: Allowed only if a Diwa is already present
		if GameEnums.CardCategory.LAHI in categories and not GameEnums.CardCategory.DIWA in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_NEEDS_DIWA

	if new_card.card_category == GameEnums.CardCategory.KALIKASAN:
		# If trying to add Kalikasan to a Lahi combo:
		if GameEnums.CardCategory.LAHI in categories:
			# Check if Diwa is in Slot OR in Hand
			var diwa_in_hand = player_hand.player_cards.any(func(c): return c.card_category == GameEnums.CardCategory.DIWA)
			var diwa_in_slot = GameEnums.CardCategory.DIWA in categories
			if not (diwa_in_hand or diwa_in_slot):
				return GameEnums.ComboValidationResult.INVALID_LAHI_NEEDS_DIWA
	
	if new_card.card_category == GameEnums.CardCategory.KALIKASAN:
		if GameEnums.CardCategory.LAHI in categories:
			var diwa_in_hand = player_hand.player_cards.any(func(c): return c.card_category == GameEnums.CardCategory.DIWA)
			var diwa_in_slot = GameEnums.CardCategory.DIWA in categories
			if not (diwa_in_hand or diwa_in_slot):
				return GameEnums.ComboValidationResult.INVALID_LAHI_NEEDS_DIWA
	return GameEnums.ComboValidationResult.VALID

# --- PART 2: CAST RULES (Is the combo complete for the Attack Button?) ---
func validate_cast() -> bool:
	var active = get_cards_in_slots()
	if active.is_empty(): return false
	
	var categories = active.map(func(c): return c.card_category)
	
	# LAHI COMPLEX RULE
	if GameEnums.CardCategory.LAHI in categories:
		# If Lahi is present, it MUST have BOTH Diwa and Kalikasan to be a valid combo
		# unless it's a Solo Lahi (one card only)
		if active.size() > 1:
			var has_diwa = GameEnums.CardCategory.DIWA in categories
			var has_kali = GameEnums.CardCategory.KALIKASAN in categories
			if not (has_diwa and has_kali):
				return false # Button stays disabled
	
	return true
