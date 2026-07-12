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

func initialize_victory_rewards(level_data: LevelData, score: int, final_rank: String) -> void:
	visible = true
	$VICTORY.visible = true
	level_data_ref = level_data

	final_score_to_display = score

	var level_key = "level_" + str(level_data.phase_number) + "-" + str(level_data.level_number) if level_data else "custom"
	var is_new_high_score = PlayerProfile.update_high_score(level_key, score)

	var minimum_reward_threshold = 700
	var qualifies_for_rewards = is_new_high_score or (score >= minimum_reward_threshold)

	if not qualifies_for_rewards:
		cached_coins_earned = 0
		cached_packs_earned = 0
	else:
		# Calculate standard baseline values based on target minions vs boss tiers
		if level_data and level_data.is_boss_level:
			var boss_ratio: float = float(score) / 2500.0
			cached_coins_earned = int(clamp(boss_ratio * 200, 50, 250))
		else:
			var minion_ratio: float = float(score) / 1500.0
			cached_coins_earned = int(clamp(minion_ratio * 50, 15, 75))

		# 🌟 DYNAMIC ASSIGNMENT OVERRIDE BASED ON ROUND RANKINGS
		match final_rank:
			"S": cached_packs_earned = 2
			"A": cached_packs_earned = 1
			"B": cached_packs_earned = 0
			"C", _: cached_packs_earned = 0

	PlayerProfile.add_coins(cached_coins_earned)
	SaveManager.save_game()

	update_ui_text_displays()

## Sequence controller running the box disappearance and pack animations loop
func _on_next_pressed() -> void:
	next_button.disabled = true

	# 1. Hide the Victory UI overlay panels first to clear screen real estate
	var hide_tween = create_tween()
	hide_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	hide_tween.tween_callback(func(): self.visible = false)
	await hide_tween.finished

	# 2. Check if any card packs were earned from the match
	if cached_packs_earned > 0 and pack_scene:
		pack_layer.visible = true
		
		# Loop through each earned card pack sequentially
		for i in range(cached_packs_earned):
			var pack_instance = pack_scene.instantiate()
			pack_layer.add_child(pack_instance)
			
			# 🌟 GENERATE LIVE PACK DATA VIA CARD REGISTRY
			# Generate 5 random card paths using your registry weights (False = not a new player starter pack)
			var rolled_card_paths: Array[String] = CardRegistry.generate_pack_paths(false)
			
			# Add the rolled card paths directly to the player's profile data registry inventory
			for card_path in rolled_card_paths:
				PlayerProfile.add_card_to_inventory(card_path)
			
			# 🌟 TRIGGER THE ANIMATED CARD OPENING PACK 
			# Pass false to indicate it's a standard gameplay pack opening, not the starter tutorial
			pack_instance.open_pack(false)
			
			# Wait completely for the player to click/finish opening this pack instance
			await pack_instance.tree_exited
			
			# Quick intermission buffer timing break before rendering the next pack instance layout
			if i < cached_packs_earned - 1:
				await get_tree().create_timer(0.25).timeout
				
		# Force a save update to secure the newly rolled inventory collection variables in cloud sync slots
		SaveManager.save_game()

	# 3. 🌟 ROUTING: Now that all card packs are opened and closed, it's safe to transition out!
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
		#SceneTransition.change_scene_path("res://scenes/menus/lounge.tscn")
		SceneTransition.change_scene(level_data_ref.post_boss_cutscene)
	else:
		print("[ROUTE] Minion clear complete. Redirecting straight to Deck Builder scene layout.")
		# Redirect the player directly back to card preparation operations
		SceneTransition.change_scene_path("res://scenes/ui/DeckBuilder.tscn")
		
	queue_free()
