extends Node

const ITEM_HOLDER_SCENE = preload("res://scenes/menus/spellbook_item_holder.tscn")
const SPECIAL_SLOT_SCENE = preload("res://scenes/menus/spellbook_special_cards.tscn")
const COMBO_SLOT_SCENE = preload("res://scenes/menus/spellbook_spells_slot.tscn")
const COMBO_PATH = "res://data/ComboRecipe/"
#UI
@onready var chapter: Label = $"../Chapter"
@onready var item_numbers: Label = $"../ItemNumbers"
@onready var coming_soon: Label = $"../Coming Soon"

# --- TEXTURE EXPORTS FOR COMBO MAPPING ---
@export_group("Category Textures")
@export var texture_kalikasan: Texture2D
@export var texture_tanglaw: Texture2D
@export var texture_diwa: Texture2D
@export var texture_lahi: Texture2D

# --- RIGHT PAGE REFERENCES ---
@onready var tab1_right_page: Control = $"../RightPage/SpellbookCards"
@onready var tab2_right_page: Control = $"../RightPage/ComboSlot" # Fixed: Points directly to ComboSlot UI script

# --- SPELLBOOK TAB BUTTONS ---
@onready var cards_button_tab1: TextureButton = $"../Bookmarks/Cards"
@onready var spells_button_tab2: TextureButton = $"../Bookmarks/Spells"
@onready var battle_journal_tab3: TextureButton = $"../Bookmarks/BattleJournal"
@onready var star_fragments_tab4: TextureButton = $"../Bookmarks/StarFragments"
@onready var locations_tab5: TextureButton = $"../Bookmarks/Locations"

# --- SPELLBOOK LEFT PAGE PANELS ---
@onready var tab_1_cards: Control = $"../LeftPage/Tab1_Cards"
@onready var tab_2_special_spells: Control = $"../LeftPage/Tab2_Special_Spells"
@onready var tab_3_battle_journal: Control = $"../LeftPage/Tab3_BattleJournal"
@onready var tab_4_star_fragments: Control = $"../LeftPage/Tab4_StarFragments"
@onready var tab_5_world: Control = $"../LeftPage/Tab5_World"

# --- GRID CONTAINERS ---
@onready var cards_container: GridContainer = $"../LeftPage/Tab1_Cards/Tab1Holder/CardsContainer"
@onready var special_card_container: GridContainer = $"../LeftPage/Tab2_Special_Spells/SpecialCardsHolder/SpecialCardContainer"
@onready var spell_container: GridContainer = $"../LeftPage/Tab2_Special_Spells/SpellHolder/SpellContainer"

# --- EMPTY LABEL ---
@onready var empty: Label = $"../LeftPage/Tab2_Special_Spells/Empty"

# --- PAGINATION BUTTONS ---
@onready var cards_bookmark = cards_button_tab1
@onready var spells_bookmark = spells_button_tab2


func _ready():
	setup_connections()
	await get_tree().process_frame
	open_cards_tab()

func setup_connections():
	if cards_bookmark: cards_bookmark.pressed.connect(open_cards_tab)
	if spells_bookmark: spells_bookmark.pressed.connect(open_spells_tab)

	# Dictionary mapping for non-inventory titles
	var non_inventory_tabs = {
		"BattleJournal": "Battle Journal",
		"StarFragments": "Star Fragments",
		"Locations": "World Discovery"
	}
	
	var bk = "../Bookmarks/"
	for b_name in non_inventory_tabs.keys():
		var b_node = get_node_or_null(bk + b_name)
		if b_node:
			b_node.pressed.connect(func():
				hide_cards_tab()
				hide_spells_tab()
				if chapter: chapter.text = non_inventory_tabs[b_name]
				if item_numbers: item_numbers.hide()
				if coming_soon: coming_soon.show() # Shows the overlay panel for these tabs
			)

# --- TAB 1 LOGIC (Owned Base Cards) ---
func open_cards_tab():
	hide_spells_tab()
	if coming_soon: coming_soon.hide() # Ensure it's hidden when returning to inventory tabs
	if tab_1_cards: tab_1_cards.show()
	if tab1_right_page: tab1_right_page.show()
	
	if chapter: chapter.text = "My Cards"
	if item_numbers:
		item_numbers.text = "Owned Cards: %d" % PlayerProfile.owned_cards.size()
		item_numbers.show()
		
	reload_tab1_data()

# --- TAB 2 LOGIC (Specials & Combos) ---
func open_spells_tab():
	hide_cards_tab()
	if coming_soon: coming_soon.hide() # Ensure it's hidden when returning to inventory tabs
	if tab_2_special_spells: tab_2_special_spells.show()
	if tab2_right_page: tab2_right_page.show()
	
	if chapter: chapter.text = "My Spells"
	if item_numbers: item_numbers.show()
	
	reload_tab2_data()


func get_texture_for_element(element_val) -> Texture2D:
	if element_val == null: return null
	
	var type_str = ""
	if element_val is String:
		type_str = element_val.to_lower().strip_edges()
	elif element_val is int or element_val is float:
		# Safeguard against out-of-bounds enum integers
		var keys = GameEnums.CardCategory.keys()
		var idx = int(element_val)
		if idx >= 0 and idx < keys.size():
			type_str = keys[idx].to_lower()
		
	match type_str:
		"kalikasan": return texture_kalikasan
		"tanglaw": return texture_tanglaw
		"diwa": return texture_diwa
		"lahi": return texture_lahi
	return null



