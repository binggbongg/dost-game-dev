extends CanvasLayer

class_name CustomLoadingScreen

@onready var loading_text: Label = $LoadingText

func _ready() -> void:
	pass
	# Start spinner animation if you have one
	#if spinner and spinner.sprite_frames.has_animation("spin"):
		#spinner.play("spin")

## Call this to dynamically change what the loading bar says
func set_message(text: String) -> void:
	if is_instance_valid(loading_text):
		loading_text.text = text

### Fades out the loading screen smoothly and frees it from memory
func close_loading_screen() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.4)
	fade_tween.tween_callback(func():
		queue_free()
	)
