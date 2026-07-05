extends CanvasLayer
# UI References (matched to your scene tree)
@onready var score_label: Label = $VICTORY/ScoreLabel
@onready var next_button: TextureButton = $VICTORY/next
@onready var pack_reward_label: Label = $VICTORY/Control/CardLabel
@onready var coin_reward_label: Label = $VICTORY/CoinLabel

@onready var pack_layer: CanvasLayer = $PackLayer
@export var pack_scene: PackedScene                           # Assign your card pack .tscn here

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
	
	# Keep this here to handle fallback frame drawing if elements initialize slowly
	update_ui_text_displays()

func initialize_victory_rewards(level_data: LevelData, score: int) -> void:
	visible = true
	$VICTORY.visible = true
	level_data_ref = level_data 

	final_score_to_display = score

	var level_key = "level_" + str(level_data.phase_number) + "-" + str(level_data.level_number) if level_data else "custom"

	var is_new_high_score = PlayerProfile.update_high_score(level_key, score)

	var minimum_reward_threshold = 300
	var qualifies_for_rewards = is_new_high_score or (score >= minimum_reward_threshold)

	if not qualifies_for_rewards:
		cached_coins_earned = 0
		cached_packs_earned = 0
		print("Score did not break an old high score or meet minimum requirements. No rewards granted.")
	else:
		# 2. Score / Currency Ratio Processing Matrix using your LevelData layout rules
		if level_data and level_data.is_boss_level:
			var boss_ratio: float = float(score) / 2500.00
			cached_coins_earned = int(clamp(boss_ratio * 200, 0, 250))
			cached_packs_earned = 2
		elif level_data and level_data.level_number == 3:
			var miniboss_ratio: float = float(score) / 1500.0
			cached_coins_earned = int(clamp(miniboss_ratio * 120, 0, 150))
			cached_packs_earned = 1
		else:
			var minion_ratio: float = float(score) / 800.0
			cached_coins_earned = int(clamp(minion_ratio * 50, 0, 75))
			cached_packs_earned = 0

	# 3. Apply profile data updates safely
	PlayerProfile.add_coins(cached_coins_earned)
	SaveManager.save_game()

	# 4. 🌟 FIX 2: Centralize UI text updates using our robust display coupler function
	update_ui_text_displays()

## Sequence controller running the box disappearance and pack animations loop
func _on_next_pressed() -> void:
	next_button.disabled = true

	# Visual Box Fade Disappear Sequence Effect
	var hide_tween = create_tween()
	hide_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	hide_tween.tween_callback(func(): self.visible = false)
	await hide_tween.finished

	# Instantiate and sequence card packs inside the PackLayer canvas frame context sequentially
	if cached_packs_earned > 0 and pack_scene:
		pack_layer.visible = true

		for i in range(cached_packs_earned):
			var pack_instance = pack_scene.instantiate()
			pack_layer.add_child(pack_instance)
			pack_instance.open_pack(false)
			await pack_instance.tree_exited

			if i < cached_packs_earned - 1:
				await get_tree().create_timer(0.25).timeout

	# Transition to card selection loops or map interfaces safely
	_finish_and_transition_scene()

func update_ui_text_displays():
	if is_instance_valid(score_label):
		score_label.text = str(final_score_to_display)
	if is_instance_valid(coin_reward_label):
		coin_reward_label.text = str(cached_coins_earned)
	if is_instance_valid(pack_reward_label):
		pack_reward_label.text = str(cached_packs_earned)

func _finish_and_transition_scene() -> void:
	# 🌟 THE FINAL ROUTING FLOW CONTROLLER
	if level_data_ref and level_data_ref.is_boss_level:
		print("[ROUTE] Boss clear complete. Moving back to overall lounge interface.")
		SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
	else:
		print("[ROUTE] Minion clear complete. Redirecting straight to Deck Builder scene layout.")
		# Redirect the player directly back to card preparation operations
		SceneTransition.change_scene_path("res://scenes/ui/DeckBuilder.tscn")
		
	queue_free()
