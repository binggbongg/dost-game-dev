extends CanvasLayer

signal conversation_finished
signal line_finished

@onready var dialogue_box: Control = $DialogueBox
@onready var text_label: RichTextLabel = $DialogueBox/DialoguePanel/TextLabel 
@onready var name_label: RichTextLabel = $DialogueBox/DialoguePanel/NameLabel
@onready var portrait: TextureRect = $DialogueBox/npc_portrait
@onready var next: RichTextLabel = $DialogueBox/DialoguePanel/Next

var is_active: bool = false
var player_sprite_frames: SpriteFrames 
var gem_portrait: Texture2D            

# Keeps track of the active typewriter tween so we can cancel it if needed
var typewriter_tween: Tween

func _ready() -> void:
	dialogue_box.hide()
	if next:
		next.hide()
		
	if text_label:
		text_label.bbcode_enabled = true
		text_label.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	if name_label:
		name_label.bbcode_enabled = true
		
	_load_star_fragment_portrait()

func _load_star_fragment_portrait() -> void:
	var chapter_num = PlayerProfile.selected_chapter
	var fragment_path = "res://data/StarFragments/chapter_%d.tres" % chapter_num
	
	if ResourceLoader.exists(fragment_path):
		var fragment_resource = load(fragment_path)
		if fragment_resource and "illustration" in fragment_resource:
			gem_portrait = fragment_resource.illustration
			print("[Dialogue] Successfully loaded Star Fragment portrait for Chapter: ", chapter_num)
		else:
			print("[Warning] Star Fragment resource loaded, but is missing an 'illustration' property.")
	else:
		print("[Warning] Star Fragment resource path not found: ", fragment_path)

func display_line(speaker: String, text: String) -> void:
	dialogue_box.show()
	
	if next:
		next.hide()
	
	if typewriter_tween:
		typewriter_tween.kill()
	
	# --- UNIFIED STYLE SWITCHING ---
	if speaker == "Player":
		name_label.text = PlayerProfile.player_name
		
		if text.contains("?") or text.contains("...") or text.contains("Let's move"):
			text_label.text = "[i]" + text + "[/i]"
		else:
			text_label.text = text
			
		if player_sprite_frames and player_sprite_frames.has_animation("portrait"):
			portrait.texture = player_sprite_frames.get_frame_texture("portrait", 0)
			portrait.show()
		else:
			portrait.hide()
			
	elif speaker == "Star Fragment" or speaker == "Araw":
		name_label.text = "[color=#ffe6f2][b]" + speaker + "[/b][/color]"
		text_label.text = "[color=#ffffff][b]" + text + "[/b][/color]"
		
		if gem_portrait:
			portrait.texture = gem_portrait
			portrait.show()
		else:
			portrait.hide()
	else:
		name_label.text = speaker
		text_label.text = text
		portrait.hide()

	# --- TYPEWRITER ANIMATION LOGIC ---
	text_label.visible_characters = 0
	var total_chars = text_label.get_total_character_count()
	var duration = total_chars * 0.03
	
	typewriter_tween = create_tween()
	typewriter_tween.tween_property(text_label, "visible_characters", total_chars, duration)
	typewriter_tween.finished.connect(func(): if next: next.show())

func play_sequence(dialogue_resource: DialogueResource, title: String) -> void:
	is_active = true
	dialogue_box.show()
	
	var dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, title)
	while dialogue_line != null:
		# 🛠️ FIX: If the skip button turned off dialogue processing, break the loop immediately!
		if not is_active: 
			break
			
		display_line(dialogue_line.character, dialogue_line.text)
		await line_finished 
		
		if not is_active: 
			break
			
		dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, dialogue_line.next_id)
		
	dialogue_box.hide()
	if next:
		next.hide()
	is_active = false
	conversation_finished.emit()


func _input(event: InputEvent) -> void:
	# If the cutscene is currently running skip logic, completely block text progression inputs!
	if not is_active: return
	
	var is_action = event.is_action_pressed("ui_accept")
	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	
	if is_action or is_click:
		# 🛠️ FIX: Check if the mouse click is hitting a UI button like Skip. 
		# If it is, let the button handle it instead of advancing text!
		var clicked_control = get_viewport().gui_get_focus_owner()
		if is_click and clicked_control and clicked_control is BaseButton:
			return 

		if text_label.visible_characters < text_label.get_total_character_count():
			if typewriter_tween:
				typewriter_tween.kill()
			text_label.visible_characters = text_label.get_total_character_count()
			if next:
				next.show()
		else:
			if next:
				next.hide()
			line_finished.emit()
			
		get_viewport().set_input_as_handled()
		
