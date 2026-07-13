extends CanvasLayer

class_name CustomLoadingScreen

@onready var loading_text: Label = $LoadingText

# Keep track of the typewriter loop so we can stop it on close
var typewriter_tween: Tween

func _ready() -> void:
	# Locate background for intro fade
	var background_node = get_node_or_null("Background")
	if is_instance_valid(background_node):
		background_node.modulate.a = 0.0
		var intro_tween = create_tween()
		intro_tween.tween_property(background_node, "modulate:a", 1.0, 0.3)
	
	# Start the professional typewriter animation loop
	start_typewriter_loop()

## Call this to dynamically change what the loading bar says
func set_message(text: String) -> void:
	if is_instance_valid(loading_text):
		loading_text.text = text
		# Restart loop with new text length if text updates mid-load
		start_typewriter_loop()

## Creates a continuous typewriter in-and-out loop
func start_typewriter_loop() -> void:
	if not is_instance_valid(loading_text) or loading_text.text.is_empty():
		return
		
	if typewriter_tween:
		typewriter_tween.kill()
		
	typewriter_tween = create_tween().set_loops()
	
	# 1. Type Write In
	loading_text.visible_characters = 0
	typewriter_tween.tween_property(loading_text, "visible_characters", loading_text.text.length(), 1.5)
	typewriter_tween.tween_interval(1.0) # Pause while fully visible
	
	# 2. Type Write Out (Erase)
	typewriter_tween.tween_property(loading_text, "visible_characters", 0, 1.0)
	typewriter_tween.tween_interval(0.5) # Pause while fully hidden

### Fades out the loading screen smoothly and frees it from memory
func close_loading_screen() -> void:
	print("[LOADING] Cloud sync complete. Fading out loading screen.")
	
	# Stop the text animation loop cleanly
	if typewriter_tween:
		typewriter_tween.kill()
	
	# Locate the ColorRect background node safely
	var background_node = get_node_or_null("Background")
	
	if is_instance_valid(background_node):
		var fade_tween = create_tween()
		# 🌟 FIX: Tween the modulate property of the background item, NOT the CanvasLayer root!
		fade_tween.tween_property(background_node, "modulate:a", 0.0, 0.4)
		fade_tween.tween_callback(func():
			queue_free()
		)
	else:
		# Fallback if the scene node structure doesn't match
		queue_free()
