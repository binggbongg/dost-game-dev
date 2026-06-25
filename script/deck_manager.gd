extends Node2D

var all_cards = []
var deck = []
@onready var player_hand: Node2D = $"../PlayerHand"

func _ready():
	load_all_cards()
	build_deck()
	shuffle_deck()
	
#initialize tanan cards and access them from our resources
func load_all_cards():
	all_cards.clear()
	load_folder("res://data/Diwa")
	load_folder("res://data/Kalikasan")
	load_folder("res://data/Lahi")
	load_folder("res://data/Tanglaw")
	print("Debugging the loading of the cards: ", all_cards.size())
	
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
	
#himuon na atong deckk (dapat shared ra ang deck sa player and enemy)
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
	deck.shuffle()

#this will initialize drawing of card from our deck para mao ang method tawgon after mahuman ang turn sa player/enemy and sa start pud sa game
func draw_cards(amount:int):
	var drawn_cards = []
	for i in range(amount):
		if deck.is_empty():
			break
		drawn_cards.append(deck.pop_back())
	return drawn_cards

func redraw_hand():
	var all_nodes = get_tree().get_nodes_in_group("cards")
	for node in all_nodes:
		if "location" in node and node.location != GameEnums.Location.DECK:
			if node.card_data:
				deck.append(node.card_data)
			node.queue_free()
	
	player_hand.player_cards.clear()
	
	# Explicitly clear slots
	var slots_folder = get_node_or_null("../../Slots")
	if slots_folder:
		for slot in slots_folder.get_children():
			if "card_in_slot" in slot:
				slot.card_in_slot = false
				
	shuffle_deck()
	# DRAW THE NEW HAND IMMEDIATELY AS REQUESTED
	player_hand.draw_starting_hand()
