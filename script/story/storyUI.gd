extends CanvasLayer

@onready var me: AnimatedSprite2D = $Buttons/Content/CharacterSpotlight/Character

func _ready():
	if PlayerProfile.selected_character != "None":
		var character_id = PlayerProfile.selected_character
		var path = "res://data/Characters/%s.tres" % character_id

		var frames := load(path) as SpriteFrames
		if frames:
			me.sprite_frames = frames
		else:
			push_error("Failed to load SpriteFrames: " + path)
