extends Control

@export var phase1: PackedScene
@export var phase2: PackedScene
@export var phase3: PackedScene

func _ready() -> void:
	if $Buttons/Phase1:
		$Buttons/Phase1.pressed.connect(func(): phase_button_pressed(phase1))
	
	if $Buttons/Phase2:
		$Buttons/Phase2.pressed.connect(func(): phase_button_pressed(phase2))
	
	if$Buttons/Phase3:
		$Buttons/Phase3.pressed.connect(func(): phase_button_pressed(phase3))

func phase_button_pressed(current_phase):
	if current_phase:
		UIManager.open_menu(current_phase)
