extends Control

@onready var logout_button = $LogoutButton
@onready var message_label = $MessageLabel
@export var menu: PackedScene

func _ready() -> void:
	if logout_button:
		logout_button.pressed.connect(_on_logout_button_pressed)

func _on_logout_button_pressed():
	var res = await Talo.player_auth.logout()
	if res == OK:
		print("MainMenu: Logout successful.")
		
		# 2. Reset your local singletons so a new account doesn't inherit dirty variables
		if typeof(PlayerProfile) != TYPE_NIL:
			PlayerProfile.is_profile_initialized = false
			PlayerProfile.high_scores.clear()
			PlayerProfile.owned_cards = []
		
		if typeof(PlayerInventory) != TYPE_NIL:
			PlayerInventory.owned_items = {}
			PlayerInventory.inventory_changed.emit()
		
		# 3. Cleanly force the login menu overlay back onto the screen
		if typeof(UIManager) != TYPE_NIL and menu:
			UIManager.open_menu(menu)
			
	else:
		print("Error: Failed to process backend account logout.")