func hide_cards_tab():
	if tab_1_cards: tab_1_cards.hide()
	if tab1_right_page: tab1_right_page.hide()


func hide_spells_tab():
	if tab_2_special_spells: tab_2_special_spells.hide()
	if tab2_right_page: tab2_right_page.hide()

# --- UPDATE DATA RELOAD FOR TAB 2 ---
#func reload_tab2_data():
	#for child in special_card_container.get_children(): child.queue_free()
	#for child in spell_container.get_children(): child.queue_free()
	#
	#var owned_count = 0
	#var first_valid_resource: Resource = null
	#
	## Load Specials
	#for item_id in PlayerInventory.owned_items.keys():
		#var res = ItemDb.get_item(item_id)
		#if res and (res is SpecialCardData or res.has_method("is_special_card")):
			#owned_count += 1
			#if not first_valid_resource: first_valid_resource = res
			#var inst = SPECIAL_SLOT_SCENE.instantiate()
			#special_card_container.add_child(inst)
			#
			#if inst.has_method("setup_item"): 
				#inst.setup_item(res)
			#
			#if inst.has_signal("card_selected"): 
				#inst.card_selected.connect(_on_tab2_selected)
	#
	## Dynamically update Special Cards label count
	#if item_numbers:
		#item_numbers.text = "Special Cards: %d" % owned_count
#
	#if empty:
		#empty.visible = (owned_count == 0)
#
	## Load Combos
	#var dir = DirAccess.open(COMBO_PATH)
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
				#var res = load(COMBO_PATH + file_name)
				#if not first_valid_resource: first_valid_resource = res
				#var inst = COMBO_SLOT_SCENE.instantiate()
				#spell_container.add_child(inst)
				#
				#if inst.has_method("setup_spell"): 
					#inst.setup_spell(res)
				#
				#if inst.has_signal("spell_selected"): 
					#inst.spell_selected.connect(_on_tab2_selected)
					#
			#file_name = dir.get_next()
			#
	#if first_valid_resource and tab2_right_page.has_method("display_content"):
		#tab2_right_page.display_content(first_valid_resource)

func reload_tab2_data():
	for child in special_card_container.get_children(): child.queue_free()
	for child in spell_container.get_children(): child.queue_free()
	
	var owned_count = 0
	var first_valid_resource: Resource = null
	
	# Load Specials
	for item_id in PlayerInventory.owned_items.keys():
		var res = ItemDb.get_item(item_id)
		if res and (res is SpecialCardData or res.has_method("is_special_card")):
			owned_count += 1
			if not first_valid_resource: first_valid_resource = res
			var inst = SPECIAL_SLOT_SCENE.instantiate()
			special_card_container.add_child(inst)
			
			if inst.has_method("setup_item"): 
				inst.setup_item(res)
			
			if inst.has_signal("card_selected"): 
				inst.card_selected.connect(_on_tab2_selected)
	
	# Dynamically update Special Cards label count
	if item_numbers:
		item_numbers.text = "Special Cards: %d" % owned_count
	if empty:
		empty.visible = (owned_count == 0)
	
	# Load Combos
	var files = ResourceLoader.list_directory(COMBO_PATH)
	for file_name in files:
		if file_name.ends_with("/"):
			continue
		
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var res = load(COMBO_PATH.path_join(file_name))
			if not first_valid_resource: first_valid_resource = res
			var inst = COMBO_SLOT_SCENE.instantiate()
			spell_container.add_child(inst)
			
			if inst.has_method("setup_spell"): 
				inst.setup_spell(res)
			
			if inst.has_signal("spell_selected"): 
				inst.spell_selected.connect(_on_tab2_selected)
			
	if first_valid_resource and tab2_right_page.has_method("display_content"):
		tab2_right_page.display_content(first_valid_resource)

# --- TAB 1 LOGIC (Owned Base Cards) ---


func reload_tab1_data():
	if not cards_container: return
	for child in cards_container.get_children(): child.queue_free()
	
	for path in PlayerProfile.owned_cards:
		if ResourceLoader.exists(path):
			var res = load(path)
			var inst = ITEM_HOLDER_SCENE.instantiate()
			cards_container.add_child(inst)
			
			if inst.has_method("setup_item"): 
				inst.setup_item(res)
			
			if inst.has_signal("card_selected"):
				inst.card_selected.connect(_on_tab1_selected)
			
	if cards_container.get_child_count() > 0 and tab1_right_page.has_method("display"):
		tab1_right_page.display(load(PlayerProfile.owned_cards[0]))

func _on_tab1_selected(res):
	if tab1_right_page and tab1_right_page.has_method("display"): 
		tab1_right_page.display(res)



func _on_tab2_selected(res):
	if has_node("/root/AudioManager") and AudioManager.has_method("play_ui_sound"): 
		AudioManager.play_ui_sound("flip")
	
	if tab2_right_page and tab2_right_page.has_method("display_content"): 
		tab2_right_page.display_content(res)

# --- PAGINATION ---
func _on_next_chapter():
	if tab_1_cards and tab_1_cards.visible: open_spells_tab()

func _on_prev_chapter():
	if tab_2_special_spells and tab_2_special_spells.visible: open_cards_tab()
