extends Node

signal purchase_success(item_id: String)
signal purchase_failed(reason: String)

func buy_item(item_id: String, cost: int) -> bool:
	if not PlayerProfile.can_afford(cost):
		purchase_failed.emit("Not enough coins!")
		return false
	
	if PlayerProfile.spend_coins(cost):
		PlayerInventory.add_item(item_id, 1)
		if has_node("/root/SaveManager"): get_node("/root/SaveManager").save_game()
		purchase_success.emit(item_id)
		return true
		
	return false
