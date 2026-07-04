extends Control

# UI References
@onready var texture_rect = get_node_or_null("Card")
@onready var name_label = get_node_or_null("CardNameHolder/Name")
@onready var rarity_pill = get_node_or_null("Rarirty")
@onready var rarity_label = get_node_or_null("Rarirty/Rarity")
@onready var desc_label = get_node_or_null("DescriptionFull")

# Generic display slots (their names don't matter anymore)
@onready var physical_slots = [
	get_node_or_null("ManaCost"),
	get_node_or_null("Attack"),
	get_node_or_null("Shield"),
	get_node_or_null("Heal")
]

var icon_textures = {}

func _ready():
	# Save the icons currently assigned to each slot safely
	if physical_slots[0]:
		var icon = physical_slots[0].get_node_or_null("Icon")
		if icon: icon_textures["mana"] = icon.texture

	if physical_slots[1]:
		var icon = physical_slots[1].get_node_or_null("Icon")
		if icon == null:
			icon = physical_slots[1].get_node_or_null("Icon2")
		if icon: icon_textures["attack"] = icon.texture

	if physical_slots[2]:
		var icon = physical_slots[2].get_node_or_null("Icon")
		if icon: icon_textures["multiplier"] = icon.texture

	if physical_slots[3]:
		var icon = physical_slots[3].get_node_or_null("Icon")
		if icon: icon_textures["heal"] = icon.texture


func display(card_res: Resource):
	if card_res == null:
		hide()
		return

	show()

	# -----------------------------
	# Card Info
	# -----------------------------
	if texture_rect:
		texture_rect.texture = card_res.get("texture")
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.texture_filter = TEXTURE_FILTER_NEAREST

	if name_label:
		name_label.text = str(card_res.get("name"))

	if desc_label:
		desc_label.text = str(card_res.get("description"))

	# -----------------------------
	# Rarity
	# -----------------------------
	var r = card_res.get("rarity")

	if rarity_pill:
		if r != null:
			rarity_pill.show()
			if rarity_label:
				rarity_label.text = GameEnums.CardRarity.keys()[r]
		else:
			rarity_pill.hide()

	# -----------------------------
	# Build active stats
	# -----------------------------
	var active_stats = []

	# Defined as a lambda to cleanly modify active_stats in-line
	var add_stat = func(value, label, icon):
		if value == null:
			value = 0

		if value > 0:
			active_stats.append({
				"text": "%s: %s" % [label, str(value)],
				"icon": icon
			})

	# Safely call the lambda using .call(), using .get() to avoid missing key crashes
	add_stat.call(card_res.get("mana_cost"), "Mana Cost", icon_textures.get("mana"))
	add_stat.call(card_res.get("damage"), "Damage", icon_textures.get("attack"))
	add_stat.call(card_res.get("heal"), "Heal", icon_textures.get("heal"))
	add_stat.call(card_res.get("multiplier"), "Multiplier", icon_textures.get("multiplier"))

	# -----------------------------
	# Fill the display slots
	# -----------------------------
	for i in range(physical_slots.size()):
		var slot = physical_slots[i]

		if slot == null:
			continue

		if i >= active_stats.size():
			slot.hide()
			continue

		slot.show()

		var stat = active_stats[i]

		var icon = slot.get_node_or_null("Icon")
		if icon == null:
			icon = slot.get_node_or_null("Icon2")

		if icon:
			icon.texture = stat.icon

		for child in slot.get_children():
			if child is Label:
				child.text = stat.text
				break


func display_combo(title: String, body: String):
	show()

	for p in physical_slots:
		if p:
			p.hide()

	if rarity_pill:
		rarity_pill.hide()

	if name_label:
		name_label.text = title

	if desc_label:
		desc_label.text = body

	if texture_rect:
		texture_rect.texture = null
