extends CanvasLayer

signal finished

@onready var dimmer = $Dimmer # This is a Control/ColorRect, so it HAS modulate
@onready var label = $TextLabel2

func _ready():
	# 1. Start the BACKGROUND invisible (this affects children too)
	dimmer.modulate.a = 0
	label.text = "Battle Tutorial Complete!\nClick anywhere to begin your journey."
	
	# 2. Fade In the Dimmer
	var tween = create_tween()
	# We target 'dimmer' specifically instead of 'self'
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

func _input(event):
	# Detect click or keypress
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		# Prevent double-clicking
		set_process_input(false) 
		
		# 3. Fade Out the Dimmer
		var tween = create_tween()
		tween.tween_property(dimmer, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
		
		await tween.finished
		finished.emit()
		queue_free()
