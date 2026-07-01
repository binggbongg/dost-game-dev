extends Control

@export var phase1: PackedScene
@export var phase2: PackedScene
@export var phase3: PackedScene

@onready var button1 = $Buttons/Phase1
@onready var button2 = $Buttons/Phase2
@onready var button3 = $Buttons/Phase3
 
func _ready() -> void:
	update_button_locks()
	
	button1.pressed.connect(func(): phase_button_pressed(phase1))
	button2.pressed.connect(func(): phase_button_pressed(phase2))
	button3.pressed.connect(func(): phase_button_pressed(phase3))

func phase_button_pressed(current_phase):
	if current_phase:
		UIManager.open_menu(current_phase)

func update_button_locks():
	var max_unlocked = PlayerProfile.max_unlocked_chapters
	
	button1.disabled = false
	
	if max_unlocked >= 2:
		button2.disabled = false
		button2.modulate = Color(1, 1, 1, 1)
	else:
		button2.disabled = true
		button2.modulate = Color(0.3, 0.3, 0.3, 0.9)
	
	if max_unlocked == 3:
		button3.disabled = false
		button3.modulate = Color(1, 1, 1, 1)
	else:
		button3.disabled = true
		button3.modulate = Color(0.3, 0.3, 0.3, 0.9)
