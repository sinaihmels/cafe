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
signal focus_customer_requested(customer_index: int)
signal customer_item_requested(customer_index: int)
signal prep_item_requested(item_index: int)
signal oven_item_requested(slot_index: int)
signal table_item_requested(item_index: int)

const BOARD_FILL: Color = Color(0.95, 0.89, 0.78, 0.90)
const BOARD_BORDER: Color = Color(0.34, 0.23, 0.15, 0.96)
const BOARD_SHADOW: Color = Color(0.20, 0.13, 0.08, 0.88)
const BOARD_TEXT: Color = Color(0.20, 0.13, 0.10)
const BOARD_MUTED: Color = Color(0.38, 0.31, 0.26)
const BOARD_ACCENT: Color = Color(0.82, 0.45, 0.27, 0.98)
const BOARD_ACCENT_SOFT: Color = Color(0.98, 0.84, 0.72, 0.98)
const BOARD_GOOD: Color = Color(0.53, 0.66, 0.43, 0.98)
const BOARD_GOLD: Color = Color(0.87, 0.70, 0.35, 0.98)
const BOARD_DANGER: Color = Color(0.67, 0.29, 0.24, 0.98)
const BOARD_PANEL_DARK: Color = Color(0.20, 0.14, 0.10, 0.90)
const HAND_AREA_HEIGHT: float = 232.0
const HAND_CARD_WIDTH: float = 154.0
const HAND_CARD_HEIGHT: float = 214.0
const HAND_MIN_SPACING: float = 34.0
const HAND_IDEAL_SPACING: float = 94.0
const ZONE_CARD_WIDTH: float = 108.0
const ZONE_CARD_HEIGHT: float = 150.0
const CUSTOMER_PANEL_WIDTH: float = 364.0
const HUD_PANEL_WIDTH: float = 232.0

var _background: TextureRect
var _margin: MarginContainer
var _root: VBoxContainer
var _title_label: Label
var _status_label: Label
var _meta_label: Label
var _hero_row: HBoxContainer
var _content_scroll: ScrollContainer
var _content: VBoxContainer
var _encounter_layer: Control
var _hand_area: Control
var _hand_card_nodes: Array[Button] = []
var _hovered_hand_card_index: int = -1
var _selected_hand_card_index: int = -1
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

	_encounter_layer = Control.new()
	_encounter_layer.anchors_preset = PRESET_FULL_RECT
	_encounter_layer.anchor_right = 1.0
	_encounter_layer.anchor_bottom = 1.0
	_encounter_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_encounter_layer.visible = false
	_margin.add_child(_encounter_layer)

