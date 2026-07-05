extends CanvasLayer

signal conversation_finished
signal line_finished

@onready var dialogue_box: Control = $DialogueBox
@onready var text_label: RichTextLabel = $DialogueBox/DialoguePanel/TextLabel 
@onready var name_label: RichTextLabel = $DialogueBox/DialoguePanel/NameLabel # Updated to RichTextLabel
@onready var portrait: TextureRect = $DialogueBox/npc_portrait

var is_active: bool = false
var player_sprite_frames: SpriteFrames 
var gem_portrait: Texture2D            

func _ready() -> void:
	dialogue_box.hide()
	# Ensure BBCode is active on both label containers
	if text_label:
		text_label.bbcode_enabled = true
	if name_label:
		name_label.bbcode_enabled = true

func display_line(speaker: String, text: String) -> void:
	dialogue_box.show()
	
	# --- UNIFIED STYLE SWITCHING ---
	if speaker == "Player":
		# Clean, standard style for the player name
		name_label.text = PlayerProfile.player_name
		
		# Format player thoughts in italics for specific phrases
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
		# Dynamic, glowing text styling for the celestial name and content
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

func play_sequence(dialogue_resource: DialogueResource, title: String) -> void:
	is_active = true
	dialogue_box.show()
	
	var dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, title)
	while dialogue_line != null:
		display_line(dialogue_line.character, dialogue_line.text)
		await line_finished 
		dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, dialogue_line.next_id)
		
	dialogue_box.hide()
	is_active = false
	conversation_finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active: return
	
	var is_action = event.is_action_pressed("ui_accept")
	var is_click = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	
	if is_action or is_click:
		line_finished.emit()
		get_viewport().set_input_as_handled()
