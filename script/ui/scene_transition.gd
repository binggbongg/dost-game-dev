extends CanvasLayer

@onready var color_rect = $ColorRect
@export var loading_screen_scene: PackedScene = preload("res://scenes/loading.tscn")

#func change_scene_path(target_scene: String):
	#var tween = create_tween()
	#color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	#tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.5)
	#AudioManager.stop_bgm(0.5) 
	#await tween.finished
	#
	#var loading_instance: CustomLoadingScreen = null
	#if  and loading_screen_scene:
		#loading_instance = loading_screen_scene.instantiate() as CustomLoadingScreen
		#get_tree().root.add_child(loading_instance)
		#loading_instance.set_message("Synchronizing cloud data...")
	#
	#get_tree().change_scene_to_file(target_scene)
	#
	#var tween_in = create_tween()
	#tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	#
	#await tween_in.finished
	#color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
#
#func change_scene(target_scene: PackedScene):
	#var tween = create_tween()
	#color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
#
	#tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.5)
	#AudioManager.stop_bgm(0.5) 
	#await tween.finished
	#
	#if typeof(UIManager) != TYPE_NIL and UIManager.current_menu != null:
		#UIManager.close_menu()
	#
	#get_tree().change_scene_to_packed(target_scene)
	#
	#var tween_in = create_tween()
	#tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	#
	#await tween_in.finished
	#color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func change_scene_path(target_scene: String, requires_cloud_sync: bool = false):
	var tween = create_tween()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.5)
	AudioManager.stop_bgm(0.5) 
	await tween.finished
	
	var loading_instance: CustomLoadingScreen = null
	if requires_cloud_sync and loading_screen_scene:
		loading_instance = loading_screen_scene.instantiate() as CustomLoadingScreen
		get_tree().root.add_child(loading_instance)
		loading_instance.set_message("Synchronizing cloud data...")
	
	get_tree().change_scene_to_file(target_scene)
	
	await get_tree().process_frame
	
	if is_instance_valid(loading_instance):
		loading_instance.close_loading_screen()
		await get_tree().create_timer(0.4).timeout
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	await tween_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func change_scene(target_scene: PackedScene, requires_cloud_sync: bool = false):
	var tween = create_tween()
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	tween.parallel().tween_property(color_rect, "modulate:a", 1.0, 0.5)
	AudioManager.stop_bgm(0.5) 
	await tween.finished
	
	if typeof(UIManager) != TYPE_NIL and UIManager.current_menu != null:
		UIManager.close_menu()
		
	var loading_instance: CustomLoadingScreen = null
	if requires_cloud_sync and loading_screen_scene:
		loading_instance = loading_screen_scene.instantiate() as CustomLoadingScreen
		get_tree().root.add_child(loading_instance)
		loading_instance.set_message("Loading battle parameters...")
	
	get_tree().change_scene_to_packed(target_scene)
	
	await get_tree().process_frame
	
	if is_instance_valid(loading_instance):
		loading_instance.close_loading_screen()
		await get_tree().create_timer(0.4).timeout
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	await tween_in.finished
	
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
