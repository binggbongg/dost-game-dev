extends Node2D

signal end_turn_pressed

@onready var turn_manager = get_node("../../GameManagers/TurnManager")
@onready var area = $Area2D

var is_disabled

func _ready() -> void:
	if area:
		area.input_event.connect(_on_area_input_event)

func _process(_delta: float) -> void:
	if not turn_manager: return
	
	var is_player_turn = turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION
	
	if is_player_turn and not turn_manager.is_busy:
		is_disabled = false
		self.modulate = Color(1, 1, 1, 1)
	else:
		is_disabled = true
		self.modulate = Color(0.3, 0.3, 0.3, 0.7)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_disabled:
			end_turn_pressed.emit()
