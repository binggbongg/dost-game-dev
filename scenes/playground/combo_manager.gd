extends Node

@onready var player_hand = $"../PlayerHand"
func get_cards_in_slots() -> Array:
	var all_nodes = get_tree().get_nodes_in_group("cards")
	var valid_cards = []
	for node in all_nodes:
		# If the card is being deleted, ignore it!
		if node.is_queued_for_deletion(): continue
		
		if "location" in node and node.location == GameEnums.Location.SLOT:
			valid_cards.append(node)
	return valid_cards
# --- PART 1: PLACEMENT RULES (Can I drop this card?) ---
func validate_addition(new_card: Card) -> GameEnums.ComboValidationResult:
	var active_cards = get_cards_in_slots()
	var categories = active_cards.map(func(c): return c.card_category)
	
	# Rule 4: TANGLAW (Max 2, Never with Lahi)
	if new_card.card_category == GameEnums.CardCategory.TANGLAW:
		if categories.count(GameEnums.CardCategory.TANGLAW) >= 2:
			return GameEnums.ComboValidationResult.INVALID_TRI_TANGLAW
		if GameEnums.CardCategory.LAHI in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_TANGLAW_MIX

	# Rule 3: DIWA (Max 1)
	if new_card.card_category == GameEnums.CardCategory.DIWA:
		if GameEnums.CardCategory.DIWA in categories:
			return GameEnums.ComboValidationResult.INVALID_DUPLICATE_DIWA

	# Rule 1 & 2: LAHI Interaction (Needs Diwa/Kalikasan partner)
	if new_card.card_category == GameEnums.CardCategory.LAHI:
		if GameEnums.CardCategory.TANGLAW in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_TANGLAW_MIX
		# Second Lahi requires a Diwa to be present
		if GameEnums.CardCategory.LAHI in categories and not GameEnums.CardCategory.DIWA in categories:
			return GameEnums.ComboValidationResult.INVALID_LAHI_NEEDS_DIWA

	# Rule: KALIKASAN + LAHI dependency
	if new_card.card_category == GameEnums.CardCategory.KALIKASAN:
		if GameEnums.CardCategory.LAHI in categories:
			var has_diwa_slot = GameEnums.CardCategory.DIWA in categories
			var has_diwa_hand = player_hand.player_cards.any(func(c): return c.card_category == GameEnums.CardCategory.DIWA)
			if not (has_diwa_slot or has_diwa_hand):
				return GameEnums.ComboValidationResult.INVALID_LAHI_NEEDS_DIWA

	return GameEnums.ComboValidationResult.VALID

func validate_cast() -> bool:
	var active = get_cards_in_slots()
	if active.is_empty(): return false
	var categories = active.map(func(c): return c.card_category)
	
	# Trio Check: Lahi mixed with others MUST have Diwa + Kalikasan
	if GameEnums.CardCategory.LAHI in categories and active.size() > 1:
		var has_diwa = GameEnums.CardCategory.DIWA in categories
		var has_kali = GameEnums.CardCategory.KALIKASAN in categories
		if not (has_diwa and has_kali): return false
		
	# Tanglaw Check: Cannot do damage alone
	return true
