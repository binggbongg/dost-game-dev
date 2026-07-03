extends Resource
class_name CardData
#Each card will have a name. For description gi put ra nako for now but probably not necessary? Unless sa spellbook siya iput!
@export var name: String = ""
@export var description: String = ""

#What type of card na siya
@export var category: GameEnums.CardCategory
@export var rarity: GameEnums.CardRarity 

#These will affect player stats and enemy stats sa game, can be compounded with other cards if played at the same time.
@export var damage: float = 0
@export var heal: float = 0
@export var mana_cost: int = 0

#For the art nii!
@export var texture: Texture2D
var card_source: GameEnums.CardSource =GameEnums.CardSource.DECK

@export var cardASL: SpriteFrames

func apply_effect(player_stats_node, targets):
	print("applying card effect")
	if damage > 0:
		for enemy in targets:
			if is_instance_valid(enemy) and enemy.has_method("take_damage"):
				enemy.take_damage(int(damage))
			else:
				print("missing take damage method -- from card data")
	
	if heal > 0 and player_stats_node and player_stats_node.has_method("heal_player"):
		player_stats_node.heal_player(int(heal))
