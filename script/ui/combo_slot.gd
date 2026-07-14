extends Control

@export_group("Combo Element Templates")
@export var tex_kalikasan: Texture2D
@export var tex_tanglaw: Texture2D
@export var tex_diwa: Texture2D
@export var tex_lahi: Texture2D

@onready var special_panel = $SpecialCards
@onready var double_panel = $Spell_double
@onready var triple_panel = $Spell_triiple

func display_content(res):
	if special_panel: special_panel.hide()
	if double_panel: double_panel.hide()
	if triple_panel: triple_panel.hide()
	
	if res == null: return
	var manager = get_tree().current_scene.find_child("SpellbookManager", true, false)

	if res is SpecialCardData or res.get("elements") == null:
		if special_panel:
			special_panel.show()
			_fill_special(res)
	else:
		var elements_array = res.get("elements")
		if elements_array.size() >= 3:
			if triple_panel:
				triple_panel.show()
				_fill_combo(triple_panel, res, manager, true, elements_array)
		else:
			if double_panel:
				double_panel.show()
				_fill_combo(double_panel, res, manager, false, elements_array)

func _fill_special(res):
	var n = special_panel.get_node_or_null("Name")
	var c = special_panel.get_node_or_null("Card")
	var d = special_panel.get_node_or_null("DescriptionPanel/DescriptionFull")
	var l = special_panel.get_node_or_null("FilipinoLoreLabelFull")
	var e = special_panel.get_node_or_null("SpecialEffectFull")
	
	if n: n.text = str(res.get("name"))
	if c: 
		c.texture = res.get("texture")
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if d: d.text = str(res.get("description"))
	if l: l.text = str(res.get("FilipinoLore"))
	if e: e.text = str(res.get("ASLExplanation"))

func _fill_combo(panel, res, manager, is_triple, elements_array):
	var n = panel.get_node_or_null("Name")
	var d = panel.get_node_or_null("DescriptionPanel/DescriptionFull")
	var f = panel.get_node_or_null("FilipinoLoreFull")
	if n: n.text = str(res.get("name"))
	if d: d.text = str(res.get("description"))
	if f: f.text = str(res.get("filipino_lore"))
	if elements_array.size() > 0:
		var c1 = panel.get_node_or_null("Card")
		var c2 = panel.get_node_or_null("Card2")
		var c3 = panel.get_node_or_null("Card3")
		
		if is_triple:
			if c1: c1.texture = _get_tex(elements_array[0], manager)
			if c2: c2.texture = _get_tex(elements_array[1], manager)
			if c3: c3.texture = _get_tex(elements_array[2], manager)
		else:
			if c2: c2.texture = _get_tex(elements_array[0], manager)
			if c3: c3.texture = _get_tex(elements_array[1], manager)

func _get_tex(element_val, manager) -> Texture2D:
	if manager:
		var tex = manager.get_texture_for_element(element_val)
		if tex: return tex
		
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
