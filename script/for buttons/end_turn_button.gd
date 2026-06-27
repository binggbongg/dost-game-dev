extends TextureButton

signal end_turn_pressed

@onready var turn_manager = get_node("../../GameManagers/TurnManager")

func _ready() -> void:
	self.pressed.connect(_on_pressed)

func _process(_delta: float) -> void:
	if not turn_manager: return
	
	var is_player_turn = turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION
	
	if is_player_turn and not turn_manager.is_busy:
		self.disabled = false
		self_modulate = Color(1, 1, 1, 1)
	else:
		self.disabled = true
		self_modulate = Color(0.3, 0.3, 0.3, 0.8)

func _on_pressed():
	BattleEvents.special_end_turn_requested.emit()
	print("End Turn Button Physically Clicked!")
	end_turn_pressed.emit()
