extends Control
signal spell_selected(res)

@onready var triple_container = $SpellItem_Tripple
@onready var double_container = $SpellItem_Double

@export_group("Element Textures")
@export var tex_kalikasan: Texture2D
@export var tex_tanglaw: Texture2D
@export var tex_diwa: Texture2D
@export var tex_lahi: Texture2D

var spell_res

func setup_spell(res):
	spell_res = res
	var manager = get_tree().current_scene.find_child("SpellbookManager", true, false)
	
	if res.elements.size() >= 3:
		_setup_panel(triple_container, res, manager, true)
		double_container.hide()
		triple_container.show()
	else:
		_setup_panel(double_container, res, manager, false)
		triple_container.hide()
		double_container.show()

func _setup_panel(panel, res, manager, is_triple):
	panel.get_node("ItemCost_Description_Score").text = res.name
	
	var t1 = panel.get_node_or_null("ItemTexture")
	var t2 = panel.get_node_or_null("ItemTexture2")
	var t3 = panel.get_node_or_null("ItemTexture3")
	
	if is_triple:
		if t1: t1.texture = _get_tex(res.elements[0], manager)
		if t2: t2.texture = _get_tex(res.elements[1], manager)
		if t3: t3.texture = _get_tex(res.elements[2], manager)
	else:
		if t2: t2.texture = _get_tex(res.elements[0], manager)
		if t3: t3.texture = _get_tex(res.elements[1], manager)
	
	var btn = panel.get_node("Button")
	if not btn.pressed.is_connected(_on_pressed): 
		btn.pressed.connect(_on_pressed)

# Helper function that falls back to local exports if manager fails
func _get_tex(element_val, manager) -> Texture2D:
	if manager:
		var tex = manager.get_texture_for_element(element_val)
		if tex: return tex
		
	# Fallback directly to slot properties
	var type_str = ""
	if element_val is String:
		type_str = element_val.to_lower().strip_edges()
	elif element_val is int:
		type_str = GameEnums.CardCategory.keys()[element_val].to_lower()
		
	match type_str:
		"kalikasan": return tex_kalikasan
		"tanglaw": return tex_tanglaw
		"diwa": return tex_diwa
		"lahi": return tex_lahi
	return null

func _on_pressed():
	spell_selected.emit(spell_res)
