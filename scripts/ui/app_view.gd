class_name AppView
extends Control

signal continue_from_title_requested()
signal reset_profile_requested()
signal open_dough_select_requested()
signal open_decoration_requested()
signal close_decoration_requested()
signal start_run_requested(dough_id: StringName)
signal buy_upgrade_requested(upgrade_id: StringName)
signal buy_decoration_requested(decoration_id: StringName)
signal place_decoration_requested(slot_name: String, decoration_id: StringName)
signal toggle_equipment_requested(equipment_id: StringName, equipped: bool)
signal choose_reward_requested(reward_id: StringName)
signal buy_offer_requested(offer_id: StringName)
signal continue_after_shop_requested()
signal return_to_hub_requested()
signal start_boss_requested()
signal end_turn_requested()
signal play_card_requested(card_index: int)
signal customer_item_requested(customer_index: int)
signal prep_item_requested(item_index: int)
signal oven_item_requested(slot_index: int)
signal table_item_requested(item_index: int)

var _background: TextureRect
var _margin: MarginContainer
var _root: VBoxContainer
var _title_label: Label
var _status_label: Label
var _meta_label: Label
var _hero_row: HBoxContainer
var _content_scroll: ScrollContainer
var _content: VBoxContainer
var _ui_built: bool = false

func _enter_tree() -> void:
	_ensure_ui_built()

func _ready() -> void:
	_ensure_ui_built()

func _ensure_ui_built() -> void:
	if _ui_built:
		return
	_build_ui()
	_ui_built = true

func _build_ui() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0

	if _background != null:
		return

	_background = TextureRect.new()
	_background.anchors_preset = PRESET_FULL_RECT
	_background.anchor_right = 1.0
	_background.anchor_bottom = 1.0
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_background.texture = _load_texture(ArtCatalog.background_path())
	add_child(_background)

	_margin = MarginContainer.new()
	_margin.anchors_preset = PRESET_FULL_RECT
	_margin.anchor_right = 1.0
	_margin.anchor_bottom = 1.0
	_margin.add_theme_constant_override("margin_left", 24)
	_margin.add_theme_constant_override("margin_top", 24)
	_margin.add_theme_constant_override("margin_right", 24)
	_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(_margin)

	_root = VBoxContainer.new()
	_root.size_flags_vertical = SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", 12)
	_margin.add_child(_root)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 30)
	_root.add_child(_title_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_status_label)

	_meta_label = Label.new()
	_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_meta_label)

	_hero_row = HBoxContainer.new()
	_hero_row.add_theme_constant_override("separation", 12)
	_root.add_child(_hero_row)

	_content_scroll = ScrollContainer.new()
	_content_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	_root.add_child(_content_scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 12)
	_content_scroll.add_child(_content)

func render(session_service: SessionService, interaction_state: Dictionary = {}) -> void:
	_ensure_ui_built()
	_title_label.text = _screen_title(session_service.run_state.screen)
	_status_label.text = session_service.get_status_message()
	_meta_label.text = _build_meta_text(session_service)
	_clear_container(_hero_row)
	_clear_container(_content)
	_render_hero(session_service)
	match session_service.run_state.screen:
		GameEnums.Screen.TITLE:
			_render_title_screen()
		GameEnums.Screen.CAFE_HUB:
			_render_hub_screen(session_service)
		GameEnums.Screen.DECORATION:
			_render_decoration_screen(session_service)
		GameEnums.Screen.DOUGH_SELECT:
			_render_dough_select_screen(session_service)
		GameEnums.Screen.ENCOUNTER:
			_render_encounter_screen(session_service, interaction_state)
		GameEnums.Screen.REWARD:
			_render_reward_screen(session_service)
		GameEnums.Screen.RUN_SHOP:
			_render_shop_screen(session_service)
		GameEnums.Screen.BOSS_INTRO:
			_render_boss_intro_screen(session_service)
		GameEnums.Screen.SUMMARY:
			_render_summary_screen(session_service)

func _screen_title(screen: int) -> String:
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

func _build_meta_text(session_service: SessionService) -> String:
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

