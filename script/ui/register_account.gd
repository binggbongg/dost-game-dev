extends Control

@onready var username = $Placeholder1/InputUsername
@onready var password = $Placeholder2/InputPassword
@onready var confirm_pass = $Placeholder2/Placeholder3/InputCPass
@onready var message_label = $MessageLabel
@onready var register_button = $RegisterButton
@export var next_scene: PackedScene

func _ready() -> void:
	if message_label:
		message_label.text = ""
	register_button.pressed.connect(register_user)

func register_user():
	if username.text.is_empty() or password.text.is_empty() or confirm_pass.text.is_empty():
		message_label.text = "Required fields cannot be empty."
		return
	
	if confirm_pass.text.strip_edges() != password.text.strip_edges():
		message_label.text = "Passwords do not match. Try Again."
		return
	
	var result := await Talo.player_auth.register(username.text.strip_edges(), password.text.strip_edges())
	if result != OK:
		match Talo.player_auth.last_error.get_code():
			TaloAuthError.ErrorCode.IDENTIFIER_TAKEN:
				message_label.text = "Username is already taken"
			_:
				message_label.text = Talo.player_auth.last_error.get_string()
	
	message_label.text = "Registration successful"
	SceneTransition.change_scene(next_scene)
	UIManager.close_menu()