func render(session_service: SessionService, interaction_state: Dictionary = {}) -> void:
	_ensure_ui_built()
	if session_service.run_state.screen == GameEnums.Screen.ENCOUNTER:
		_root.visible = false
		_encounter_layer.visible = true
		_clear_container(_encounter_layer)
		_hand_card_nodes.clear()
		_hand_area = null
		_selected_hand_card_index = int(interaction_state.get("pending_card_index", -1))
		if _hovered_hand_card_index >= session_service.deck_state.hand.size():
			_hovered_hand_card_index = -1
		_render_encounter_screen(session_service, interaction_state)
		return

	_root.visible = true
	_encounter_layer.visible = false
	_clear_container(_encounter_layer)
	_hand_card_nodes.clear()
	_hand_area = null
	_hovered_hand_card_index = -1
	_selected_hand_card_index = -1
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

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _encounter_layer != null and _encounter_layer.visible and _hand_area != null:
		call_deferred("_layout_hand_cards")

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
	var board_root: VBoxContainer = VBoxContainer.new()
	board_root.anchors_preset = PRESET_FULL_RECT
	board_root.anchor_right = 1.0
	board_root.anchor_bottom = 1.0
	board_root.size_flags_horizontal = SIZE_EXPAND_FILL
	board_root.size_flags_vertical = SIZE_EXPAND_FILL
	board_root.add_theme_constant_override("separation", 14)
	_encounter_layer.add_child(board_root)

	var header_row: HBoxContainer = HBoxContainer.new()
	header_row.custom_minimum_size = Vector2(0, 170)
	header_row.add_theme_constant_override("separation", 14)
	board_root.add_child(header_row)

	header_row.add_child(_build_encounter_hud(session_service))

	var center_panel: PanelContainer = _make_board_panel("burnt")
	center_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	header_row.add_child(center_panel)
	var center_body: VBoxContainer = _board_panel_body(center_panel)
	var center_header: HBoxContainer = HBoxContainer.new()
	center_header.size_flags_horizontal = SIZE_EXPAND_FILL
	center_header.add_theme_constant_override("separation", 12)
	center_body.add_child(center_header)

	var center_title_col: VBoxContainer = VBoxContainer.new()
	center_title_col.size_flags_horizontal = SIZE_EXPAND_FILL
	center_title_col.add_theme_constant_override("separation", 4)
	center_header.add_child(center_title_col)
	center_title_col.add_child(_make_board_title("Kitchen Rush", Color(1.0, 0.97, 0.93), 28))
	center_title_col.add_child(_make_board_text("Prep the dough, bake it, collect it, and serve before patience runs out.", Color(1.0, 0.96, 0.92, 0.84), 15))

	var end_turn_button: Button = _make_board_button("End Turn", _on_end_turn_pressed, false, "primary")
	end_turn_button.custom_minimum_size = Vector2(148, 52)
	center_header.add_child(end_turn_button)

	var prompt: String = String(interaction_state.get("pending_prompt", ""))
	var prompt_panel: PanelContainer = _make_board_prompt(prompt if prompt != "" else "Choose a card below, then click the required spaces on the board.")
	prompt_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	center_body.add_child(prompt_panel)

	header_row.add_child(_build_customer_focus_panel(session_service, interaction_state))

	var board_area: Control = Control.new()
	board_area.size_flags_horizontal = SIZE_EXPAND_FILL
	board_area.size_flags_vertical = SIZE_EXPAND_FILL
	board_root.add_child(board_area)

	var zones_row: HBoxContainer = HBoxContainer.new()
	zones_row.anchors_preset = PRESET_FULL_RECT
	zones_row.anchor_right = 1.0
	zones_row.anchor_bottom = 1.0
	zones_row.offset_bottom = -68
	zones_row.size_flags_horizontal = SIZE_EXPAND_FILL
	zones_row.size_flags_vertical = SIZE_EXPAND_FILL
	zones_row.add_theme_constant_override("separation", 14)
	board_area.add_child(zones_row)

	zones_row.add_child(_build_prep_zone(session_service, interaction_state))
	zones_row.add_child(_build_oven_zone(session_service, interaction_state))
	zones_row.add_child(_build_table_zone(session_service, interaction_state))

	var deck_pile: PanelContainer = _build_pile_card("Deck", session_service.deck_state.draw_pile.size())
	deck_pile.anchor_left = 0.0
	deck_pile.anchor_right = 0.0
	deck_pile.offset_left = 12.0
	deck_pile.offset_right = 12.0 + deck_pile.custom_minimum_size.x
	board_area.add_child(deck_pile)

	var discard_pile: PanelContainer = _build_pile_card("Discard", session_service.deck_state.discard_pile.size())
	discard_pile.anchor_left = 1.0
	discard_pile.anchor_right = 1.0
	discard_pile.offset_left = -discard_pile.custom_minimum_size.x - 12.0
	discard_pile.offset_right = -12.0
	board_area.add_child(discard_pile)

	var hand_shell: Control = Control.new()
	hand_shell.custom_minimum_size = Vector2(0, HAND_AREA_HEIGHT)
	hand_shell.size_flags_horizontal = SIZE_EXPAND_FILL
	board_root.add_child(hand_shell)

	_hand_area = Control.new()
	_hand_area.anchors_preset = PRESET_FULL_RECT
	_hand_area.anchor_right = 1.0
	_hand_area.anchor_bottom = 1.0
	_hand_area.offset_left = 18
	_hand_area.offset_top = 6
	_hand_area.offset_right = -18
	_hand_area.offset_bottom = -6
	_hand_area.mouse_filter = Control.MOUSE_FILTER_PASS
	hand_shell.add_child(_hand_area)

	_build_hand_fan(session_service, interaction_state)
	call_deferred("_layout_hand_cards")

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

