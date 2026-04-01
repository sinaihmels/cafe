class_name ProgressionDirector
extends RefCounted

var _content: DemoContentLibrary
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(content: DemoContentLibrary, rng_seed: int = 0) -> void:
	_content = content
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed

func get_reward_choices(encounter_index: int, player_state: DemoPlayerState) -> Array[DemoRewardDef]:
	var tier: int = clampi(encounter_index, 1, 5)
	var choices: Array[DemoRewardDef] = []
	var card_reward: DemoRewardDef = _build_card_reward(tier)
	if card_reward != null:
		choices.append(card_reward)
	choices.append(_build_heal_reward(tier))
	if encounter_index >= 2 and not player_state.equipment_ids.has(&"equipment_coffee_machine"):
		choices.append(_build_equipment_reward(&"equipment_coffee_machine", tier))
	else:
		choices.append(_build_upgrade_reward(tier))
	choices.shuffle()
	return choices

func get_shop_offers(encounter_index: int, player_state: DemoPlayerState) -> Array[DemoRewardDef]:
	var tier: int = clampi(encounter_index, 1, 5)
	var offers: Array[DemoRewardDef] = []
	var card_offer: DemoRewardDef = _build_card_reward(tier)
	if card_offer != null:
		card_offer.cost = 4 + int(floor(float(tier) / 2.0))
		card_offer.description = "%s (Cost: %d tips)" % [card_offer.description, card_offer.cost]
		offers.append(card_offer)
	var heal_offer: DemoRewardDef = _build_heal_reward(tier)
	heal_offer.cost = 3 + int(floor(float(tier) / 2.0))
	heal_offer.description = "%s (Cost: %d tips)" % [heal_offer.description, heal_offer.cost]
	offers.append(heal_offer)
	var upgrade_offer: DemoRewardDef = _build_upgrade_reward(tier)
	upgrade_offer.cost = 5 + int(floor(float(tier) / 2.0))
	upgrade_offer.description = "%s (Cost: %d tips)" % [upgrade_offer.description, upgrade_offer.cost]
	offers.append(upgrade_offer)
	if not player_state.equipment_ids.has(&"equipment_coffee_machine"):
		var equipment_offer: DemoRewardDef = _build_equipment_reward(&"equipment_coffee_machine", tier)
		if equipment_offer != null:
			offers.append(equipment_offer)
	if not player_state.equipment_ids.has(&"equipment_display_case"):
		var display_case_offer: DemoRewardDef = _build_equipment_reward(&"equipment_display_case", tier)
		if display_case_offer != null:
			offers.append(display_case_offer)
	return offers

func apply_reward(reward: DemoRewardDef, run_state: DemoRunState, player_state: DemoPlayerState) -> String:
	if reward == null:
		return "No reward selected."
	match reward.type:
		DemoEnums.RewardType.ADD_CARD:
			var card_id: StringName = reward.payload_id
			var card_def: DemoCardDef = _content.get_card(card_id)
			if card_def == null:
				return "Reward card is missing."
			player_state.master_deck_ids.append(card_id)
			return "%s was added to your deck." % card_def.name
		DemoEnums.RewardType.ADD_EQUIPMENT:
			var equipment_def: DemoEquipmentDef = _content.get_equipment(reward.payload_id)
			if equipment_def == null:
				return "Equipment reward is missing."
			if player_state.equipment_ids.has(equipment_def.id):
				return "%s is already installed." % equipment_def.name
			player_state.equipment_ids.append(equipment_def.id)
			_apply_equipment_modifiers(equipment_def, player_state)
			return "Installed %s." % equipment_def.name
		DemoEnums.RewardType.HEAL_STRESS:
			player_state.heal_stress(reward.payload_amount)
			return "Recovered %d stress." % reward.payload_amount
		DemoEnums.RewardType.UPGRADE:
			player_state.max_stress += reward.payload_amount
			player_state.heal_stress(reward.payload_amount)
			if int(reward.tier) >= 4 and not player_state.equipment_ids.has(&"upgrade_mana_boost"):
				player_state.max_mana += 1
				player_state.equipment_ids.append(&"upgrade_mana_boost")
				player_state.reset_turn_mana()
				return "Kitchen upgrade: +%d max stress and +1 max mana." % reward.payload_amount
			return "Kitchen upgrade: +%d max stress." % reward.payload_amount
		DemoEnums.RewardType.ADD_TIPS:
			run_state.tips += reward.payload_amount
			return "Gained %d tips." % reward.payload_amount
		_:
			return "Reward type is unsupported."

func _build_card_reward(tier: int) -> DemoRewardDef:
	var card_ids: Array[StringName] = []
	for card_id_value in _content.cards.keys():
		var card_id: StringName = StringName(card_id_value)
		card_ids.append(card_id)
	if card_ids.is_empty():
		return null
	var picked_id: StringName = card_ids[_rng.randi_range(0, card_ids.size() - 1)]
	var card_def: DemoCardDef = _content.get_card(picked_id)
	if card_def == null:
		return null
	var reward: DemoRewardDef = DemoRewardDef.new()
	reward.type = DemoEnums.RewardType.ADD_CARD
	reward.payload_id = picked_id
	reward.tier = tier
	reward.label = "Add Card: %s" % card_def.name
	reward.description = "Add %s to your deck." % card_def.name
	return reward

func _build_heal_reward(tier: int) -> DemoRewardDef:
	var reward: DemoRewardDef = DemoRewardDef.new()
	reward.type = DemoEnums.RewardType.HEAL_STRESS
	reward.payload_amount = 2 + tier
	reward.tier = tier
	reward.label = "Take A Breather"
	reward.description = "Recover %d stress." % reward.payload_amount
	return reward

func _build_upgrade_reward(tier: int) -> DemoRewardDef:
	var reward: DemoRewardDef = DemoRewardDef.new()
	reward.type = DemoEnums.RewardType.UPGRADE
	reward.payload_amount = 2 + int(floor(float(tier) / 2.0))
	reward.tier = tier
	reward.label = "Kitchen Upgrade"
	reward.description = "Increase max stress by %d and heal the same amount." % reward.payload_amount
	return reward

func _build_equipment_reward(equipment_id: StringName, tier: int) -> DemoRewardDef:
	var equipment_def: DemoEquipmentDef = _content.get_equipment(equipment_id)
	if equipment_def == null:
		return null
	var reward: DemoRewardDef = DemoRewardDef.new()
	reward.type = DemoEnums.RewardType.ADD_EQUIPMENT
	reward.payload_id = equipment_id
	reward.tier = tier
	reward.label = "Install %s" % equipment_def.name
	reward.description = equipment_def.description
	reward.cost = equipment_def.cost
	return reward

func _apply_equipment_modifiers(equipment_def: DemoEquipmentDef, player_state: DemoPlayerState) -> void:
	if equipment_def == null:
		return
	var max_mana_bonus: int = int(equipment_def.modifiers.get("max_mana_bonus", 0))
	if max_mana_bonus > 0:
		player_state.max_mana += max_mana_bonus
		player_state.reset_turn_mana()
	var max_stress_bonus: int = int(equipment_def.modifiers.get("max_stress_bonus", 0))
	if max_stress_bonus > 0:
		player_state.max_stress += max_stress_bonus
		player_state.heal_stress(max_stress_bonus)
	var draw_bonus: int = int(equipment_def.modifiers.get("starting_hand_bonus", 0))
	if draw_bonus > 0:
		player_state.starting_hand_size += draw_bonus
