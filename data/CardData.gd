extends Resource
class_name CardData
#Each card will have a name. For description gi put ra nako for now but probably not necessary? Unless sa spellbook siya iput!
@export var name: String = ""
@export var description: String = ""
#What type of card na siya
@export var category: GameEnums.CardCategory
@export var rarity: GameEnums.CardRarity 
#These will affect player stats and enemy stats sa game, can be compounded with other cards if played at the same time.
@export var damage: int = 0
@export var heal: int = 0
@export var mana_cost: int = 0
#For the art nii!
@export var texture: Texture2D