func _build_encounter_hud(session_service: SessionService) -> PanelContainer:
	var hud_panel: PanelContainer = _make_board_panel("paper")
	hud_panel.custom_minimum_size = Vector2(HUD_PANEL_WIDTH, 0)
	var body: VBoxContainer = _board_panel_body(hud_panel)

	body.add_child(_make_board_title("Energy", BOARD_TEXT, 18))
	body.add_child(_make_board_title("%d / %d" % [session_service.player_state.energy, session_service.player_state.max_energy], BOARD_ACCENT, 34))
	body.add_child(_make_board_text("Buffs", BOARD_TEXT, 16))

	var buff_lines: Array[String] = _build_modifier_lines(session_service)
	if buff_lines.is_empty():
		body.add_child(_make_board_text("No active buffs.", BOARD_MUTED, 14))
	else:
		for buff_line in buff_lines:
			body.add_child(_make_board_text(buff_line, BOARD_MUTED, 14))

	var stat_flow: HFlowContainer = HFlowContainer.new()
	stat_flow.add_theme_constant_override("h_separation", 8)
	stat_flow.add_theme_constant_override("v_separation", 8)
	body.add_child(stat_flow)
	stat_flow.add_child(_make_board_stat_chip("Stress", "%d/%d" % [session_service.player_state.stress, session_service.player_state.max_stress], _stress_chip_tone(session_service)))
	stat_flow.add_child(_make_board_stat_chip("Rep", str(session_service.player_state.reputation), "accent"))
	stat_flow.add_child(_make_board_stat_chip("Tips", str(session_service.player_state.tips), "gold"))
	stat_flow.add_child(_make_board_stat_chip("Day", str(session_service.run_state.day_number), "paper"))
	stat_flow.add_child(_make_board_stat_chip("Turn", str(session_service.combat_state.turn_number), "paper"))
	return hud_panel

func _build_modifier_lines(session_service: SessionService) -> Array[String]:
	var lines: Array[String] = []
	var all_modifiers: Array = []
	all_modifiers.append_array(session_service.player_state.passive_modifiers)
	all_modifiers.append_array(session_service.player_state.active_buffs)
	for modifier_value in all_modifiers:
		var instance: ModifierInstance = modifier_value
		if instance == null:
			continue
		var definition: ModifierDef = session_service.content_library.get_modifier(instance.modifier_id)
		if definition == null:
			continue
		var line: String = definition.display_name
		if instance.stacks > 1:
			line += " x%d" % instance.stacks
		if instance.remaining_turns > 0:
			line += " (%dt)" % instance.remaining_turns
		lines.append(line)
	return lines

func _build_customer_focus_panel(session_service: SessionService, interaction_state: Dictionary) -> PanelContainer:
	var customer_panel: PanelContainer = _make_board_panel("paper")
	customer_panel.custom_minimum_size = Vector2(CUSTOMER_PANEL_WIDTH, 0)
	var body: VBoxContainer = _board_panel_body(customer_panel)
	body.add_child(_make_board_title("Customer", BOARD_TEXT, 18))

	if session_service.combat_state.active_customers.is_empty():
		body.add_child(_make_board_text("No active customers.", BOARD_MUTED, 14))
		return customer_panel

	var focus_index: int = int(interaction_state.get("focused_customer_index", 0))
	focus_index = clampi(focus_index, 0, session_service.combat_state.active_customers.size() - 1)
	var customer: CustomerInstance = session_service.combat_state.active_customers[focus_index]

	var hero_row: HBoxContainer = HBoxContainer.new()
	hero_row.add_theme_constant_override("separation", 12)
	body.add_child(hero_row)

	var portrait_shell: PanelContainer = _make_board_panel("accent_soft")
	portrait_shell.custom_minimum_size = Vector2(130, 130)
	portrait_shell.add_theme_stylebox_override("panel", _make_board_stylebox(BOARD_ACCENT_SOFT, BOARD_BORDER, 64, 2))
	hero_row.add_child(portrait_shell)
	var portrait_body: VBoxContainer = _board_panel_body(portrait_shell)
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(98, 98)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture = _load_texture(ArtCatalog.customer_path(customer.customer_def.customer_id), ArtCatalog.customer_placeholder_path())
	portrait_body.alignment = BoxContainer.ALIGNMENT_CENTER
	portrait_body.add_child(portrait)

	var info_col: VBoxContainer = VBoxContainer.new()
	info_col.size_flags_horizontal = SIZE_EXPAND_FILL
	info_col.add_theme_constant_override("separation", 6)
	hero_row.add_child(info_col)
	info_col.add_child(_make_board_title(customer.get_display_name(), BOARD_TEXT, 24))
	info_col.add_child(_make_board_stat_chip("Patience", str(customer.current_patience), _patience_chip_tone(customer.current_patience)))
	info_col.add_child(_make_board_text(_describe_customer_request(customer), BOARD_MUTED, 14))

	var select_enabled: bool = _is_zone_targetable(interaction_state, &"customer", focus_index) or _is_target_selected(interaction_state, &"customer", focus_index)
	var select_label: String = "Customer Selected" if _is_target_selected(interaction_state, &"customer", focus_index) else "Select Customer"
	body.add_child(_make_board_button(select_label, func() -> void: focus_customer_requested.emit(focus_index), not select_enabled, "primary"))

	var selector_row: HFlowContainer = HFlowContainer.new()
	selector_row.add_theme_constant_override("h_separation", 8)
	selector_row.add_theme_constant_override("v_separation", 8)
	body.add_child(selector_row)
	for customer_index in range(session_service.combat_state.active_customers.size()):
		var selector_index: int = customer_index
		var selector_customer: CustomerInstance = session_service.combat_state.active_customers[customer_index]
		var selector_button: Button = _make_board_button(
			"%d\n%s" % [customer_index + 1, selector_customer.get_display_name()],
			func() -> void: focus_customer_requested.emit(selector_index),
			false,
			"accent" if customer_index == focus_index else "secondary"
		)
		selector_button.custom_minimum_size = Vector2(84, 58)
		selector_row.add_child(selector_button)
	return customer_panel

