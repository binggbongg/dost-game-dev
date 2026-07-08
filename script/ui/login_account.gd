extends Control

@onready var username_input = $Placeholder1/InputUsername
@onready var password_input = $Placeholder2/InputPassword
@onready var login_button = $LoginButton
@onready var register_label = $RegisterLabel
@onready var message_label = $MessageLabel
@onready var register_scene: PackedScene = load("res://scenes/menus/register_account.tscn")

const LOADING_SCREEN_SCENE = preload("res://scenes/loading.tscn")

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
	var loading_instance = LOADING_SCREEN_SCENE.instantiate()
	get_tree().root.add_child(loading_instance)
	
	if loading_instance.has_method("set_message"):
		loading_instance.set_message("Authenticating credentials...")
	
	var result = await Talo.player_auth.login(username, password)
	match result:
		Talo.player_auth.LoginResult.FAILED:
			loading_instance.queue_free()
			match Talo.player_auth.last_error.get_code():
				TaloAuthError.ErrorCode.INVALID_CREDENTIALS:
					message_label.text = "Username or passsword is incorrect"
				_:
					message_label.text = Talo.player_auth.last_error.get_string()
		Talo.player_auth.LoginResult.OK:
			message_label.text = "Login successful"
			
			if loading_instance.has_method("set_message"):
				loading_instance.set_message("Downloading cloud save data...")
			
			if typeof(SaveManager) != TYPE_NIL and SaveManager.has_method("sync_with_cloud"):
				await SaveManager.sync_with_cloud()
			
			if loading_instance.has_method("close_loading_screen"):
				loading_instance.close_loading_screen()
			else:
				loading_instance.queue_free()
			
			var main_menu = get_tree().current_scene
			if main_menu and main_menu.has_method("check_player_history"):
				main_menu.update_settings_button_state() # Lock the login gear icon
				main_menu.check_player_history()          # Refresh the Play/Continue status
			
			UIManager.close_menu()

func register_user(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed == false:
		print("redirecting to register screen")
		if register_scene:
			UIManager.close_menu()
			UIManager.open_menu(register_scene)

func update_message(message):
	if message_label:
		message_label.text = message
