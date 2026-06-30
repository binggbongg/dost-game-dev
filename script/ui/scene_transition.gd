extends CanvasLayer

@onready var color_rect = $ColorRect

func change_scene(target_scene: PackedScene):
	var tween = create_tween()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.5)
	AudioManager.stop_bgm(0.5) 
	await tween.finished
	
	get_tree().change_scene_to_packed(target_scene)
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	
	await tween_in.finished
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
