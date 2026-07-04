extends AnimatedSprite2D

func _ready() -> void:
	hide()

func play_cast_sequence(active_cards: Array) -> void:
	if active_cards.is_empty():
		return
	show()
	for card in active_cards:
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
				
				if sprite_frames.get_animation_loop(anim_to_play):
					await get_tree().create_timer(1.2).timeout
				else:
					# Standard wait for completion
					await self.animation_finished
	
	
	hide()
	self.sprite_frames = null
