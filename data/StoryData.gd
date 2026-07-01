extends Resource
class_name StoryData

enum Type {LORE, TUTORIAL, DIALOGUE}

@export var type: Type = Type.LORE
@export var character_name: String = "Lore"
@export var portrait: Texture2D
@export var background: Texture2D
@export_multiline var lines: Array[String]
@export var bgm_to_play: AudioStream
