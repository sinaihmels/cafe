class_name MetaProfileService
extends Node

const SAVE_PATH: String = "user://meta_profile.json"

var profile_state: MetaProfileState = MetaProfileState.new()

func load_or_create(content: ContentLibrary) -> void:
	profile_state = MetaProfileState.new()
	if FileAccess.file_exists(SAVE_PATH):
		var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				_apply_loaded_data(parsed)
	profile_state.ensure_defaults()
	_apply_default_unlocks(content)
	save_profile()

func save_profile() -> void:
	profile_state.ensure_defaults()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(_to_dict(), "\t"))

func reset_profile(content: ContentLibrary) -> void:
	profile_state = MetaProfileState.new()
	profile_state.ensure_defaults()
	_apply_default_unlocks(content)
	save_profile()

func can_afford_meta(cost: int) -> bool:
	return profile_state.meta_currency >= cost

func spend_meta(cost: int) -> bool:
	if cost > profile_state.meta_currency:
		return false
	profile_state.meta_currency -= cost
	save_profile()
	return true

func grant_meta_currency(amount: int) -> void:
	profile_state.meta_currency = maxi(0, profile_state.meta_currency + amount)
	save_profile()

func grant_equipment(equipment_id: StringName) -> void:
	if not profile_state.owned_equipment_ids.has(equipment_id):
		profile_state.owned_equipment_ids.append(equipment_id)
	if not profile_state.unlocked_equipment_ids.has(equipment_id):
		profile_state.unlocked_equipment_ids.append(equipment_id)
	save_profile()

func purchase_equipment(equipment_id: StringName, cost: int) -> bool:
	if profile_state.owned_equipment_ids.has(equipment_id):
		return true
	if not spend_meta(cost):
		return false
	profile_state.owned_equipment_ids.append(equipment_id)
	if not profile_state.unlocked_equipment_ids.has(equipment_id):
		profile_state.unlocked_equipment_ids.append(equipment_id)
	save_profile()
	return true

func equip_equipment(equipment_id: StringName, equipped: bool) -> void:
	if equipped:
		if profile_state.owned_equipment_ids.has(equipment_id) and not profile_state.equipped_equipment_ids.has(equipment_id):
			profile_state.equipped_equipment_ids.append(equipment_id)
	else:
		var index: int = profile_state.equipped_equipment_ids.find(equipment_id)
		if index >= 0:
			profile_state.equipped_equipment_ids.remove_at(index)
	save_profile()

func purchase_upgrade(upgrade_id: StringName, cost: int) -> bool:
	if profile_state.purchased_shop_upgrade_ids.has(upgrade_id):
		return false
	if not spend_meta(cost):
		return false
	profile_state.purchased_shop_upgrade_ids.append(upgrade_id)
	if not profile_state.unlocked_shop_upgrade_ids.has(upgrade_id):
		profile_state.unlocked_shop_upgrade_ids.append(upgrade_id)
	save_profile()
	return true

func purchase_decoration(decoration_id: StringName, cost: int) -> bool:
	if profile_state.owned_decoration_ids.has(decoration_id):
		return false
	if not spend_meta(cost):
		return false
	profile_state.owned_decoration_ids.append(decoration_id)
	if not profile_state.unlocked_decoration_ids.has(decoration_id):
		profile_state.unlocked_decoration_ids.append(decoration_id)
	save_profile()
	return true

func place_decoration(slot_name: String, decoration_id: StringName) -> bool:
	if decoration_id != &"" and not profile_state.owned_decoration_ids.has(decoration_id):
		return false
	profile_state.decoration_layout[slot_name] = String(decoration_id)
	save_profile()
	return true

func unlock_card(card_id: StringName) -> void:
	if not profile_state.unlocked_card_ids.has(card_id):
		profile_state.unlocked_card_ids.append(card_id)
	save_profile()

func unlock_customer(customer_id: StringName) -> void:
	if not profile_state.unlocked_customer_ids.has(customer_id):
		profile_state.unlocked_customer_ids.append(customer_id)
	save_profile()

func record_run_result(day_number: int, meta_currency_reward: int) -> void:
	profile_state.run_count += 1
	profile_state.best_run_day = maxi(profile_state.best_run_day, day_number)
	grant_meta_currency(meta_currency_reward)
	save_profile()

