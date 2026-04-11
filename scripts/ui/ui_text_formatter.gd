class_name UiTextFormatter
extends RefCounted

static func screen_title(screen: int) -> String:
	match screen:
		GameEnums.Screen.TITLE:
			return "Cafe"
		GameEnums.Screen.CAFE_HUB:
			return "Cafe Hub"
		GameEnums.Screen.DECORATION:
			return "Decorate Cafe"
		GameEnums.Screen.DOUGH_SELECT:
			return "Choose Dough"
		GameEnums.Screen.ENCOUNTER:
			return "Encounter"
		GameEnums.Screen.REWARD:
			return "Reward"
		GameEnums.Screen.RUN_SHOP:
			return "Run Shop"
		GameEnums.Screen.BOSS_INTRO:
			return "Boss Intro"
		GameEnums.Screen.SUMMARY:
			return "Summary"
		_:
			return "Cafe"

static func build_meta_text(session_service: SessionService) -> String:
	var profile: MetaProfileState = session_service.get_profile_state()
	return "Cafe tokens: %d | Runs: %d | Best day: %d | Stress: %d/%d | Reputation: %d | Tips: %d" % [
		profile.meta_currency,
		profile.run_count,
		profile.best_run_day,
		session_service.player_state.stress,
		session_service.player_state.max_stress,
		session_service.player_state.reputation,
		session_service.player_state.tips,
	]

static func build_modifier_lines(session_service: SessionService) -> Array[String]:
	var lines: Array[String] = []
	for passive_modifier in session_service.player_state.passive_modifiers:
		_append_modifier_line(lines, session_service, passive_modifier)
	for active_buff in session_service.player_state.active_buffs:
		_append_modifier_line(lines, session_service, active_buff)
	return lines

static func _append_modifier_line(
	lines: Array[String],
	session_service: SessionService,
	instance: ModifierInstance
) -> void:
	if instance == null:
		return
	var definition: ModifierDef = session_service.content_library.get_modifier(instance.modifier_id)
	if definition == null:
		return
	var line: String = definition.display_name
	if instance.stacks > 1:
		line += " x%d" % instance.stacks
	if instance.remaining_turns > 0:
		line += " (%dt)" % instance.remaining_turns
	lines.append(line)

static func describe_customer_request(customer: CustomerInstance) -> String:
	if customer == null:
		return "Request: none"
	if customer.is_departing():
		return "Request: leaving the counter"
	var required_text: String = join_packed(customer.get_preferences())
	var details: Array[String] = []
	if required_text != "none":
		details.append("Needs: %s" % required_text)
	else:
		details.append("Needs: any plated pastry")
	var bonus_text: String = join_packed(customer.get_bonus_tags())
	if bonus_text != "none":
		details.append("Likes: %s" % bonus_text)
	if customer.get_minimum_quality() > 0:
		details.append("Q>=%d" % customer.get_minimum_quality())
	details.append("Hunger: %d" % maxi(0, customer.remaining_hunger))
	return "Request: %s" % join_strings(details)

static func describe_item(item: ItemInstance) -> String:
	return "%s | Q%d | %s" % [item.get_display_name(), item.quality, join_packed(item.get_all_tags())]

static func describe_pastry(pastry: PastryInstance) -> String:
	if pastry == null:
		return "No pastry"
	return "%s | Q%d | Tags: %s | States: %s" % [
		pastry.get_display_name(),
		pastry.quality,
		join_packed(pastry.get_pastry_tags()),
		join_packed(pastry.get_pastry_states()),
	]

static func join_strings(values: Array[String]) -> String:
	var output: String = ""
	for index in range(values.size()):
		if index > 0:
			output += " | "
		output += values[index]
	return output

static func join_packed(values: PackedStringArray) -> String:
	if values.is_empty():
		return "none"
	var output: String = ""
	for index in range(values.size()):
		if index > 0:
			output += ", "
		output += String(values[index])
	return output
