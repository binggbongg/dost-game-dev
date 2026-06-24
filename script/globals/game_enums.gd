extends Node
# This is to differentiate the cards and later to identify valid combos
enum CardCategory { LAHI, DIWA, KALIKASAN, TANGLAW, S_DIWATA, S_ASWANG, S_KAPRE, S_BAKUNAWA, S_MINOKAWA }
#This is so that our system kay maka tell what are the allowed actions at certain states
enum TurnState {     
	START_TURN,
	DRAW_PHASE,
	PLAYER_ACTION,
	COMBO_SELECTION,
	RESOLVING_COMBO,
	END_TURN,
	ENEMY_TURN }
#This is to show the valididty of the combos used to attack/invalidities.
enum ComboValidationResult {
	VALID,
	INVALID_DUPLICATE_DIWA,
	INVALID_TRI_TANGLAW,
	INVALID_LAHI_TANGLAW_MIX,
	INVALID_LAHI_NEEDS_DIWA,
	INVALID_LAHI_NEEDS_KALIKASAN,
	INVALID_MISSING_PIECE, 
	INVALID_NOT_ENOUGH_MANA,
	INVALID_MAX_CARDS
}
#This can be used for both spellbook and actual gameplay
enum ComboType {
	ATTACK,
	HEAL,
	HYBRID,
	BUFF,
	DEBUFF,
	SPECIAL
}
#Can be used to define the probability of drawing that card after shuffled
enum CardRarity { 
	Karaniwan, 
	Natatangi, 
	Bihira, 
	Dambana, 	
	Special }
#Can be used to flag cards that have already been used in the game.
enum CardState {
	IN_DECK,
	IN_HAND,
	SELECTED,
	IN_COMBO,
	PLAYED,
	DISCARDED
}
#Used for different card functionalities and also will block player from using if for invalid combos
enum CardInteractionState {
	IDLE,
	HOVERED,
	CLICKED,
	DRAGGING,
	DISABLED
}
#Used ni siya sa ComboManager while nag validate siya sa combo gi use.
enum ComboPhase {
	IDLE,
	BUILDING,
	VALIDATING,
	RESOLVING,
	FINISHED
}

enum Location {
	HAND,
	SLOT,
	DECK
}

# -- For enemy stuff -- 
enum EnemyMoveType {
	ATTACK,
	DEFENSE,
	SKILL,
	BURST
}
