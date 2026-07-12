extends Label

@export var character_delay: float = 0.08  # Time in seconds between each letter
@export var show_duration: float = 2.0    # How long the full text stays on screen before restarting

var total_characters: int = 0
var loop_tween: Tween

func _ready() -> void:
	# Save the full string and start the typewriter effect
	total_characters = text.length()
	visible_characters = 0
	start_typewriter_loop()

func _notification(what: int) -> void:
	# Automatically controls the loop when the SpellbookManager shows/hides this label
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_visible_in_tree():
			start_typewriter_loop()
		else:
			stop_typewriter_loop()

func start_typewriter_loop() -> void:
	stop_typewriter_loop()
	
	visible_characters = 0
	loop_tween = create_tween().set_loops()
	
	# Animate the number of visible characters from 0 to the full length of your text
	loop_tween.tween_property(self, "visible_characters", total_characters, character_delay * total_characters)\
		.set_trans(Tween.TRANS_LINEAR)
		
	# Wait at the end so the player can read the full text
	loop_tween.tween_interval(show_duration)
	
	# Instantly reset to 0 characters visible right before the loop restarts
	loop_tween.tween_callback(func(): visible_characters = 0)

func stop_typewriter_loop() -> void:
	if loop_tween and loop_tween.is_valid():
		loop_tween.kill()
	visible_characters = -1 # Resets the label to reveal all text normally if disabled