func _apply_loaded_data(data: Dictionary) -> void:
	profile_state.version = int(data.get("version", profile_state.version))
	profile_state.meta_currency = int(data.get("meta_currency", profile_state.meta_currency))
	profile_state.owned_equipment_ids = PackedStringArray(data.get("owned_equipment_ids", []))
	profile_state.equipped_equipment_ids = PackedStringArray(data.get("equipped_equipment_ids", []))
	profile_state.purchased_shop_upgrade_ids = PackedStringArray(data.get("purchased_shop_upgrade_ids", []))
	profile_state.owned_decoration_ids = PackedStringArray(data.get("owned_decoration_ids", []))
	profile_state.decoration_layout = data.get("decoration_layout", profile_state.decoration_layout)
	profile_state.unlocked_dough_ids = PackedStringArray(data.get("unlocked_dough_ids", []))
	profile_state.unlocked_card_ids = PackedStringArray(data.get("unlocked_card_ids", []))
	profile_state.unlocked_customer_ids = PackedStringArray(data.get("unlocked_customer_ids", []))
	profile_state.unlocked_equipment_ids = PackedStringArray(data.get("unlocked_equipment_ids", []))
	profile_state.unlocked_decoration_ids = PackedStringArray(data.get("unlocked_decoration_ids", []))
	profile_state.unlocked_shop_upgrade_ids = PackedStringArray(data.get("unlocked_shop_upgrade_ids", []))
	profile_state.unlocked_buff_ids = PackedStringArray(data.get("unlocked_buff_ids", []))
	profile_state.unlocked_status_ids = PackedStringArray(data.get("unlocked_status_ids", []))
	profile_state.run_count = int(data.get("run_count", 0))
	profile_state.best_run_day = int(data.get("best_run_day", 0))

func _apply_default_unlocks(content: ContentLibrary) -> void:
	for dough_value in content.doughs.values():
		var dough: DoughDef = dough_value
		if dough != null and dough.unlocked_by_default and not profile_state.unlocked_dough_ids.has(dough.dough_id):
			profile_state.unlocked_dough_ids.append(dough.dough_id)
	for card_value in content.cards.values():
		var card: CardDef = card_value
		if card != null and not profile_state.unlocked_card_ids.has(card.card_id):
			profile_state.unlocked_card_ids.append(card.card_id)
	for customer_value in content.customers.values():
		var customer: CustomerDef = customer_value
		if customer != null and customer.customer_id != &"critic_boss" and not profile_state.unlocked_customer_ids.has(customer.customer_id):
			profile_state.unlocked_customer_ids.append(customer.customer_id)
	for equipment_value in content.equipment.values():
		var equipment: EquipmentDef = equipment_value
		if equipment != null and equipment.unlocked_by_default and not profile_state.unlocked_equipment_ids.has(equipment.equipment_id):
			profile_state.unlocked_equipment_ids.append(equipment.equipment_id)
	for decoration_value in content.decorations.values():
		var decoration: DecorationDef = decoration_value
		if decoration != null and decoration.unlocked_by_default and not profile_state.unlocked_decoration_ids.has(decoration.decoration_id):
			profile_state.unlocked_decoration_ids.append(decoration.decoration_id)
	for upgrade_value in content.shop_upgrades.values():
		var upgrade: ShopUpgradeDef = upgrade_value
		if upgrade != null and upgrade.unlocked_by_default and not profile_state.unlocked_shop_upgrade_ids.has(upgrade.upgrade_id):
			profile_state.unlocked_shop_upgrade_ids.append(upgrade.upgrade_id)
	for buff_value in content.buffs.values():
		var buff: BuffDef = buff_value
		if buff != null and not profile_state.unlocked_buff_ids.has(buff.modifier_id):
			profile_state.unlocked_buff_ids.append(buff.modifier_id)
	for status_value in content.statuses.values():
		var status_def: StatusDef = status_value
		if status_def != null and not profile_state.unlocked_status_ids.has(status_def.modifier_id):
			profile_state.unlocked_status_ids.append(status_def.modifier_id)

func _to_dict() -> Dictionary:
	return {
		"version": profile_state.version,
		"meta_currency": profile_state.meta_currency,
		"owned_equipment_ids": Array(profile_state.owned_equipment_ids),
		"equipped_equipment_ids": Array(profile_state.equipped_equipment_ids),
		"purchased_shop_upgrade_ids": Array(profile_state.purchased_shop_upgrade_ids),
		"owned_decoration_ids": Array(profile_state.owned_decoration_ids),
		"decoration_layout": profile_state.decoration_layout,
		"unlocked_dough_ids": Array(profile_state.unlocked_dough_ids),
		"unlocked_card_ids": Array(profile_state.unlocked_card_ids),
		"unlocked_customer_ids": Array(profile_state.unlocked_customer_ids),
		"unlocked_equipment_ids": Array(profile_state.unlocked_equipment_ids),
		"unlocked_decoration_ids": Array(profile_state.unlocked_decoration_ids),
		"unlocked_shop_upgrade_ids": Array(profile_state.unlocked_shop_upgrade_ids),
		"unlocked_buff_ids": Array(profile_state.unlocked_buff_ids),
		"unlocked_status_ids": Array(profile_state.unlocked_status_ids),
		"run_count": profile_state.run_count,
		"best_run_day": profile_state.best_run_day,
	}
