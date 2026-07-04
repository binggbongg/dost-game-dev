extends AnimatedSprite2D

# MASSIVE SIZE BOOST!
# Adjust this to change the overall size (e.g., 5.0, 7.0, 8.0)
const BASE_SCALE := Vector2(6.0, 6.0)

func _ready() -> void:
	hide()

func play_cast_sequence(active_cards: Array) -> void:
	if active_cards.is_empty():
		return

	# 1. INITIALIZE TOTAL STATE (Hidden, scaled down, ready to pop)
	self.modulate.a = 1.0
	self.scale = Vector2.ZERO
	show()
	
	# Keep track of indices so we know when we are at the absolute start or end
	var total_cards = active_cards.size()

	for i in range(total_cards):
		var card = active_cards[i]
		
		if is_instance_valid(card) and card.get("card_data"):
			var data = card.card_data as CardData
			if data and data.cardASL:
				self.sprite_frames = data.cardASL
				
				# Determine which animation to target
				var anim_to_play = "default"
				if not sprite_frames.has_animation(anim_to_play):
					var anims = sprite_frames.get_animation_names()
					if not anims.is_empty(): 
						anim_to_play = anims[0]
				
				play(anim_to_play)
				
				# ─── THE POP-IN EFFECT (ONLY FOR THE VERY FIRST CARD) ───
				if i == 0:
					var pop_tween = create_tween().set_parallel(true)
					pop_tween.tween_property(self, "scale", BASE_SCALE * 1.15, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					pop_tween.chain().tween_property(self, "scale", BASE_SCALE, 0.05)
				else:
					# Ensure middle cards instantly render at full scale
					self.scale = BASE_SCALE
					self.modulate.a = 1.0
				
				# Wait for current animation duration to complete
				if sprite_frames.get_animation_loop(anim_to_play):
					await get_tree().create_timer(1.2).timeout
				else:
					await self.animation_finished
				
				# ─── THE FADE-OUT EFFECT (ONLY FOR THE ABSOLUTE LAST CARD) ───
				if i == total_cards - 1:
					var fade_tween = create_tween().set_parallel(true)
					fade_tween.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
					fade_tween.tween_property(self, "scale", BASE_SCALE * 0.75, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
					
					# Wait for the grand finale fade out to complete
					await fade_tween.finished
	
	hide()
	self.sprite_frames = null
