extends Node

var mechanics_ui: CanvasLayer

func play_tutorial(data_path: String, target_node: CanvasItem = null):
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

func play_group_tutorial(data_path: String, targets: Array):
	var data: StoryData = load(data_path)
	if mechanics_ui == null:
		var scene = load("res://scenes/story/mechanicsui.tscn")
		mechanics_ui = scene.instantiate()
		get_tree().root.add_child.call_deferred(mechanics_ui)
		await mechanics_ui.ready
	mechanics_ui.start_group_tutorial(data, targets)
	await mechanics_ui.finished

func play_card_pack_tutorial(data_path: String, pack: Control):
	var data: StoryData = load(data_path)

	if mechanics_ui == null:
		var scene = load("res://scenes/story/mechanicsui.tscn")
		mechanics_ui = scene.instantiate()
		get_tree().root.add_child.call_deferred(mechanics_ui)
		await mechanics_ui.ready

	await mechanics_ui.start_card_pack_tutorial(data, pack)
	await mechanics_ui.finished
