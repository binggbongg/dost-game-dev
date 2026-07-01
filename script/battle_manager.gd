extends Node2D

@onready var battle_timer = $"../Timer"
@onready var combat_arena = $"../CombatArena"
@onready var turn_manager = $"../PlayerInterface/GameManagers/TurnManager"
@onready var player_hand = $"../PlayerInterface/GameManagers/PlayerHand"
@onready var card_manager = $"../PlayerInterface/GameManagers/CardManager"
@onready var end_turn = $"../PlayerInterface/UI/EndTurn"
@onready var deck_manager = $"../PlayerInterface/GameManagers/DeckManager"
@onready var combo_manager = $"../PlayerInterface/GameManagers/ComboManager"
@onready var mana_manager = $"../PlayerInterface/GameManagers/ManaManager"
@onready var slots: Node2D = $"../PlayerInterface/Slots"
@onready var timer_bar = $"../TimerBar"
@onready var battle_background = $"../UpperBackground"

var active_special_card : Card = null
var active_special_item_id := ""
var is_timeout_ending: bool = false
var is_manually_drawn: bool = false

@export var card_scene: PackedScene = preload("res://scenes/card.tscn")
@export var pause_scene = preload("res://scenes/menus/pause_menu.tscn")

signal battle_won

# angela ay ni hilabti tanan
# chat all i can say is it all worked on my end but if mu crash...HIHIHI

func _ready() -> void:
	BattleEvents.special_card_requested.connect(_on_special_requested)
	BattleEvents.special_cancel_requested.connect(_on_special_cancel)
	BattleEvents.special_shuffle_requested.connect(_on_special_shuffle)
	BattleEvents.special_cast_requested.connect(_on_special_cast)
	BattleEvents.special_end_turn_requested.connect(_on_special_end_turn)
	print("BattleManager connected special_cast_requested")
	
	if turn_manager:
		turn_manager.turn_changed.connect(_on_turned_state_changed)
		print("battle manager connected to turn manager")
	
	if end_turn:
		end_turn.end_turn_pressed.connect(_on_end_turn_clicked)

func _process(_delta: float) -> void:
	if not turn_manager or not battle_timer or not timer_bar: return
	if turn_manager.current_state == GameEnums.TurnState.PLAYER_ACTION and not battle_timer.is_stopped():
		var seconds_left = ceil(battle_timer.time_left)
		
		timer_bar.visible = true
		timer_bar.value = seconds_left
		
		var timer_label = timer_bar.get_node_or_null("TimeText")
		if timer_label:
			timer_label.text = str(seconds_left) + " s"
	else:
		timer_bar.visible = false
		timer_bar.value = 0

func setup_enemy(enemy_resource: EnemyBehavior) -> void:
	if not enemy_resource:
		print("Received null enemy resource --from battlemanager")
	
	if combat_arena and combat_arena.has_method("initialize_arena_enemy"):
		combat_arena.initialize_arena_enemy(enemy_resource)
	else:
		print("something wrong with combat arena --battle manager")

func _on_special_requested(item_id:String):
	if active_special_card != null:
		cancel_special()
	
	var data = ItemDb.get_item(item_id)
	if data == null:
		print("Special not found.")
		return
	
	create_special_card(data, item_id)

func _on_special_cancel():
	cancel_special()

func _on_special_shuffle():
	cancel_special()

func _on_special_end_turn():
	cancel_special()

func _on_special_cast():
	print("===== SPECIAL CAST =====")
	print("active_special_card:", active_special_card)
	if active_special_card == null:
		print("active_special_card IS NULL")
		return
	print("Mana Cost:", active_special_card.card_cost)
	print("Current Mana:", mana_manager.current_mana)
	if !mana_manager.spend_mana(active_special_card.card_cost):
		print("FAILED TO SPEND MANA")
		return
	print("Mana spent successfully")
	var enemy = combat_arena.get_enemy()
	print("Enemy:", enemy)
	print("Applying special effect")
	active_special_card.card_data.apply_effect(
		PlayerStats,
		[enemy]
	)
	print("Effect finished")
	PlayerInventory.consume_item(active_special_item_id)
	if active_special_card.current_slot:
		card_manager.clear_card_from_slot(active_special_card)
	active_special_card.queue_free()
	active_special_card = null
	active_special_item_id = ""
	player_hand.set_hand_enabled(true)
	card_manager.refresh_hand_interaction()
	turn_manager.end_player_turn()
	
func cancel_special():
	if active_special_card == null:
		return
	if active_special_card.current_slot:
		card_manager.clear_card_from_slot(active_special_card)
	active_special_card.queue_free()
	active_special_card = null
	active_special_item_id = ""
	player_hand.set_hand_enabled(true)

	card_manager.refresh_hand_interaction()
