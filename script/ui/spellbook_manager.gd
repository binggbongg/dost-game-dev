extends Node

const ITEM_HOLDER_SCENE = preload("res://scenes/menus/spellbook_item_holder.tscn")
const SPECIAL_SLOT_SCENE = preload("res://scenes/menus/spellbook_special_cards.tscn")
const COMBO_SLOT_SCENE = preload("res://scenes/menus/spellbook_spells_slot.tscn")
const COMBO_PATH = "res://data/ComboRecipe/"


# --- TAB 1 NODES ---
@onready var cards_bookmark = get_node_or_null("../Bookmarks/Cards")
@onready var tab1_left_page = get_node_or_null("../LeftPage/Tab1_Cards")
@onready var tab1_grid = get_node_or_null("../LeftPage/Tab1_Cards/Tab1Holder/GridContainer")
@onready var tab1_right_page = get_node_or_null("../RightPage/SpellbookCards")

# --- TAB 2 NODES ---
@onready var spells_bookmark = get_node_or_null("../Bookmarks/Spells")
@onready var tab2_left_page = get_node_or_null("../LeftPage/Tab2_Special_Spells")
@onready var tab2_right_page = get_node_or_null("../RightPage/ComboSlot")

# Grids inside Tab 2
@onready var special_inv_grid = get_node_or_null("../LeftPage/Tab2_Special_Spells/SpecialCardsHolder/GridContainer")
@onready var combo_recipes_grid = get_node_or_null("../LeftPage/Tab2_Special_Spells/SpellHolder/GridContainer")
@onready var owned_count_label = get_node_or_null("../LeftPage/Tab2_Special_Spells/SpecialCardsHolder/GridContainer/../../Label") # "Owned: 25/36"

# --- NAVIGATION ---
@onready var btn_left = get_node_or_null("../Pagination/Left")
@onready var btn_right = get_node_or_null("../Pagination/Right")

func _ready():
	setup_connections()
	# Start on Tab 1
	await get_tree().process_frame
	open_cards_tab()

func setup_connections():
	# Tab Buttons
	if cards_bookmark: cards_bookmark.pressed.connect(open_cards_tab)
	if spells_bookmark: spells_bookmark.pressed.connect(open_spells_tab)
	
	# Pagination
	if btn_left: btn_left.pressed.connect(_on_prev_chapter)
	if btn_right: btn_right.pressed.connect(_on_next_chapter)
	
	# Hook other tabs to hide everything
	var bk = "../Bookmarks/"
	var hide_all = func():
		hide_cards_tab()
		hide_spells_tab()
		# Add logic for BattleJournal, etc here
		
	for b_name in ["BattleJournal", "StarFragments", "Locations"]:
		var b_node = get_node_or_null(bk + b_name)
		if b_node: b_node.pressed.connect(hide_all)

# --- TAB 1 LOGIC (Owned Base Cards) ---
func open_cards_tab():
	hide_spells_tab()
	if tab1_left_page: tab1_left_page.show()
	if tab1_right_page: tab1_right_page.show()
	reload_tab1_data()

func hide_cards_tab():
	if tab1_left_page: tab1_left_page.hide()
	if tab1_right_page: tab1_right_page.hide()

func reload_tab1_data():
	for child in tab1_grid.get_children(): child.queue_free()
	
	for path in PlayerProfile.owned_cards:
		if ResourceLoader.exists(path):
			var res = load(path)
			var inst = ITEM_HOLDER_SCENE.instantiate()
			tab1_grid.add_child(inst)
			if inst.has_method("setup_item"): inst.setup_item(res)
			if inst.has_signal("card_selected"): inst.card_selected.connect(_on_tab1_selected)
			
	# Default display
	if tab1_grid.get_child_count() > 0 and tab1_right_page.has_method("display"):
		tab1_right_page.display(load(PlayerProfile.owned_cards[0]))

func _on_tab1_selected(res):
	if tab1_right_page.has_method("display"): tab1_right_page.display(res)

# --- TAB 2 LOGIC (Specials & Combos) ---
func open_spells_tab():
	hide_cards_tab()
	if tab2_left_page: tab2_left_page.show()
	if tab2_right_page: tab2_right_page.show()
	reload_tab2_data()

func hide_spells_tab():
	if tab2_left_page: tab2_left_page.hide()
	if tab2_right_page: tab2_right_page.hide()

func reload_tab2_data():
	# 1. Load Inventory Specials (Top Grid)
	for child in special_inv_grid.get_children(): child.queue_free()
	var owned_count = 0
	for item_id in PlayerInventory.owned_items.keys():
		var res = ItemDb.get_item(item_id)
		if res is SpecialCardData:
			owned_count += 1
			var inst = SPECIAL_SLOT_SCENE.instantiate()
			special_inv_grid.add_child(inst)
			inst.setup_item(res)
			if inst.has_signal("card_selected"): inst.card_selected.connect(_on_tab2_selected)
	
	if owned_count_label: owned_count_label.text = "Owned: %d/36" % owned_count

	# 2. Load Combo Recipes Folder (Bottom Grid)
	for child in combo_recipes_grid.get_children(): child.queue_free()
	var dir = DirAccess.open(COMBO_PATH)
	if dir:
		dir.list_dir_begin()
		var file = dir.get_next()
		while file != "":
			if file.ends_with(".tres") or file.ends_with(".tres.remap"):
				var res = load(COMBO_PATH + file.replace(".remap", ""))
				var inst = COMBO_SLOT_SCENE.instantiate()
				combo_recipes_grid.add_child(inst)
				if inst.has_method("setup_spell"): inst.setup_spell(res)
				if inst.has_signal("spell_selected"): inst.spell_selected.connect(_on_tab2_selected)
			file = dir.get_next()

func _on_tab2_selected(res):
	if AudioManager.has_method("play_ui_sound"): AudioManager.play_ui_sound("flip")
	if tab2_right_page.has_method("display_content"): tab2_right_page.display_content(res)

# --- PAGINATION ---
func _on_next_chapter():
	if tab1_left_page.visible: open_spells_tab()

func _on_prev_chapter():
	if tab2_left_page.visible: open_cards_tab()
