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

# ─── VICTORY UI PRELOAD ───
@export var victory_screen_scene: PackedScene = preload("res://scenes/ui/level_complete.tscn")

signal battle_won

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

	# Connect our victory signal to handle opening the screen setup
	battle_won.connect(_sequence_battle_wrap_up)
	print("CHECKPOINT 0: battle_won connected to _sequence_battle_wrap_up in _ready()")

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

		if combat_arena.has_method("get_enemy"):
			var enemy = combat_arena.get_enemy()
			if enemy and enemy.has_signal("enemy_died"):
				if not enemy.enemy_died.is_connected(_on_enemy_died):
					enemy.enemy_died.connect(_on_enemy_died)
					print("CHECKPOINT: connected enemy_died signal to _on_enemy_died")
	else:
		print("something wrong with combat arena --battle manager")

func _on_enemy_died() -> void:
	print("CHECKPOINT A: _on_enemy_died received signal")
	check_enemy_death()
	print("CHECKPOINT B: check_enemy_death() returned inside _on_enemy_died")

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
	if active_special_card == null: return

	if !mana_manager.spend_mana(active_special_card.card_cost):
		return

	var enemy = combat_arena.get_enemy()
	active_special_card.card_data.apply_effect(PlayerStats, [enemy])

	PlayerInventory.consume_item(active_special_item_id)
	if active_special_card.current_slot:
		card_manager.clear_card_from_slot(active_special_card)
	active_special_card.queue_free()
	active_special_card = null
	active_special_item_id = ""
	player_hand.set_hand_enabled(true)
	card_manager.refresh_hand_interaction()

	# Check death from special items instantly before passing turn
	if check_enemy_death(): return

	turn_manager.end_player_turn()

func cancel_special():
	if active_special_card == null: return
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
		if !slot.card_in_slot: return slot
	return get_child(0)

func _on_end_turn_clicked():
	if turn_manager.is_busy: return
	cancel_special()
	battle_timer.stop()

	if timer_bar: timer_bar.visible = false
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
					if card_manager: card_manager.return_to_hand(card)

			await get_tree().process_frame

			if is_timeout_ending:
				if deck_manager and deck_manager.has_method("redraw_hand"):
					deck_manager.redraw_hand()
				is_timeout_ending = false

			await execute_enemy_turn()

			# Check enemy death at end of turn sequence loops
			if check_enemy_death(): return

			turn_manager.start_player_turn()

		GameEnums.TurnState.PLAYER_ACTION:
			print("player turn")
			# Check death immediately at turn start in case of damage-over-time effects
			if check_enemy_death(): return

			start_player_timer()
			if turn_manager: turn_manager.is_busy = false
			if mana_manager: mana_manager.reset_turn_mana()

			if not is_manually_drawn:
				player_hand.replenish_hand()
			else:
				is_manually_drawn = false

			await get_tree().process_frame
			if card_manager: card_manager.refresh_hand_interaction()

func execute_enemy_turn():
	print("enemy is preparing action")
	battle_timer.one_shot = true
	battle_timer.start(2.0)
	await battle_timer.timeout

	if combat_arena and combat_arena.has_method("get_enemy"):
		var enemy = combat_arena.get_enemy()
		enemy.execute_intent()

	battle_timer.start(0.5)
	await battle_timer.timeout

func start_player_timer():
	PlayerProfile.run_turns += 1
	if battle_timer.timeout.is_connected(_on_player_turn_timeout):
		battle_timer.timeout.disconnect(_on_player_turn_timeout)

	battle_timer.one_shot = true
	battle_timer.timeout.connect(_on_player_turn_timeout)
	battle_timer.start(40.0)

func _on_player_turn_timeout():
	if turn_manager.is_busy and turn_manager.current_state != GameEnums.TurnState.PLAYER_ACTION: return
	is_timeout_ending = true
	turn_manager.is_busy = true

	if battle_timer.timeout.is_connected(_on_player_turn_timeout):
		battle_timer.timeout.disconnect(_on_player_turn_timeout)

	turn_manager.end_player_turn()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if UIManager.current_menu == null and pause_scene:
			UIManager.open_menu(pause_scene)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			if combat_arena and combat_arena.has_method("get_enemy"):
				var enemy = combat_arena.get_enemy()
				if enemy and enemy.has_method("take_damage"):
					print("--- DEBUG: Forcing 10 Damage to Enemy ---")
					enemy.take_damage(10)
					# Intercept debug damage instantly to trigger win criteria check screen
					check_enemy_death()

func check_enemy_death() -> bool:
	if combat_arena and combat_arena.has_method("get_enemy"):
		var enemy = combat_arena.get_enemy()
		if enemy and enemy.get("current_health") <= 0:

			# Halt the entire turn processing system completely
			if turn_manager:
				turn_manager.is_busy = false # UNLOCK UI processing systems so you can click buttons
				turn_manager.current_state = GameEnums.TurnState.GAME_COMPLETE

			# Kill all active turn timing wheels
			battle_timer.stop()
			if battle_timer.timeout.is_connected(_on_player_turn_timeout):
				battle_timer.timeout.disconnect(_on_player_turn_timeout)

			if timer_bar:
				timer_bar.visible = false

			_sequence_battle_wrap_up()
			return true
	return false

func _sequence_battle_wrap_up() -> void:
	if has_node("../PlayerInterface/VictoryScreenNode"):
		return

	var base_max_score = 400000
	var turn_penalty = PlayerProfile.run_turns * 7500
	var damage_penalty = PlayerProfile.run_damage_taken * 250
	var final_score: int = max(50000, base_max_score - turn_penalty - damage_penalty)

	if victory_screen_scene:
		var victory_instance = victory_screen_scene.instantiate()
		victory_instance.name = "VictoryScreenNode"

		var ui_parent = get_node_or_null("../PlayerInterface")
		if ui_parent:
			ui_parent.add_child(victory_instance)
		else:
			get_parent().add_child(victory_instance)

		var current_level_data = PlayerProfile.get_current_level_data()

		victory_instance.initialize_victory_rewards(current_level_data, final_score)

		PlayerProfile.reset_run_counter()
