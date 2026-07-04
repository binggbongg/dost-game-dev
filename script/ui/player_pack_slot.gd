extends Control

@onready var cards_container = $Cards 
var card_paths: Array[String] = []
var current_idx = 0

var is_dragging = false
var drag_start_pos = Vector2.ZERO
var swipe_threshold = 100 # How far to drag before it triggers swipe
func _ready():
	# Force this node to be the size of the screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Center the $Cards node based on the screen size
	$Cards.position = get_viewport_rect().size / 2
	
	self.scale = Vector2.ZERO
	self.visible = false
	self.pivot_offset = get_viewport_rect().size / 2

func setup_cards():
	var nodes = cards_container.get_children()
	for i in range(nodes.size()):
		if i < card_paths.size():
			var data = CardRegistry.all_cards[card_paths[i]]
			nodes[i].display_info(data) 
			
			# Ensure card is BIG (Battle cards are usually small 0.16)
			nodes[i].scale = Vector2(1.2, 1.2) 
			
			# Center the card inside the $Cards container
			nodes[i].position = Vector2.ZERO 
			nodes[i].rotation = 0
			nodes[i].visible = (i == 0)

func open_pack(is_new_player: bool):
	card_paths = CardRegistry.generate_pack_paths(is_new_player)
	current_idx = 0
	setup_cards()
	
	self.visible = true
	var tween = create_tween()
	# Pop in from center
	tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _input(event):
	if not visible or current_idx >= 5: return
	
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
		current_card.position.x = offset
		# Tilt the card as it drags
		current_card.rotation_degrees = offset * 0.05 
func _handle_drag_end(card):
	if abs(card.position.x) > swipe_threshold:
		var direction = 1 if card.position.x > 0 else -1
		var tween = create_tween()
		# Fly far away (3000 pixels is safe for any screen)
		var target_x = 3000 * direction
		tween.tween_property(card, "position:x", target_x, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# Hide the card as it flies away so it doesn't block the next one
		tween.parallel().tween_property(card, "modulate:a", 0, 0.3)
		tween.tween_callback(_on_card_swiped)
	else:
		var tween = create_tween()
		tween.tween_property(card, "position", Vector2.ZERO, 0.2)
		tween.parallel().tween_property(card, "rotation", 0, 0.2)

func _on_card_swiped():
	PlayerProfile.add_card_to_inventory(card_paths[current_idx])
	
	# Disable the old card completely
	var old_card = cards_container.get_child(current_idx)
	old_card.visible = false
	old_card.process_mode = Node.PROCESS_MODE_DISABLED 
	
	current_idx += 1
	if current_idx < 5:
		var next_card = cards_container.get_child(current_idx)
		next_card.visible = true
		next_card.modulate.a = 0
		next_card.position = Vector2(0, -100) # Slide in from top
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(next_card, "modulate:a", 1.0, 0.3)
		tween.tween_property(next_card, "position:y", 0, 0.3).set_trans(Tween.TRANS_BACK)
	else:
		_finish_pack()
func _finish_pack():
	# Slide the pack down off-screen
	var tween = create_tween()
	tween.tween_property(self, "position:y", 2000, 0.6).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(queue_free)