func _render_hero(session_service: SessionService) -> void:
	var dough_id: StringName = session_service.run_state.selected_dough_id
	if dough_id == &"":
		dough_id = &"sweet_dough"
	_hero_row.add_child(_make_texture_card(_load_texture(ArtCatalog.dough_path(dough_id), ArtCatalog.dough_placeholder_path()), "Dough"))
	if not session_service.run_state.current_customer_ids.is_empty():
		var customer_id: StringName = StringName(session_service.run_state.current_customer_ids[0])
		_hero_row.add_child(_make_texture_card(_load_texture(ArtCatalog.customer_path(customer_id), ArtCatalog.customer_placeholder_path()), "Guest"))
	else:
		_hero_row.add_child(_make_texture_card(_load_texture(ArtCatalog.customer_placeholder_path()), "Guest"))

func _render_title_screen() -> void:
	_content.add_child(_make_text_label("One canonical project now drives the whole game: title, cafe hub, decoration flow, run encounters, rewards, shop, boss, and summary."))
	_content.add_child(_make_button("Continue", _on_continue_from_title_pressed))
	_content.add_child(_make_button("Reset Profile", _on_reset_profile_pressed))

func _render_hub_screen(session_service: SessionService) -> void:
	_content.add_child(_make_section_label("Cafe Management"))
	_content.add_child(_make_text_label("Permanent upgrades and decorations live here. Run-only cards and buffs stay inside the run."))
	_content.add_child(_make_button("Start New Run", _on_open_dough_select_pressed))
	_content.add_child(_make_button("Decorate Cafe", _on_open_decoration_pressed))
	_content.add_child(_make_button("Reset Profile", _on_reset_profile_pressed))

	_content.add_child(_make_section_label("Equipment"))
	var profile: MetaProfileState = session_service.get_profile_state()
	for equipment_value in session_service.get_available_equipment():
		var equipment: EquipmentDef = equipment_value
		var owned: bool = profile.owned_equipment_ids.has(equipment.equipment_id)
		var equipped: bool = profile.equipped_equipment_ids.has(equipment.equipment_id)
		_content.add_child(_make_text_label("%s | %s | Cost %d | %s" % [equipment.display_name, equipment.description, equipment.cost, "Equipped" if equipped else "Not equipped"]))
		var label: String = "Unequip" if equipped else ("Unlock And Equip" if not owned else "Equip")
		var equipment_id: StringName = equipment.equipment_id
		var next_equipped: bool = not equipped
		_content.add_child(_make_button(label, func() -> void: toggle_equipment_requested.emit(equipment_id, next_equipped)))

	_content.add_child(_make_section_label("Permanent Shop Upgrades"))
	for upgrade_value in session_service.get_available_shop_upgrades():
		var upgrade: ShopUpgradeDef = upgrade_value
		var owned_upgrade: bool = profile.purchased_shop_upgrade_ids.has(upgrade.upgrade_id)
		_content.add_child(_make_text_label("%s | %s | Cost %d | %s" % [upgrade.display_name, upgrade.description, upgrade.cost, "Owned" if owned_upgrade else "Available"]))
		if not owned_upgrade:
			var upgrade_id: StringName = upgrade.upgrade_id
			_content.add_child(_make_button("Buy Upgrade", func() -> void: buy_upgrade_requested.emit(upgrade_id)))

	_content.add_child(_make_section_label("Decorations"))
	for decoration_value in session_service.get_available_decorations():
		var decoration: DecorationDef = decoration_value
		var owned_decoration: bool = profile.owned_decoration_ids.has(decoration.decoration_id)
		_content.add_child(_make_text_label("%s | %s | Cost %d | %s" % [decoration.display_name, decoration.description, decoration.cost, "Owned" if owned_decoration else "Available"]))
		if not owned_decoration:
			var decoration_id: StringName = decoration.decoration_id
			_content.add_child(_make_button("Buy Decoration", func() -> void: buy_decoration_requested.emit(decoration_id)))

	_content.add_child(_make_section_label("Current Layout"))
	for slot_name in ["wall", "counter", "floor", "shelf", "exterior"]:
		var current_value: String = String(profile.decoration_layout.get(slot_name, ""))
		var label: String = current_value if current_value != "" else "Empty"
		_content.add_child(_make_text_label("%s: %s" % [slot_name.capitalize(), label]))