func _build_prep_zone(session_service: SessionService, interaction_state: Dictionary) -> PanelContainer:
	var zone: PanelContainer = _make_board_zone_panel("Prep", "%d / %d items" % [session_service.cafe_state.prep_items.size(), session_service.cafe_state.prep_space_capacity])
	var content: VBoxContainer = _board_panel_body(zone)
	var area: Control = _make_zone_area()
	content.add_child(area)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.anchors_preset = PRESET_CENTER
	grid.anchor_left = 0.5
	grid.anchor_top = 0.5
	grid.anchor_right = 0.5
	grid.anchor_bottom = 0.5
	grid.position = Vector2(-((ZONE_CARD_WIDTH * 3.0) + 24.0) * 0.5, -145.0)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	area.add_child(grid)

	if session_service.cafe_state.prep_items.is_empty():
		area.add_child(_make_zone_empty_label("Prep is empty."))
	else:
		for prep_index in range(session_service.cafe_state.prep_items.size()):
			var prep_item: ItemInstance = session_service.cafe_state.prep_items[prep_index]
			var prep_item_index: int = prep_index
			var wrapper: Control = _make_tilted_card_wrapper(ZONE_CARD_WIDTH, ZONE_CARD_HEIGHT, _spread_rotation(prep_index, session_service.cafe_state.prep_items.size(), 7.0))
			var tone: String = "accent" if _is_target_selected(interaction_state, &"prep", prep_index) else "paper"
			var button: Button = _make_surface_card_button(
				prep_item.get_display_name(),
				"Q%d | %s" % [prep_item.quality, _join_packed(prep_item.get_all_tags())],
				_load_texture(ArtCatalog.dish_base_path(), ArtCatalog.dish_placeholder_path()),
				func() -> void: prep_item_requested.emit(prep_item_index),
				not _is_zone_targetable(interaction_state, &"prep", prep_index),
				tone
			)
			button.position = Vector2(12, 12)
			wrapper.add_child(button)
			grid.add_child(wrapper)

	var energy_coin: PanelContainer = _make_board_panel("accent_soft")
	energy_coin.custom_minimum_size = Vector2(72, 72)
	energy_coin.add_theme_stylebox_override("panel", _make_board_stylebox(BOARD_ACCENT_SOFT, BOARD_BORDER, 36, 2))
	energy_coin.anchor_left = 0.0
	energy_coin.anchor_top = 1.0
	energy_coin.anchor_right = 0.0
	energy_coin.anchor_bottom = 1.0
	energy_coin.offset_left = 16.0
	energy_coin.offset_top = -88.0
	energy_coin.offset_right = 88.0
	energy_coin.offset_bottom = -16.0
	var energy_body: VBoxContainer = _board_panel_body(energy_coin)
	energy_body.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_body.add_child(_make_board_text("Mana", BOARD_TEXT, 12))
	energy_body.add_child(_make_board_title(str(session_service.player_state.energy), BOARD_ACCENT, 26))
	area.add_child(energy_coin)
	return zone

func _build_oven_zone(session_service: SessionService, interaction_state: Dictionary) -> PanelContainer:
	var zone: PanelContainer = _make_board_zone_panel("Oven", "%d slots" % session_service.cafe_state.oven_slots.size())
	var content: VBoxContainer = _board_panel_body(zone)
	var area: Control = _make_zone_area()
	content.add_child(area)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.anchors_preset = PRESET_CENTER
	row.anchor_left = 0.5
	row.anchor_top = 0.5
	row.anchor_right = 0.5
	row.anchor_bottom = 0.5
	row.position = Vector2(-132, -112)
	row.add_theme_constant_override("separation", 12)
	area.add_child(row)

	for slot_index in range(session_service.cafe_state.oven_slots.size()):
		var slot: OvenSlotState = session_service.cafe_state.oven_slots[slot_index]
		if slot.item == null:
			row.add_child(_make_static_slot_card("Slot %d" % (slot_index + 1), "Empty"))
			continue
		var oven_slot_index: int = slot_index
		var ready: bool = slot.remaining_turns <= 0
		var button: Button = _make_surface_card_button(
			slot.item.get_display_name(),
			"Ready" if ready else "%d turn left" % slot.remaining_turns,
			_load_texture(ArtCatalog.oven_base_path(), ArtCatalog.oven_placeholder_path()),
			func() -> void: oven_item_requested.emit(oven_slot_index),
			not (_is_zone_targetable(interaction_state, &"oven", slot_index) or ready),
			"accent" if ready or _is_target_selected(interaction_state, &"oven", slot_index) else "paper"
		)
		row.add_child(button)

	return zone

