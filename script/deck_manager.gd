extends Node2D

var all_cards = []
var deck = []
@onready var player_hand: Node2D = $"../PlayerHand"

func _ready():
	load_all_cards()
	build_deck()
	shuffle_deck()
	
func load_all_cards():
	all_cards.clear()

	var source = PlayerProfile.current_deck

	if source.is_empty():
		source = PlayerProfile.owned_cards

	for card_path in source:
		if CardRegistry.all_cards.has(card_path):
			all_cards.append(CardRegistry.all_cards[card_path])

	print("Loaded", all_cards.size(), "cards")

func load_folder(path:String):
	var dir = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card = load(path + "/" + file_name)
			all_cards.append(card)
		file_name = dir.get_next()
	dir.list_dir_end()
	
func build_deck():
	deck.clear()
	for card in all_cards:
		match card.rarity:
			GameEnums.CardRarity.Karaniwan:
				for i in range(3):
					deck.append(card)
			GameEnums.CardRarity.Natatangi:
				for i in range(2):
					deck.append(card)
			GameEnums.CardRarity.Bihira:
				deck.append(card)
			GameEnums.CardRarity.Dambana:
				deck.append(card)
	print("For debugging gihapon deck size right now: ", deck.size())
	
func shuffle_deck():
	BattleEvents.special_shuffle_requested.emit()
	deck.shuffle()

# Draws cards from our deck. Automatically replenishes if the deck runs dry mid-game.
func draw_cards(amount:int):
	var drawn_cards = []
	for i in range(amount):
		if deck.is_empty():
			print("Deck is out of cards! Re-shuffling and replenishing from deck builder selections...")
			build_deck()
			shuffle_deck()
			
			if deck.is_empty():
				print("Warning: Attempted to replenish deck, but all_cards profile configuration is empty!")
				break
				
		drawn_cards.append(deck.pop_back())
	return drawn_cards

func redraw_hand():
	var all_nodes = get_tree().get_nodes_in_group("cards")
	for node in all_nodes:
		if "state" in node and node.state == GameEnums.CardState.PLAYED:
			node.queue_free()
			continue
		
		if "location" in node and node.location != GameEnums.Location.DECK:
			if node.card_data:
				deck.append(node.card_data)
			node.queue_free()
	
	player_hand.player_cards.clear()
	
	var slots_folder = get_node_or_null("../../Slots")
	if slots_folder:
		for slot in slots_folder.get_children():
			if "card_in_slot" in slot:
				slot.card_in_slot = false
				
	shuffle_deck()
	player_hand.draw_starting_hand()