func _render_decoration_screen(session_service: SessionService) -> void:
	var profile: MetaProfileState = session_service.get_profile_state()
	_content.add_child(_make_button("Back To Hub", _on_close_decoration_pressed))
	for slot_name in ["wall", "counter", "floor", "shelf", "exterior"]:
		var slot_name_copy: String = slot_name
		_content.add_child(_make_section_label(slot_name.capitalize()))
		var current_value: String = String(profile.decoration_layout.get(slot_name, ""))
		_content.add_child(_make_text_label("Current: %s" % (current_value if current_value != "" else "Empty")))
		_content.add_child(_make_button("Clear Slot", func() -> void: place_decoration_requested.emit(slot_name_copy, &"")))
		for decoration_value in session_service.get_available_decorations():
			var decoration: DecorationDef = decoration_value
			if session_service.get_decoration_slot_name(decoration.slot) != slot_name:
				continue
			if not profile.owned_decoration_ids.has(decoration.decoration_id):
				continue
			var owned_decoration_id: StringName = decoration.decoration_id
			_content.add_child(_make_button(decoration.display_name, func() -> void: place_decoration_requested.emit(slot_name_copy, owned_decoration_id)))

func _render_dough_select_screen(session_service: SessionService) -> void:
	var pending_day_number: int = maxi(1, session_service.run_state.pending_day_number)
	_content.add_child(_make_text_label("Choose the dough for day %d. The selected dough is automatically prepped at the start of the day." % pending_day_number))
	for dough_value in session_service.get_available_doughs():
		var dough: DoughDef = dough_value
		var unlocked: bool = session_service.get_profile_state().unlocked_dough_ids.has(dough.dough_id)
		_content.add_child(_make_texture_card(_load_texture(ArtCatalog.dough_path(dough.dough_id), ArtCatalog.dough_placeholder_path()), dough.display_name))
		_content.add_child(_make_text_label("%s | %s | %s" % [dough.display_name, dough.description, "Unlocked" if unlocked else "Locked"]))
		if unlocked:
			var dough_id: StringName = dough.dough_id
			_content.add_child(_make_button("Prep Day %d" % pending_day_number, func() -> void: start_run_requested.emit(dough_id)))

func _render_encounter_screen(session_service: SessionService, interaction_state: Dictionary) -> void:
	_content.add_child(_make_text_label("Day %d | Turn %d | Energy %d/%d | Stress %d/%d | Reputation %d | Tips %d" % [
		session_service.run_state.day_number,
		session_service.combat_state.turn_number,
		session_service.player_state.energy,
		session_service.player_state.max_energy,
		session_service.player_state.stress,
		session_service.player_state.max_stress,
		session_service.player_state.reputation,
		session_service.player_state.tips,
	]))
	_content.add_child(_make_text_label("Each day starts with your chosen dough already in prep. Play dough-modifying cards, bake for 1 turn, collect from the oven, then play Serve to deliver the pastry."))
	var prompt: String = String(interaction_state.get("pending_prompt", ""))
	if prompt != "":
		_content.add_child(_make_text_label(prompt))
	_content.add_child(_make_button("End Turn", _on_end_turn_pressed))

	_content.add_child(_make_section_label("Customers"))
	if session_service.combat_state.active_customers.is_empty():
		_content.add_child(_make_text_label("No active customers."))
	for customer_index in range(session_service.combat_state.active_customers.size()):
		var customer: CustomerInstance = session_service.combat_state.active_customers[customer_index]
		var active_customer_index: int = customer_index
		_content.add_child(_make_texture_card(_load_texture(ArtCatalog.customer_path(customer.customer_def.customer_id), ArtCatalog.customer_placeholder_path()), customer.get_display_name()))
		_content.add_child(_make_text_label("%s | Patience: %d" % [_describe_customer_request(customer), customer.current_patience]))
		var customer_button: Button = _make_button("Customer %d: %s" % [customer_index + 1, customer.get_display_name()], func() -> void: customer_item_requested.emit(active_customer_index))
		customer_button.disabled = not _is_zone_targetable(interaction_state, &"customer", customer_index)
		_content.add_child(customer_button)

	_content.add_child(_make_section_label("Prep"))
	if session_service.cafe_state.prep_items.is_empty():
		_content.add_child(_make_text_label("Prep is empty."))
	for prep_index in range(session_service.cafe_state.prep_items.size()):
		var prep_item: ItemInstance = session_service.cafe_state.prep_items[prep_index]
		var prep_item_index: int = prep_index
		var prep_button: Button = _make_button(_describe_item(prep_item), func() -> void: prep_item_requested.emit(prep_item_index))
		prep_button.disabled = not _is_zone_targetable(interaction_state, &"prep", prep_index)
		_content.add_child(prep_button)

	_content.add_child(_make_section_label("Oven"))
	for slot_index in range(session_service.cafe_state.oven_slots.size()):
		var slot: OvenSlotState = session_service.cafe_state.oven_slots[slot_index]
		if slot.item == null:
			_content.add_child(_make_text_label("Slot %d: Empty" % [slot_index + 1]))
			continue
		var oven_slot_index: int = slot_index
		var oven_button: Button = _make_button("Slot %d: %s (%s)" % [slot_index + 1, slot.item.get_display_name(), "Ready" if slot.remaining_turns <= 0 else "%d turn left" % [slot.remaining_turns]], func() -> void: oven_item_requested.emit(oven_slot_index))
		oven_button.disabled = not (_is_zone_targetable(interaction_state, &"oven", slot_index) or slot.remaining_turns <= 0)
		_content.add_child(oven_button)

	_content.add_child(_make_section_label("Table"))
	if session_service.cafe_state.table_items.is_empty():
		_content.add_child(_make_text_label("Table is empty."))
	for table_index in range(session_service.cafe_state.table_items.size()):
		var table_item: ItemInstance = session_service.cafe_state.table_items[table_index]
		var table_item_index: int = table_index
		var table_button: Button = _make_button(_describe_item(table_item), func() -> void: table_item_requested.emit(table_item_index))
		table_button.disabled = not _is_zone_targetable(interaction_state, &"table", table_index)
		_content.add_child(table_button)

	_content.add_child(_make_section_label("Hand"))
	for card_index in range(session_service.deck_state.hand.size()):
		var card: CardInstance = session_service.deck_state.hand[card_index]
		var hand_card_index: int = card_index
		_content.add_child(_make_texture_card(_load_texture(ArtCatalog.card_path(card.card_def.card_id), ArtCatalog.card_base_path()), card.get_display_name()))
		var button_label: String = "%s%s (Cost %d) | %s" % ["[Selecting] " if interaction_state.get("pending_card_index", -1) == card_index else "", card.get_display_name(), card.get_cost(), card.get_preview_text()]
		var card_button: Button = _make_button(button_label, func() -> void: play_card_requested.emit(hand_card_index))
		card_button.disabled = card.get_cost() > session_service.player_state.energy
		_content.add_child(card_button)