func _build_table_zone(session_service: SessionService, interaction_state: Dictionary) -> PanelContainer:
	var zone: PanelContainer = _make_board_zone_panel("Table", "%d / %d items" % [session_service.cafe_state.table_items.size(), session_service.cafe_state.serving_table_capacity])
	var content: VBoxContainer = _board_panel_body(zone)
	var area: Control = _make_zone_area()
	content.add_child(area)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.anchors_preset = PRESET_CENTER
	row.anchor_left = 0.5
	row.anchor_top = 0.5
	row.anchor_right = 0.5
	row.anchor_bottom = 0.5
	row.position = Vector2(-175, -110)
	row.add_theme_constant_override("separation", 12)
	area.add_child(row)

	if session_service.cafe_state.table_items.is_empty():
		area.add_child(_make_zone_empty_label("Table is empty."))
	else:
		for table_index in range(session_service.cafe_state.table_items.size()):
			var table_item: ItemInstance = session_service.cafe_state.table_items[table_index]
			var table_item_index: int = table_index
			var wrapper: Control = _make_tilted_card_wrapper(ZONE_CARD_WIDTH, ZONE_CARD_HEIGHT, _spread_rotation(table_index, session_service.cafe_state.table_items.size(), 8.0))
			var button: Button = _make_surface_card_button(
				table_item.get_display_name(),
				"Q%d | %s" % [table_item.quality, _join_packed(table_item.get_all_tags())],
				_load_texture(ArtCatalog.dish_placeholder_path(), ArtCatalog.dish_base_path()),
				func() -> void: table_item_requested.emit(table_item_index),
				not _is_zone_targetable(interaction_state, &"table", table_index),
				"accent" if _is_target_selected(interaction_state, &"table", table_index) else "paper"
			)
			button.position = Vector2(12, 12)
			wrapper.add_child(button)
			row.add_child(wrapper)

	return zone

func _build_hand_fan(session_service: SessionService, interaction_state: Dictionary) -> void:
	if _hand_area == null:
		return
	for card_index in range(session_service.deck_state.hand.size()):
		var card: CardInstance = session_service.deck_state.hand[card_index]
		var hand_card_index: int = card_index
		var card_button: Button = _make_hand_card_button(session_service, card, interaction_state, hand_card_index)
		card_button.mouse_entered.connect(func() -> void: _set_hovered_hand_card(hand_card_index))
		card_button.mouse_exited.connect(func() -> void: _clear_hovered_hand_card(hand_card_index))
		card_button.pressed.connect(func() -> void: play_card_requested.emit(hand_card_index))
		_hand_area.add_child(card_button)
		_hand_card_nodes.append(card_button)

func _layout_hand_cards() -> void:
	if _hand_area == null or _hand_card_nodes.is_empty():
		return
	var hand_count: int = _hand_card_nodes.size()
	var available_width: float = maxf(180.0, _hand_area.size.x - 24.0)
	var base_width: float = HAND_CARD_WIDTH
	var base_height: float = HAND_CARD_HEIGHT
	var desired_spacing: float = HAND_IDEAL_SPACING if hand_count <= 5 else 64.0
	var spacing: float = desired_spacing
	if hand_count > 1 and (base_width + (hand_count - 1) * spacing) > available_width:
		spacing = maxf(HAND_MIN_SPACING, (available_width - base_width) / float(hand_count - 1))
	if hand_count > 1 and (base_width + (hand_count - 1) * spacing) > available_width:
		var shrunk_width: float = maxf(124.0, available_width - (hand_count - 1) * spacing)
		var width_scale: float = shrunk_width / base_width
		base_width = shrunk_width
		base_height *= width_scale

	var total_span: float = spacing * float(maxi(0, hand_count - 1))
	var start_x: float = (_hand_area.size.x - (base_width + total_span)) * 0.5
	for card_index in range(_hand_card_nodes.size()):
		var card_button: Button = _hand_card_nodes[card_index]
		var normalized: float = 0.0
		if hand_count > 1:
			normalized = (float(card_index) / float(hand_count - 1)) * 2.0 - 1.0
		var curve_drop: float = pow(absf(normalized), 1.4) * 34.0
		var is_selected: bool = card_index == _selected_hand_card_index
		var is_hovered: bool = card_index == _hovered_hand_card_index
		var lift: float = 0.0
		if is_selected:
			lift = 40.0
		elif is_hovered:
			lift = 28.0
		var rotation_multiplier: float = 1.0
		if is_selected:
			rotation_multiplier = 0.0
		elif is_hovered:
			rotation_multiplier = 0.35
		card_button.size = Vector2(base_width, base_height)
		card_button.position = Vector2(start_x + spacing * float(card_index), maxf(6.0, _hand_area.size.y - base_height - 12.0 + curve_drop - lift))
		card_button.pivot_offset = card_button.size * 0.5
		card_button.rotation_degrees = normalized * 13.0 * rotation_multiplier
		card_button.z_index = 100 + card_index
		if is_hovered:
			card_button.z_index = 250
		elif is_selected:
			card_button.z_index = 225

