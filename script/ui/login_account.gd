extends Control

@onready var username_input = $Placeholder1/InputUsername
@onready var password_input = $Placeholder2/InputPassword
@onready var login_button = $LoginButton
@onready var register_label = $RegisterLabel
@onready var message_label = $MessageLabel
@export var next_scene: PackedScene
@export var scene: PackedScene

func _ready() -> void:
	if message_label:
		message_label.text = ""
	
	if login_button:
		login_button.pressed.connect(login_user)
	
	if register_label:
		register_label.gui_input.connect(register_user)

func login_user():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if username.is_empty() or password.is_empty():
		update_message("Required fields missing. Try again.")
		return
	
	update_message("Connecting...")
	var result := await Talo.player_auth.login(username, password)
	match result:
		Talo.player_auth.LoginResult.FAILED:
			match Talo.player_auth.last_error.get_code():
				TaloAuthError.ErrorCode.INVALID_CREDENTIALS:
					message_label.text = "Username or passsword is incorrect"
				_:
					message_label.text = Talo.player_auth.last_error.get_string()
		Talo.player_auth.LoginResult.OK:
			message_label.text = "Login successful"
			SceneTransition.change_scene(next_scene)
			UIManager.close_menu()

func register_user(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false:
		print("redirecting to register screen")
		UIManager.open_menu(scene)

func update_message(message):
	if message_label:
		message_label.text = message
