extends Node
signal inventory_changed

# Format: { "item_id": quantity }
var owned_items = {}

func add_item(item_id: String, amount: int = 1):
	var data = ItemDb.get_item(item_id)
	if not data:
		print("Inventory Error: Item ID ", item_id, " not found in Database.")
		return

	if data.stackable:
		owned_items[item_id] = owned_items.get(item_id, 0) + amount
	else:
		#update this code later please for items bought from actual store and not
		owned_items[item_id] = owned_items.get(item_id, 0)
	
	inventory_changed.emit()
	print("Inventory: Added ", amount, "x ", item_id)

func remove_item(item_id: String, amount: int = 1) -> bool:
	if has_item(item_id, amount):
		owned_items[item_id] -= amount
		if owned_items[item_id] <= 0:
			owned_items.erase(item_id)
		inventory_changed.emit()
		return true
	return false

func has_item(item_id: String, amount: int = 1) -> bool:
	return owned_items.get(item_id, 0) >= amount

func get_quantity(item_id: String) -> int:
	return owned_items.get(item_id, 0)

# Used for consumables like potions
func consume_item(item_id: String) -> bool:
	var data = ItemDb.get_item(item_id)
	if data and has_item(item_id, 1):
		remove_item(item_id, 1)
		return true
	return false