func _set_hovered_hand_card(card_index: int) -> void:
	if _hovered_hand_card_index == card_index:
		return
	_hovered_hand_card_index = card_index
	_layout_hand_cards()

func _clear_hovered_hand_card(card_index: int) -> void:
	if _hovered_hand_card_index != card_index:
		return
	_hovered_hand_card_index = -1
	_layout_hand_cards()

func _make_board_zone_panel(title_text: String, subtitle_text: String) -> PanelContainer:
	var panel: PanelContainer = _make_board_panel("paper")
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_vertical = SIZE_EXPAND_FILL
	var body: VBoxContainer = _board_panel_body(panel)
	body.add_child(_make_board_title(title_text, BOARD_TEXT, 24))
	body.add_child(_make_board_text(subtitle_text, BOARD_MUTED, 14))
	return panel

func _make_zone_area() -> Control:
	var area: Control = Control.new()
	area.size_flags_horizontal = SIZE_EXPAND_FILL
	area.size_flags_vertical = SIZE_EXPAND_FILL
	area.mouse_filter = Control.MOUSE_FILTER_PASS
	return area

func _make_zone_empty_label(text_value: String) -> Label:
	var label: Label = _make_board_text(text_value, BOARD_MUTED, 15)
	label.anchors_preset = PRESET_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.position = Vector2(-80, -12)
	return label

func _make_tilted_card_wrapper(card_width: float, card_height: float, rotation_value: float) -> Control:
	var wrapper: Control = Control.new()
	wrapper.custom_minimum_size = Vector2(card_width + 24.0, card_height + 24.0)
	wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
	wrapper.pivot_offset = wrapper.custom_minimum_size * 0.5
	wrapper.rotation_degrees = rotation_value
	return wrapper

func _make_surface_card_button(
	title_text: String,
	detail_text: String,
	texture: Texture2D,
	callback: Callable,
	disabled: bool,
	tone: String
) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = Vector2(ZONE_CARD_WIDTH, ZONE_CARD_HEIGHT)
	button.size = Vector2(ZONE_CARD_WIDTH, ZONE_CARD_HEIGHT)
	button.size_flags_horizontal = SIZE_FILL
	button.size_flags_vertical = SIZE_FILL
	button.text = ""
	button.disabled = disabled
	button.add_theme_stylebox_override("normal", _make_board_stylebox(_tone_fill_for_card(tone), _tone_border_for_card(tone), 18, 2))
	button.add_theme_stylebox_override("hover", _make_board_stylebox(_tone_fill_for_card(tone).lightened(0.05), _tone_border_for_card(tone), 18, 2))
	button.add_theme_stylebox_override("pressed", _make_board_stylebox(_tone_fill_for_card(tone).darkened(0.05), _tone_border_for_card(tone), 18, 2))
	button.add_theme_stylebox_override("disabled", _make_board_stylebox(Color(0.82, 0.78, 0.71, 0.60), Color(0.52, 0.46, 0.40, 0.55), 18, 2))
	if callback.is_valid():
		button.pressed.connect(callback)

	var margin: MarginContainer = MarginContainer.new()
	margin.anchors_preset = PRESET_FULL_RECT
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	button.add_child(margin)

	var body: VBoxContainer = VBoxContainer.new()
	body.anchors_preset = PRESET_FULL_RECT
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	margin.add_child(body)

	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.custom_minimum_size = Vector2(0, 64)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture = texture
	body.add_child(texture_rect)
	body.add_child(_make_board_title(title_text, BOARD_TEXT, 15))
	body.add_child(_make_board_text(detail_text, BOARD_MUTED, 12))
	return button

