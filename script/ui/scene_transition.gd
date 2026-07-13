extends CanvasLayer

@onready var color_rect = $ColorRect

const LOADING_SCREEN_SCENE = preload("res://scenes/loading.tscn")

func change_scene_path(target_scene: String):
	var tween = create_tween()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.5)
	AudioManager.stop_bgm(0.5) 
	await tween.finished
	var loading_instance = LOADING_SCREEN_SCENE.instantiate()
	get_tree().root.add_child(loading_instance)
	loading_instance.set_message("Loading...")
	color_rect.modulate.a = 0.0
	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	
	
	loading_instance.close_loading_screen()
	

	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(target_scene: PackedScene):
	var tween = create_tween()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP


	tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.5)
	AudioManager.stop_bgm(0.5) 
	await tween.finished
	
	if typeof(UIManager) != TYPE_NIL and UIManager.current_menu != null:
		UIManager.close_menu()
	

	var loading_instance = LOADING_SCREEN_SCENE.instantiate()
	get_tree().root.add_child(loading_instance)
	loading_instance.set_message("Loading...")
	
	
	color_rect.modulate.a = 0.0
	

	get_tree().change_scene_to_packed(target_scene)
	
	await get_tree().process_frame
	
	
	loading_instance.close_loading_screen()
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
