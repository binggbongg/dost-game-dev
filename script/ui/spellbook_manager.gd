extends Node

const CARDS_PER_SPREAD := 2
var all_cards: Array = []
var filtered_cards: Array = []
var current_spread := 0
var combo_mode := false

# VISIBILITY GROUPS (These are the parent containers)
@onready var card_group = get_node_or_null("../CardSlots")
@onready var combo_group = get_node_or_null("../ComboSlot")

# THE PAGE SLOTS
@onready var left_slot = get_node_or_null("../CardSlots/SpellbookCardSlotLeft")
@onready var right_slot = get_node_or_null("../CardSlots/SpellbookCardSlotRight")
@onready var combo_l = get_node_or_null("../ComboSlot/ComboSlotLeftTop")
@onready var combo_r = get_node_or_null("../ComboSlot/ComboSlotRightTop")

@onready var page_label = get_node_or_null("../Pagination/Label")

var combo_pages = [
	["🌿 + 🌿", "Two Kalikasan cards.", "🌿 + 🌿 + 🌿", "Three Kalikasan cards."],
	["🌿 + 👻", "Kalikasan + Diwa.", "🌿 + ☀️", "Kalikasan + Tanglaw."],
	["👥 + 👻 + 🌿", "Lahi + Diwa + Kalikasan.", "👥 + 👻 + 👥", "Lahi + Diwa + Lahi."]
]

func _ready():
	load_all_cards()
	connect_ui()
	
	# Open default tab
	await get_tree().process_frame
	open_category(GameEnums.CardCategory.KALIKASAN)

func load_all_cards():
	all_cards.clear()
	var folders = ["Kalikasan", "Tanglaw", "Lahi", "Diwa"]
	for folder in folders:
		var path = "res://data/" + folder
		var dir = DirAccess.open(path)
		if dir:
			dir.list_dir_begin()
			var file = dir.get_next()
			while file != "":
				if file.ends_with(".tres"):
					var res = load(path + "/" + file)
					if res: all_cards.append(res)
				file = dir.get_next()

func connect_ui():
	# Connecting bookmark buttons manually to ensure they are robust
	var bk = "../Bookmarks/"
	get_node(bk + "Kalikasan").pressed.connect(func(): open_category(GameEnums.CardCategory.KALIKASAN))
	get_node(bk + "Tanglaw").pressed.connect(func(): open_category(GameEnums.CardCategory.TANGLAW))
	get_node(bk + "Lahi").pressed.connect(func(): open_category(GameEnums.CardCategory.LAHI))
	get_node(bk + "Diwa").pressed.connect(func(): open_category(GameEnums.CardCategory.DIWA))
	get_node(bk + "Combo").pressed.connect(open_combo_mode)
	
	get_node("../Pagination/Left").pressed.connect(prev_page)
	get_node("../Pagination/Right").pressed.connect(next_page)

#==========================
# TAB SWITCHING
#==========================

func open_category(category):
	combo_mode = false
	if card_group: card_group.show()
	if combo_group: combo_group.hide()
	
	current_spread = 0
	filtered_cards = all_cards.filter(func(c): return c.category == category)
	refresh_display()

func open_combo_mode():
	combo_mode = true
	if card_group: card_group.hide()
	if combo_group: combo_group.show()
	
	current_spread = 0
	refresh_display()

#==========================
# PAGINATION & REFRESH
#==========================

func refresh_display():
	if combo_mode:
		var data = combo_pages[current_spread]
		if combo_l: combo_l.display_combo(data[0], data[1])
		if combo_r: combo_r.display_combo(data[2], data[3])
		if page_label: page_label.text = "Combo " + str(current_spread + 1)
	else:
		var i = current_spread * 2
		if left_slot: left_slot.display(filtered_cards[i] if i < filtered_cards.size() else null)
		if right_slot: right_slot.display(filtered_cards[i+1] if i+1 < filtered_cards.size() else null)
		
		var total = maxi(1, ceili(filtered_cards.size() / 2.0))
		if page_label: page_label.text = "Page " + str(current_spread + 1) + " / " + str(total)

func next_page():
	var max_p = combo_pages.size() - 1 if combo_mode else ceili(filtered_cards.size() / 2.0) - 1
	if current_spread < max_p:
		current_spread += 1
		refresh_display()

func prev_page():
	if current_spread > 0:
		current_spread -= 1
		refresh_display()