func _make_static_slot_card(title_text: String, detail_text: String) -> PanelContainer:
	var panel: PanelContainer = _make_board_panel("quiet")
	panel.custom_minimum_size = Vector2(ZONE_CARD_WIDTH, ZONE_CARD_HEIGHT)
	var body: VBoxContainer = _board_panel_body(panel)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_make_board_title(title_text, BOARD_TEXT, 15))
	body.add_child(_make_board_text(detail_text, BOARD_MUTED, 12))
	return panel

func _build_pile_card(title_text: String, count: int) -> PanelContainer:
	var panel: PanelContainer = _make_board_panel("burnt")
	panel.custom_minimum_size = Vector2(94, 120)
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -136
	panel.offset_bottom = -16
	var body: VBoxContainer = _board_panel_body(panel)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_make_board_text(title_text, Color(1.0, 0.95, 0.90), 14))
	body.add_child(_make_board_title(str(count), Color(1.0, 0.98, 0.95), 28))
	return panel

func _make_hand_card_button(session_service: SessionService, card: CardInstance, interaction_state: Dictionary, card_index: int) -> Button:
	var selected: bool = int(interaction_state.get("pending_card_index", -1)) == card_index
	var playable: bool = card.get_cost() <= session_service.player_state.energy
	var button: Button = Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not playable
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _make_board_stylebox(BOARD_FILL if not selected else BOARD_ACCENT_SOFT, BOARD_ACCENT if selected else BOARD_BORDER, 18, 2))
	button.add_theme_stylebox_override("hover", _make_board_stylebox(BOARD_ACCENT_SOFT, BOARD_ACCENT, 18, 2))
	button.add_theme_stylebox_override("pressed", _make_board_stylebox(BOARD_ACCENT_SOFT.darkened(0.05), BOARD_ACCENT, 18, 2))
	button.add_theme_stylebox_override("disabled", _make_board_stylebox(Color(0.88, 0.84, 0.76, 0.72), Color(0.58, 0.52, 0.46, 0.54), 18, 2))

	var margin: MarginContainer = MarginContainer.new()
	margin.anchors_preset = PRESET_FULL_RECT
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	button.add_child(margin)

	var body: VBoxContainer = VBoxContainer.new()
	body.anchors_preset = PRESET_FULL_RECT
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 6)
	body.add_child(top_row)
	top_row.add_child(_make_board_stat_chip("Cost", str(card.get_cost()), "accent"))
	var tag_label: Label = _make_board_text(_join_packed(card.get_all_tags()), BOARD_MUTED, 11)
	tag_label.size_flags_horizontal = SIZE_EXPAND_FILL
	top_row.add_child(tag_label)

	var art: TextureRect = TextureRect.new()
	art.custom_minimum_size = Vector2(0, 78)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = _load_texture(ArtCatalog.card_path(card.card_def.card_id), ArtCatalog.card_base_path())
	body.add_child(art)
	body.add_child(_make_board_title(card.get_display_name(), BOARD_TEXT, 16))
	body.add_child(_make_board_text(card.get_preview_text(), BOARD_MUTED, 12))
	return button

func _make_board_panel(tone: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_board_stylebox(_panel_fill(tone), _panel_border(tone), 20, 2))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)
	panel.set_meta("body", body)
	return panel

func _board_panel_body(panel: PanelContainer) -> VBoxContainer:
	return panel.get_meta("body") as VBoxContainer

func _make_board_stylebox(fill_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = fill_color
	style_box.border_color = border_color
	style_box.set_corner_radius_all(radius)
	style_box.set_border_width_all(border_width)
	style_box.shadow_color = BOARD_SHADOW
	style_box.shadow_size = 6
	style_box.shadow_offset = Vector2(0, 2)
	return style_box

func _make_board_title(text_value: String, color_value: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color_value)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _make_board_text(text_value: String, color_value: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color_value)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _make_board_prompt(text_value: String) -> PanelContainer:
	var prompt_panel: PanelContainer = _make_board_panel("accent_soft")
	var body: VBoxContainer = _board_panel_body(prompt_panel)
	body.add_child(_make_board_text(text_value, BOARD_TEXT, 15))
	return prompt_panel

func _make_board_button(text_value: String, callback: Callable, disabled: bool, tone: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, 42)
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _make_board_stylebox(_button_fill(tone), _button_border(tone), 14, 2))
	button.add_theme_stylebox_override("hover", _make_board_stylebox(_button_fill(tone).lightened(0.06), _button_border(tone), 14, 2))
	button.add_theme_stylebox_override("pressed", _make_board_stylebox(_button_fill(tone).darkened(0.06), _button_border(tone), 14, 2))
	button.add_theme_stylebox_override("disabled", _make_board_stylebox(Color(0.84, 0.80, 0.74, 0.60), Color(0.54, 0.49, 0.43, 0.55), 14, 2))
	button.add_theme_color_override("font_color", _button_font(tone))
	button.add_theme_color_override("font_disabled_color", Color(_button_font(tone).r, _button_font(tone).g, _button_font(tone).b, 0.55))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if callback.is_valid():
		button.pressed.connect(callback)
	return button

