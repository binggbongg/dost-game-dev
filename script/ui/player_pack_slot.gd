extends Control

@export var card_pack_cover_close: Texture
@export var card_pack_cover_open: Texture
@onready var cards_container = $Cards
@onready var texture_rect: TextureRect = $TextureRect

# Logic Variables
var card_paths: Array[String] = []
var current_idx := 0
var pack_is_sealed := false # Tracks if we are waiting for the opening click

# Drag/Swipe Variables
var is_dragging := false
var drag_start_pos := Vector2.ZERO
var swipe_threshold := 120

func _ready():
	# Fill screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	visible = false
	scale = Vector2.ZERO
	pivot_offset = get_viewport_rect().size / 2

	cards_container.position = get_viewport_rect().size / 2

	# Pre-configure the existing texture rect pivot for scaling animations
	texture_rect.pivot_offset = texture_rect.size / 2


func open_pack(is_new_player: bool):
	card_paths = CardRegistry.generate_pack_paths(is_new_player)
	current_idx = card_paths.size() - 1

	setup_cards()
	for child in cards_container.get_children():
		child.visible = false

	# Set the closed texture and enable the sealed state
	texture_rect.texture = card_pack_cover_close
	texture_rect.visible = true
	texture_rect.scale = Vector2.ONE
	texture_rect.modulate.a = 1.0
	pack_is_sealed = true

	visible = true

	var tween = create_tween()
	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.45
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_pack_opening():
	AudioManager.play_sound_from_path("res://data/SoundData/sfx/open_pack.wav", false, 0.0)
	pack_is_sealed = false # Block duplicate clicks
	
	var tween = create_tween()
	
	tween.tween_property(texture_rect, "scale", Vector2(1.1, 0.85), 0.15)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func(): texture_rect.texture = card_pack_cover_open)
	tween.tween_interval(0.15)
	
	tween.tween_property(texture_rect, "scale", Vector2(1.5, 1.5), 0.25)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	
	tween.parallel().tween_property(texture_rect, "modulate:a", 0.0, 0.2)\
		.set_delay(0.05)
	
	tween.parallel().tween_callback(func():
		var nodes = cards_container.get_children()
		for i in range(nodes.size()):
			if i < card_paths.size():
				nodes[i].visible = true
	).set_delay(0.05)
	
	tween.tween_callback(func(): texture_rect.visible = false)


func setup_cards():
	var nodes = cards_container.get_children()

	for i in range(nodes.size()):
		var card = nodes[i]

		if i < card_paths.size():
			var data = CardRegistry.all_cards[card_paths[i]]

			if card.has_method("display_info"):
				card.display_info(data)

			card.visible = true
			card.modulate.a = 1.0

			# Deck appearance
			card.scale = Vector2(1.2, 1.2)
			card.position = Vector2(i * 6, i * 5)
			card.rotation_degrees = randf_range(-3.0, 3.0)
			card.z_index = i

			if i == current_idx:
				card.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				card.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			card.visible = false


func _input(event: InputEvent):
	if !visible:
		return

	# Handle opening click if pack is sealed
	if pack_is_sealed:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_animate_pack_opening()
		return # Block card interaction while sealed

	if current_idx >= card_paths.size():
		return

	var current_card = cards_container.get_child(current_idx)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				is_dragging = true
				drag_start_pos = get_global_mouse_position()

			else:
				is_dragging = false
				_handle_drag_end(current_card)

	if event is InputEventMouseMotion and is_dragging:
		var offset = get_global_mouse_position().x - drag_start_pos.x

		current_card.position.x = current_idx * 6 + offset
		current_card.rotation_degrees = offset * 0.05


func _handle_drag_end(card_node):

	var base_x = current_idx * 6
	var base_y = current_idx * 5

	if abs(card_node.position.x - base_x) > swipe_threshold:

		var direction = 1 if card_node.position.x > base_x else -1

		var tween = create_tween()

		tween.tween_property(
			card_node,
			"position:x",
			3000 * direction,
			0.35
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		tween.parallel().tween_property(
			card_node,
			"modulate:a",
			0.0,
			0.25
		)

		tween.tween_callback(_on_card_swiped)

	else:

		var tween = create_tween()

		tween.tween_property(
			card_node,
			"position",
			Vector2(base_x, base_y),
			0.2
		).set_trans(Tween.TRANS_CUBIC)

		tween.parallel().tween_property(
			card_node,
			"rotation_degrees",
			0.0,
			0.2
		)


func _on_card_swiped():

	# Save card
	PlayerProfile.add_card_to_inventory(card_paths[current_idx])

	# Hide old card
	var old_card = cards_container.get_child(current_idx)
	old_card.visible = false
	old_card.process_mode = Node.PROCESS_MODE_DISABLED

	# Move to the next card underneath
	current_idx -= 1

	if current_idx >= 0:
		AudioManager.play_sound_from_path("res://data/SoundData/sfx/slide.wav", false, 0.0)
		var next_card = cards_container.get_child(current_idx)
		next_card.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		_finish_pack()


func _finish_pack():

	var tween = create_tween()

	tween.tween_property(
		self,
		"position:y",
		2000,
		0.6
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	tween.tween_callback(queue_free)
