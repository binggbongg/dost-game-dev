
extends Control

# UI References - Direct paths from your Image 3
@onready var texture_rect = get_node_or_null("Card")
@onready var name_label = get_node_or_null("CardNameHolder/Name")
@onready var rarity_pill = get_node_or_null("Rarirty")
@onready var rarity_label = get_node_or_null("Rarirty/Rarity")
@onready var desc_label = get_node_or_null("DescriptionFull")

# The 4 physical pill nodes in your scene
@onready var physical_slots = [
	get_node_or_null("ManaCost"),
	get_node_or_null("Attack"),
	get_node_or_null("Shield"),
	get_node_or_null("Heal")
]

# We store the original icons so we can swap them into any pill
var icon_textures = {}

func _ready():
	# Capture icons once at startup from your existing scene setup
	if physical_slots[0]: icon_textures["mana"] = physical_slots[0].get_node("Icon").texture
	if physical_slots[1]: icon_textures["attack"] = physical_slots[1].get_node("Icon").texture
	if physical_slots[2]: icon_textures["shield"] = physical_slots[2].get_node("Icon").texture
	if physical_slots[3]: icon_textures["heal"] = physical_slots[3].get_node("Icon").texture

func display(card_res: Resource):
	if card_res == null:
		self.hide()
		return
	
	self.show()
	
	# 1. Update basic info & Scaling Logic
	if texture_rect: 
		texture_rect.texture = card_res.get("texture")
		
		# --- AUTO-SCALING LOGIC ---
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# FIXED: Correct Godot 4 constant name
		texture_rect.texture_filter = TEXTURE_FILTER_NEAREST 
		# --------------------------

	if name_label: name_label.text = str(card_res.get("name"))
	if desc_label: desc_label.text = str(card_res.get("description"))
	
	# 2. Rarity logic
	var r = card_res.get("rarity")
	if rarity_pill and r != null:
		rarity_pill.show()
		rarity_label.text = GameEnums.CardRarity.keys()[r]
	elif rarity_pill:
		rarity_pill.hide()

	# 3. Gather active stats (only if value > 0)
	var active_stats = []
	
	var m = card_res.get("mana_cost")
	if m != null and m > 0:
		active_stats.append({"text": "Mana Cost: " + str(int(m)), "type": "mana"})
		
	var a = card_res.get("damage")
	if a != null and a > 0:
		active_stats.append({"text": "Attack Power: " + str(int(a)), "type": "attack"})
		
	var s = card_res.get("shield") if "shield" in card_res else 0
	if s > 0:
		active_stats.append({"text": "Shield Power: " + str(int(s)), "type": "shield"})
		
	var h = card_res.get("heal")
	if h != null and h > 0:
		active_stats.append({"text": "Heal Power: " + str(int(h)), "type": "heal"})

	# 4. Push data into the physical nodes in order (Top to Bottom)
	for i in range(physical_slots.size()):
		var pill = physical_slots[i]
		if pill == null: continue
		
		if i < active_stats.size():
			pill.show()
			var data = active_stats[i]
			
			# Set the correct icon for this stat
			pill.get_node("Icon").texture = icon_textures[data.type]
			
			# This loop finds the first Label child and sets the text
			for child in pill.get_children():
				if child is Label:
					child.text = data.text
		else:
			pill.hide()

func display_combo(title: String, body: String):
	self.show()
	for p in physical_slots: if p: p.hide()
	if rarity_pill: rarity_pill.hide()
	if name_label: name_label.text = title
	if desc_label: desc_label.text = body
	if texture_rect: texture_rect.texture = null