func _make_board_stat_chip(label_text: String, value_text: String, tone: String) -> PanelContainer:
	var chip: PanelContainer = _make_board_panel(tone)
	chip.custom_minimum_size = Vector2(0, 0)
	var body: VBoxContainer = _board_panel_body(chip)
	body.add_child(_make_boardText_label(label_text.to_upper(), _chip_title_color(tone), 10))
	body.add_child(_make_board_title(value_text, _chip_value_color(tone), 17))
	return chip

func _make_boardText_label(text_value: String, color_value: Color, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.add_theme_color_override("font_color", color_value)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _panel_fill(tone: String) -> Color:
	match tone:
		"burnt":
			return BOARD_PANEL_DARK
		"accent":
			return BOARD_ACCENT
		"accent_soft":
			return BOARD_ACCENT_SOFT
		"gold":
			return BOARD_GOLD
		"danger":
			return BOARD_DANGER
		"quiet":
			return Color(0.90, 0.86, 0.78, 0.90)
		_:
			return BOARD_FILL

func _panel_border(tone: String) -> Color:
	match tone:
		"burnt":
			return Color(0.46, 0.34, 0.27, 0.95)
		"accent":
			return Color(1.0, 0.83, 0.74, 0.98)
		"accent_soft":
			return BOARD_BORDER
		"gold":
			return Color(1.0, 0.91, 0.72, 0.98)
		"danger":
			return Color(0.96, 0.75, 0.70, 0.98)
		"quiet":
			return Color(0.63, 0.55, 0.47, 0.95)
		_:
			return BOARD_BORDER

func _button_fill(tone: String) -> Color:
	match tone:
		"primary":
			return BOARD_ACCENT
		"accent":
			return BOARD_ACCENT_SOFT
		"secondary":
			return Color(0.91, 0.85, 0.76, 0.98)
		_:
			return BOARD_ACCENT

func _button_border(tone: String) -> Color:
	match tone:
		"primary":
			return Color(1.0, 0.83, 0.74, 0.98)
		"accent":
			return BOARD_BORDER
		"secondary":
			return BOARD_BORDER
		_:
			return BOARD_BORDER

func _button_font(tone: String) -> Color:
	match tone:
		"primary":
			return Color(1.0, 0.98, 0.95)
		"accent", "secondary":
			return BOARD_TEXT
		_:
			return BOARD_TEXT

func _tone_fill_for_card(tone: String) -> Color:
	match tone:
		"accent":
			return BOARD_ACCENT_SOFT
		_:
			return BOARD_FILL

func _tone_border_for_card(tone: String) -> Color:
	match tone:
		"accent":
			return BOARD_ACCENT
		_:
			return BOARD_BORDER

func _chip_title_color(tone: String) -> Color:
	match tone:
		"gold", "accent", "danger":
			return Color(1.0, 0.97, 0.93, 0.88)
		_:
			return BOARD_MUTED

func _chip_value_color(tone: String) -> Color:
	match tone:
		"gold", "accent", "danger":
			return Color(1.0, 0.98, 0.96)
		_:
			return BOARD_TEXT

func _stress_chip_tone(session_service: SessionService) -> String:
	if session_service.player_state.stress * 3 <= session_service.player_state.max_stress:
		return "danger"
	if session_service.player_state.stress * 2 <= session_service.player_state.max_stress:
		return "gold"
	return "paper"

func _patience_chip_tone(current_patience: int) -> String:
	if current_patience <= 1:
		return "danger"
	if current_patience <= 2:
		return "gold"
	return "accent"

func _spread_rotation(index: int, total: int, max_rotation: float) -> float:
	if total <= 1:
		return 0.0
	var normalized: float = (float(index) / float(total - 1)) * 2.0 - 1.0
	return normalized * max_rotation

func _is_target_selected(interaction_state: Dictionary, zone: StringName, index: int) -> bool:
	var raw_selected_targets: Array = interaction_state.get("selected_targets", [])
	for target_value in raw_selected_targets:
		var selected_target: Dictionary = target_value
		if StringName(selected_target.get("zone", "")) == zone and int(selected_target.get("index", -1)) == index:
			return true
	return false

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