func _render_reward_screen(session_service: SessionService) -> void:
	for reward_value in session_service.get_pending_rewards():
		var reward: RewardDef = reward_value
		_content.add_child(_make_text_label("%s | %s" % [reward.display_name, reward.description]))
		if reward.reward_type == GameEnums.RewardType.ADD_CARD_TO_RUN_DECK:
			_content.add_child(_make_texture_card(_load_texture(ArtCatalog.card_path(reward.payload_id), ArtCatalog.card_base_path()), reward.display_name))
		var reward_id: StringName = reward.reward_id
		_content.add_child(_make_button("Choose", func() -> void: choose_reward_requested.emit(reward_id)))

func _render_shop_screen(session_service: SessionService) -> void:
	_content.add_child(_make_text_label("Spend run tips on temporary help for this run."))
	for offer_value in session_service.get_pending_shop_offers():
		var offer: CardOfferDef = offer_value
		_content.add_child(_make_text_label("%s | %s | Cost %d" % [offer.display_name, offer.description, offer.cost]))
		if offer.offer_type == GameEnums.OfferType.RUN_CARD:
			_content.add_child(_make_texture_card(_load_texture(ArtCatalog.card_path(offer.payload_id), ArtCatalog.card_base_path()), offer.display_name))
		var offer_id: StringName = offer.offer_id
		_content.add_child(_make_button("Buy", func() -> void: buy_offer_requested.emit(offer_id)))
	_content.add_child(_make_button("Continue", _on_continue_after_shop_pressed))

func _render_boss_intro_screen(session_service: SessionService) -> void:
	var boss: CustomerDef = session_service.content_library.get_customer(&"critic_boss")
	if boss != null:
		_content.add_child(_make_texture_card(_load_texture(ArtCatalog.customer_path(boss.customer_id), ArtCatalog.customer_placeholder_path()), boss.display_name))
		_content.add_child(_make_text_label("The boss wants something sweet and decorated. Choose the dough for the final day, then prep, bake, and serve it before patience runs out."))
	_content.add_child(_make_button("Choose Boss Dough", _on_start_boss_pressed))

