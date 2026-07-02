extends Node

var mechanics_ui: CanvasLayer

func play_tutorial(data_path: String, target_node: Control = null):
	var data: StoryData = load(data_path)

	if mechanics_ui == null:
		var scene = load("res://scenes/story/mechanicsui.tscn")
		mechanics_ui = scene.instantiate()
		get_tree().root.add_child.call_deferred(mechanics_ui)
		await mechanics_ui.ready

	mechanics_ui.start_tutorial(data, target_node)
	mechanics_ui.set_spotlight(target_node)
	# Wait until the tutorial finishes
	await mechanics_ui.finished