func create_special_card(data:SpecialCardData, item_id:String):
	active_special_item_id = item_id
	var card = card_scene.instantiate()
	card.card_data = data
	add_child(card)
	active_special_card = card
	card_manager.connect_card_signal(card)
	place_special_into_slot(card)
	player_hand.set_hand_enabled(false)

func place_special_into_slot(card: Card):
	for normal in combo_manager.get_cards_in_slots():
		card_manager.return_to_hand(normal)
	var slot = slots.get_child(0)
	card.global_position = slot.global_position
	card.position = slot.position
	card.location = GameEnums.Location.SLOT
	card.current_slot = slot
	slot.card_in_slot = true
	card.can_drag = false
	card.z_index = 10
	
func get_first_available_slot() -> Node:
	for slot in get_children():
		if !slot.card_in_slot:
			return slot
	return get_child(0)
	
func _on_end_turn_clicked():
	if turn_manager.is_busy: return
	
	cancel_special()
	battle_timer.stop()
	
	if timer_bar:
		timer_bar.visible = false
	
	if battle_timer.timeout.is_connected(_on_player_turn_timeout):
		battle_timer.timeout.disconnect(_on_player_turn_timeout)
	
	turn_manager.end_player_turn()

func _on_turned_state_changed(new_state: GameEnums.TurnState):
	match new_state:
		GameEnums.TurnState.ENEMY_TURN:
			print("enemy turn")
			
			battle_timer.stop()
			if battle_timer.timeout.is_connected(_on_player_turn_timeout):
				battle_timer.timeout.disconnect(_on_player_turn_timeout)
			
			if combo_manager:
				var active_cards = combo_manager.get_cards_in_slots()
				for card in active_cards:
					if card_manager:
						card_manager.return_to_hand(card)
			
			await get_tree().process_frame
			
			if is_timeout_ending:
				if deck_manager and deck_manager.has_method("redraw_hand"):
					print("timer ran out. redrawing cards..")
					deck_manager.redraw_hand()
				is_timeout_ending = false
			
			await execute_enemy_turn()
			
			var enemy = combat_arena.get_enemy()
			if enemy and enemy.get("current_health") <= 0:
				battle_won.emit()
				return
			
			turn_manager.start_player_turn()
		GameEnums.TurnState.PLAYER_ACTION:
			print("player turn")
			start_player_timer()
			
			if turn_manager: turn_manager.is_busy = false
			if mana_manager: mana_manager.reset_turn_mana()
			
			if not is_manually_drawn:
				player_hand.replenish_hand()
			else:
				is_manually_drawn = false
			
			await get_tree().process_frame
			if card_manager:
				card_manager.refresh_hand_interaction()

func execute_enemy_turn():
	print("enemy is preparing action")
	battle_timer.one_shot = true
	battle_timer.start(2.0)
	await battle_timer.timeout
	
	if combat_arena and combat_arena.has_method("get_enemy"):
		var enemy = combat_arena.get_enemy()
		enemy.execute_intent()
	else:
		print("execute intent method did not work or did not find enemy -- from battlemanager")
	
	battle_timer.start(0.5)
	await battle_timer.timeout

func start_player_timer():
	if battle_timer.timeout.is_connected(_on_player_turn_timeout):
		battle_timer.timeout.disconnect(_on_player_turn_timeout)
	
	battle_timer.one_shot = true
	battle_timer.timeout.connect(_on_player_turn_timeout)
	battle_timer.start(40.0)
	print("timer of 40 seconds started.")

func _on_player_turn_timeout():
	if turn_manager.is_busy and turn_manager.current_state != GameEnums.TurnState.PLAYER_ACTION:
		return
	
	print("player time ended. switching to enemy turn")
	is_timeout_ending = true
	turn_manager.is_busy = true
	
	if battle_timer.timeout.is_connected(_on_player_turn_timeout):
		battle_timer.timeout.disconnect(_on_player_turn_timeout)
	
	turn_manager.end_player_turn()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if UIManager.current_menu == null and pause_scene:
			UIManager.open_menu(pause_scene)
		else:
			print("Could not open pause screen -- from battlemanager")
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R: # Pressing the 'D' key on your keyboard
			if combat_arena and combat_arena.has_method("get_enemy"):
				var enemy = combat_arena.get_enemy()
				if enemy and enemy.has_method("take_damage"):
					print("--- DEBUG: Forcing 10 Damage to Enemy ---")
					enemy.take_damage(10)