func _render_summary_screen(session_service: SessionService) -> void:
	_content.add_child(_make_text_label(session_service.run_state.summary_message))
	_content.add_child(_make_button("Return To Hub", _on_return_to_hub_pressed))

func _is_zone_targetable(interaction_state: Dictionary, zone: StringName, index: int) -> bool:
	var pending_rule: String = String(interaction_state.get("pending_rule", ""))
	if pending_rule == "":
		return false
	match pending_rule:
		"select_two_prep_items":
			if zone != &"prep":
				return false
			var selected: PackedInt32Array = PackedInt32Array(interaction_state.get("selected_indices", PackedInt32Array()))
			return not selected.has(index)
		"select_one_prep_item":
			return zone == &"prep"
		"select_one_baked_item":
			return zone == &"table"
		"select_one_customer_and_one_table_item":
			var raw_selected_targets: Array = interaction_state.get("selected_targets", [])
			var selected_targets: Array[Dictionary] = []
			for target_value in raw_selected_targets:
				var selected_target: Dictionary = target_value
				selected_targets.append(selected_target)
			for selected_target in selected_targets:
				var selected_zone: StringName = StringName(selected_target.get("zone", ""))
				var selected_index: int = int(selected_target.get("index", -1))
				if selected_zone == zone:
					return selected_index == index
			return zone == &"customer" or zone == &"table"
		"select_one_item":
			return zone == &"prep" or zone == &"oven"
		"select_one_customer":
			return zone == &"customer"
		_:
			return false

func _describe_item(item: ItemInstance) -> String:
	return "%s | Q%d | %s" % [item.get_display_name(), item.quality, _join_packed(item.get_all_tags())]

func _describe_customer_request(customer: CustomerInstance) -> String:
	var required_text: String = _join_packed(customer.get_preferences())
	var details: Array[String] = []
	if required_text != "none":
		details.append("Needs: %s" % required_text)
	var bonus_text: String = _join_packed(customer.get_bonus_tags())
	if bonus_text != "none":
		details.append("Likes: %s" % bonus_text)
	if customer.get_minimum_quality() > 0:
		details.append("Q>=%d" % customer.get_minimum_quality())
	if details.is_empty():
		return "Request: any servable pastry"
	return "Request: %s" % _join_strings(details)

func _join_strings(values: Array[String]) -> String:
	var output: String = ""
	for index in range(values.size()):
		if index > 0:
			output += " | "
		output += values[index]
	return output

func _join_packed(values: PackedStringArray) -> String:
	if values.is_empty():
		return "none"
	var output: String = ""
	for index in range(values.size()):
		if index > 0:
			output += ", "
		output += String(values[index])
	return output

func _make_section_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.text = text_value
	return label

func _make_text_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text_value
	return label

func _make_button(text_value: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 44)
	button.pressed.connect(callback)
	return button

func _make_texture_card(texture: Texture2D, caption: String) -> Control:
	var container: VBoxContainer = VBoxContainer.new()
	container.custom_minimum_size = Vector2(180, 180)
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(180, 120)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = texture
	container.add_child(texture_rect)
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = caption
	container.add_child(label)
	return container

func _load_texture(primary_path: String, fallback_path: String = "") -> Texture2D:
	if primary_path != "" and ResourceLoader.exists(primary_path):
		return load(primary_path) as Texture2D
	if fallback_path != "" and ResourceLoader.exists(fallback_path):
		return load(fallback_path) as Texture2D
	return null

func _clear_container(container: Node) -> void:
	var children: Array[Node] = []
	for child in container.get_children():
		children.append(child)
	for child in children:
		container.remove_child(child)
		child.queue_free()

func _on_continue_from_title_pressed() -> void:
	continue_from_title_requested.emit()

func _on_reset_profile_pressed() -> void:
	reset_profile_requested.emit()

func _on_open_dough_select_pressed() -> void:
	open_dough_select_requested.emit()

func _on_open_decoration_pressed() -> void:
	open_decoration_requested.emit()

func _on_close_decoration_pressed() -> void:
	close_decoration_requested.emit()

func _on_end_turn_pressed() -> void:
	end_turn_requested.emit()

func _on_continue_after_shop_pressed() -> void:
	continue_after_shop_requested.emit()

func _on_return_to_hub_pressed() -> void:
	return_to_hub_requested.emit()

func _on_start_boss_pressed() -> void:
	start_boss_requested.emit()
