extends CanvasLayer

@onready var me: AnimatedSprite2D = $Buttons/Content/CharacterSpotlight/Character
var player_name

func _ready():
	if PlayerProfile.player_name != "Default Player":
		player_name = PlayerProfile.player_name
	if PlayerProfile.selected_character != "None":
		var character_id = PlayerProfile.selected_character
		var path = "res://data/Characters/%s.tres" % character_id
		var character_data := load(path) as CharacterData
		if character_data:
			me.sprite_frames = character_data.sprite_frames
			me.play("idle")
			
