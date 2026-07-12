extends CanvasLayer

# UI References (matched to your scene tree)
@onready var score_label: Label = $VICTORY/ScoreLabel
@onready var next_button: TextureButton = $VICTORY/next
@onready var coin_reward_label: Label = $VICTORY/CoinLabel

@onready var pack_layer: CanvasLayer = $PackLayer
@export var pack_scene: PackedScene                               # Assign your card pack .tscn here

# Updated Card Pack References
@onready var card_pack: Control = $VICTORY/CardPack
@onready var card_label: Label = $VICTORY/CardPack/CardLabel
@onready var texture_rect_4: TextureRect = $VICTORY/CardPack/TextureRect4
@onready var texture_rect_5: TextureRect = $VICTORY/CardPack/TextureRect5
@onready var texture_rect_6: TextureRect = $VICTORY/CardPack/TextureRect6
@onready var texture_rect_7: TextureRect = $VICTORY/CardPack/TextureRect7

# Internal logic data cache
var cached_coins_earned := 0
var cached_packs_earned := 0
var level_data_ref: LevelData = null

var final_score_to_display: int = 0

func _ready() -> void:
	layer = 100
	next_button.pressed.connect(_on_next_pressed)

	var reward_panel = get_node_or_null("VICTORY/ColorRect")
	if reward_panel is Control:
		reward_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		reward_panel.pivot_offset = reward_panel.size / 2.0
	
	update_ui_text_displays()

func initialize_victory_rewards(level_data: LevelData, score: int, final_rank: String) -> void:
	visible = true
	$VICTORY.visible = true
	level_data_ref = level_data

	final_score_to_display = score

	var level_key = "level_" + str(level_data.phase_number) + "-" + str(level_data.level_number) if level_data else "custom"
	var is_new_high_score = PlayerProfile.update_high_score(level_key, score)

	var minimum_reward_threshold = 700
	var qualifies_for_rewards = is_new_high_score or (score >= minimum_reward_threshold)

	# Determine if this is a boss level (Level 3)
	var is_boss = level_data and (level_data.is_boss_level or level_data.level_number == 3)

	if not qualifies_for_rewards:
		cached_coins_earned = 0
		# Boss levels should ALWAYS give a card pack, even if score threshold isn't met
		cached_packs_earned = 1 if is_boss else 0
	else:
		if level_data and level_data.is_boss_level:
			var boss_ratio: float = float(score) / 2500.0
			cached_coins_earned = int(clamp(boss_ratio * 200, 50, 250))
		else:
			var minion_ratio: float = float(score) / 1500.0
			cached_coins_earned = int(clamp(minion_ratio * 50, 15, 75))

		if is_boss:
			cached_packs_earned = 1
		else:
			cached_packs_earned = 0

	# Add earned coins to profile immediately
	PlayerProfile.add_coins(cached_coins_earned)
	SaveManager.save_game()

	# Adjust positioning and visibility of elements
	adjust_rewards_layout()
	update_ui_text_displays()

func adjust_rewards_layout() -> void:
	if cached_packs_earned == 0:
		# Hide the card pack elements completely using the correct container reference
		if card_pack:
			card_pack.visible = false
			
		# Center the coin label horizontally and lower it significantly to line up perfectly with the icon's row
		if coin_reward_label:
			coin_reward_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
			coin_reward_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
			coin_reward_label.grow_vertical = Control.GROW_DIRECTION_BOTH
			coin_reward_label.position.y += 50.0 # Increased offset to lower the text directly level with the coin icon
	else:
		# Show the correct card pack UI panel on boss levels
		if card_pack:
			card_pack.visible = true

## Sequence controller running the box disappearance and pack animations loop
func _on_next_pressed() -> void:
	next_button.disabled = true

	# 1. Hide the Victory window elements so they don't block the screen during pack openings
	var hide_tween = create_tween()
	hide_tween.tween_property($VICTORY, "modulate:a", 0.0, 0.3)
	hide_tween.tween_callback(func(): $VICTORY.visible = false)
	await hide_tween.finished

	if cached_packs_earned > 0 and pack_scene:
		# Dynamically ensure a valid, visible PackLayer exists so the pack shows over everything
		if not pack_layer:
			pack_layer = get_node_or_null("PackLayer")
			if not pack_layer:
				pack_layer = CanvasLayer.new()
				pack_layer.name = "PackLayer"
				pack_layer.layer = 105 # Higher layer priority
				add_child(pack_layer)
		
		pack_layer.visible = true
		var pack_instance = pack_scene.instantiate()
		pack_layer.add_child(pack_instance)
		pack_instance.open_pack(false)
		await pack_instance.tree_exited
		SaveManager.save_game()

	# 3. ROUTING: Now that all card packs are opened and closed, transition out!
	_finish_and_transition_scene()

func update_ui_text_displays():
	if is_instance_valid(score_label):
		score_label.text = str(final_score_to_display)
	if is_instance_valid(coin_reward_label):
		coin_reward_label.text = str(cached_coins_earned)
	if is_instance_valid(card_label):
		card_label.text = str(cached_packs_earned)

func _finish_and_transition_scene() -> void:
	if level_data_ref and (level_data_ref.is_boss_level or level_data_ref.level_number == 3):
		print("[ROUTE] Boss clear complete. Moving back to overall lounge interface.")
		#SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
		SceneTransition.change_scene(level_data_ref.post_boss_cutscene)
	else:
		print("[ROUTE] Minion clear complete. Redirecting straight to Deck Builder scene layout.")
		SceneTransition.change_scene_path("res://scenes/ui/DeckBuilder.tscn")
		
	queue_free()
