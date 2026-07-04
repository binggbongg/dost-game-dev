extends Node

const CARDS_PER_SPREAD := 2
const COMBOS_PER_SPREAD := 4

var all_cards: Array = []
var all_combos: Array = []
var filtered_cards: Array = []

var current_spread := 0
var combo_mode := false


@onready var card_parent = get_node_or_null("../CardSlots")
@onready var combo_parent = get_node_or_null("../ComboSlot")
@onready var left_slot = get_node_or_null("../CardSlots/SpellbookCardSlotLeft")
@onready var right_slot = get_node_or_null("../CardSlots/SpellbookCardSlotRight")
@onready var page_label = get_node_or_null("../Pagination/Label")

func _ready():
	load_all_cards()
	load_all_combos()
	setup_connections()
	
	await get_tree().process_frame
	open_category(GameEnums.CardCategory.KALIKASAN)


func load_all_cards():
	all_cards.clear()
	var folders = ["Kalikasan", "Tanglaw", "Lahi", "Diwa"]
	for folder in folders:
		var path = "res://data/" + folder + "/"
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if file.ends_with(".tres") or file.ends_with(".res"):
					var full_path = path + file
					var res = load(full_path)
					if res: 
						# Store BOTH the resource and its file path so we can check ownership status later
						all_cards.append({"resource": res, "path": full_path})
				file = dir.get_next()

func load_all_combos():
	all_combos.clear()
	var path = "res://data/ComboRecipe/"
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var res = load(path + file_name)
				if res: all_combos.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	all_combos.sort_custom(func(a, b):
		if a.elements.size() != b.elements.size():
			return a.elements.size() < b.elements.size()
		return a.name < b.name
	)


func setup_connections():
	var bk = "../Bookmarks/"
	get_node(bk + "Kalikasan").pressed.connect(func(): open_category(GameEnums.CardCategory.KALIKASAN))
	get_node(bk + "Tanglaw").pressed.connect(func(): open_category(GameEnums.CardCategory.TANGLAW))
	get_node(bk + "Lahi").pressed.connect(func(): open_category(GameEnums.CardCategory.LAHI))
	get_node(bk + "Diwa").pressed.connect(func(): open_category(GameEnums.CardCategory.DIWA))
	get_node(bk + "Combo").pressed.connect(open_combo_mode)
	
	get_node("../Pagination/Left").pressed.connect(prev_page)
	get_node("../Pagination/Right").pressed.connect(next_page)

func open_category(category):
	combo_mode = false
	if card_parent: card_parent.show()
	if combo_parent: combo_parent.hide()
	
	current_spread = 0
	# Filter based on the resource attribute inside our dictionary setup
	filtered_cards = all_cards.filter(func(c): return c.resource.category == category)
	AudioManager.play_ui_sound("flip")
	refresh_display()

func open_combo_mode():
	combo_mode = true
	if card_parent: card_parent.hide()
	if combo_parent: combo_parent.show()
	
	current_spread = 0
	AudioManager.play_ui_sound("flip")
	refresh_display()


func refresh_display():
	if combo_mode:
		var start_idx = current_spread * COMBOS_PER_SPREAD
		# The 4 combo slots in your book
		var slots = [
			get_node_or_null("../ComboSlot/ComboSlotLeftTop"),
			get_node_or_null("../ComboSlot/ComboSlotLeftBottom"),
			get_node_or_null("../ComboSlot/ComboSlotRightTop"),
			get_node_or_null("../ComboSlot/ComboSlotRightBottom")
		]
		
		for i in range(slots.size()):
			if slots[i]:
				var data_idx = start_idx + i
				if data_idx < all_combos.size():
					slots[i].display_recipe(all_combos[data_idx])
				else:
					slots[i].hide()
		
		var total = maxi(1, ceili(all_combos.size() / float(COMBOS_PER_SPREAD)))
		if page_label: page_label.text = "Page %d / %d" % [current_spread + 1, total]
	
	else:
		var i = current_spread * CARDS_PER_SPREAD
		
		# Left Slot Handling
		if left_slot:
			if i < filtered_cards.size():
				var card_data = filtered_cards[i]
				var is_owned = PlayerProfile.owned_cards.has(card_data.path)
				
				left_slot.display(card_data.resource)
				left_slot.modulate = Color(1, 1, 1, 1) if is_owned else Color(0.25, 0.25, 0.25, 0.7)
			else:
				left_slot.display(null)
		
		# Right Slot Handling
		if right_slot:
			if i + 1 < filtered_cards.size():
				var card_data = filtered_cards[i+1]
				var is_owned = PlayerProfile.owned_cards.has(card_data.path)
				
				right_slot.display(card_data.resource)
				right_slot.modulate = Color(1, 1, 1, 1) if is_owned else Color(0.25, 0.25, 0.25, 0.7)
			else:
				right_slot.display(null)
		
		var total = maxi(1, ceili(filtered_cards.size() / float(CARDS_PER_SPREAD)))
		if page_label: page_label.text = "Page %d / %d" % [current_spread + 1, total]

func next_page():
	var max_p = 0
	if combo_mode:
		max_p = ceili(all_combos.size() / float(COMBOS_PER_SPREAD)) - 1
	else:
		max_p = ceili(filtered_cards.size() / float(CARDS_PER_SPREAD)) - 1
		
	if current_spread < max_p:
		current_spread += 1
		AudioManager.play_ui_sound("flip")
		refresh_display()
	

func prev_page():
	if current_spread > 0:
		current_spread -= 1
		AudioManager.play_ui_sound("flip")
		refresh_display()
