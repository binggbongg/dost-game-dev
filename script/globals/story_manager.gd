extends Node

var ui: CanvasLayer

func play(data: StoryData):
	if not ui:
		var scene = load("res://scenes/ui/StoryUI.tscn")
		ui = scene.instantiate()
		get_tree().root.add_child(ui)
	
	if data.bgm_to_play:
		AudioManager.play_bgm(data.bgm_to_play)
		
	ui.start_sequence(data)
	return ui.sequence_finished # Allows us to 'await' it
