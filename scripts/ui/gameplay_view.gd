class_name GameplayView
extends Control

signal end_turn_requested()
signal play_card_requested(card_index: int)
signal prep_item_requested(item_index: int)
signal oven_item_requested(slot_index: int)
signal table_item_requested(item_index: int)
signal serve_requested(customer_index: int, item_index: int)
signal reward_requested(reward_id: StringName)
signal event_option_requested(option_id: StringName)

@onready var _day_label: Label = get_node("MarginContainer/Root/Sidebar/DayLabel") as Label
@onready var _phase_label: Label = get_node("MarginContainer/Root/Sidebar/PhaseLabel") as Label
@onready var _turn_label: Label = get_node("MarginContainer/Root/Sidebar/TurnLabel") as Label
@onready var _energy_label: Label = get_node("MarginContainer/Root/Sidebar/EnergyLabel") as Label
@onready var _reputation_label: Label = get_node("MarginContainer/Root/Sidebar/ReputationLabel") as Label
@onready var _chaos_label: Label = get_node("MarginContainer/Root/Sidebar/ChaosLabel") as Label
@onready var _zones_label: RichTextLabel = get_node("MarginContainer/Root/Sidebar/ZonesLabel") as RichTextLabel
@onready var _status_label: Label = get_node("MarginContainer/Root/MainColumn/StatusLabel") as Label
@onready var _customers_container: VBoxContainer = get_node("MarginContainer/Root/MainColumn/CustomersScroll/CustomersContainer") as VBoxContainer
@onready var _prep_container: VBoxContainer = get_node("MarginContainer/Root/MainColumn/ZonesRow/PrepPanel/PrepMargin/PrepColumn/PrepContainer") as VBoxContainer
@onready var _oven_container: VBoxContainer = get_node("MarginContainer/Root/MainColumn/ZonesRow/OvenPanel/OvenMargin/OvenColumn/OvenContainer") as VBoxContainer
@onready var _table_container: VBoxContainer = get_node("MarginContainer/Root/MainColumn/ZonesRow/TablePanel/TableMargin/TableColumn/TableContainer") as VBoxContainer
@onready var _reward_container: VBoxContainer = get_node("MarginContainer/Root/MainColumn/RewardContainer") as VBoxContainer
@onready var _event_container: VBoxContainer = get_node("MarginContainer/Root/MainColumn/EventContainer") as VBoxContainer
@onready var _hand_container: VBoxContainer = get_node("MarginContainer/Root/MainColumn/PanelContainer/HandMargin/HandColumn/HandScroll/HandContainer") as VBoxContainer
@onready var _end_turn_button: Button = get_node("MarginContainer/Root/Sidebar/EndTurnButton") as Button
@onready var _reward_header: Label = get_node("MarginContainer/Root/MainColumn/RewardHeader") as Label
@onready var _event_header: Label = get_node("MarginContainer/Root/MainColumn/EventHeader") as Label

func _ready() -> void:
	_end_turn_button.pressed.connect(_on_end_turn_pressed)

func render(
	session_service: SessionService,
	status_message: String = "",
	interaction_state: Dictionary = {}
) -> void:
	if _day_label == null or _status_label == null or _hand_container == null:
		push_error("GameplayView is missing required UI nodes.")
		return
	_day_label.text = "Day %d" % session_service.run_state.day_number
	_phase_label.text = "Phase: %s" % _run_phase_name(session_service.run_state.run_phase)
	_turn_label.text = "Turn: %d (%s)" % [
		session_service.combat_state.turn_number,
		_turn_state_name(session_service.combat_state.turn_state),
	]
	_energy_label.text = "Energy: %d / %d" % [
		session_service.player_state.energy,
		session_service.player_state.max_energy,
	]
	_reputation_label.text = "Reputation: %d / %d" % [
		session_service.player_state.reputation,
		session_service.player_state.max_reputation,
	]
	_chaos_label.text = "Chaos: %d" % session_service.player_state.chaos
	_zones_label.text = _build_zone_text(session_service.cafe_state)
	_status_label.text = status_message if status_message != "" else _default_status(session_service, interaction_state)
	_render_customers(session_service, interaction_state)
	_render_prep(session_service, interaction_state)
	_render_oven(session_service, interaction_state)
	_render_table(session_service, interaction_state)
	_render_rewards(session_service.run_state.pending_reward_ids)
	_render_event(
		session_service.run_state.pending_event_description,
		session_service.run_state.pending_event_option_ids
	)
	_render_hand(
		session_service.deck_state.hand,
		session_service.player_state.energy,
		session_service.run_state.run_phase == GameEnums.RunPhase.GAMEPLAY,
		interaction_state
	)
	_end_turn_button.disabled = (
		session_service.run_state.run_phase != GameEnums.RunPhase.GAMEPLAY
		or interaction_state.get("pending_card_index", -1) != -1
	)

func _build_zone_text(cafe_state: CafeState) -> String:
	return "[b]Zones[/b]\nPrep %d/inf\nTable %d/%d\nOven %d/%d" % [
		cafe_state.prep_items.size(),
		cafe_state.table_items.size(),
		cafe_state.serving_table_capacity,
		_count_occupied_oven_slots(cafe_state.oven_slots),
		cafe_state.oven_capacity,
	]

func _render_customers(session_service: SessionService, interaction_state: Dictionary) -> void:
	_clear_container(_customers_container)
	if session_service.combat_state.active_customers.is_empty():
		_customers_container.add_child(_make_info_label("No active customers."))
		return
	var gameplay_active: bool = (
		session_service.run_state.run_phase == GameEnums.RunPhase.GAMEPLAY
		and interaction_state.get("pending_card_index", -1) == -1
	)
	for customer_index: int in range(session_service.combat_state.active_customers.size()):
		var customer: CustomerInstance = session_service.combat_state.active_customers[customer_index]
		var panel: VBoxContainer = VBoxContainer.new()
		panel.add_theme_constant_override("separation", 6)
		var label: Label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "%s\nRequest: %s\nPatience: %d" % [
			customer.get_display_name(),
			_format_preferences(customer.get_preferences()),
			customer.current_patience,
		]
		panel.add_child(label)
		if session_service.cafe_state.table_items.is_empty():
			panel.add_child(_make_info_label("No baked items on the table to serve."))
		else:
			for item_index: int in range(session_service.cafe_state.table_items.size()):
				var item: ItemInstance = session_service.cafe_state.table_items[item_index]
				var button: Button = Button.new()
				button.text = "Serve %s" % item.get_display_name()
				button.disabled = not gameplay_active
				button.pressed.connect(_on_serve_pressed.bind(customer_index, item_index))
				panel.add_child(button)
		_customers_container.add_child(panel)

func _render_prep(session_service: SessionService, interaction_state: Dictionary) -> void:
	_clear_container(_prep_container)
	if session_service.cafe_state.prep_items.is_empty():
		_prep_container.add_child(_make_info_label("Prep is empty."))
		return
	for item_index: int in range(session_service.cafe_state.prep_items.size()):
		var item: ItemInstance = session_service.cafe_state.prep_items[item_index]
		var button: Button = Button.new()
		button.text = _describe_item(item)
		button.disabled = not _is_zone_targetable(interaction_state, &"prep", item_index)
		button.pressed.connect(_on_prep_item_pressed.bind(item_index))
		_prep_container.add_child(button)

func _render_oven(session_service: SessionService, interaction_state: Dictionary) -> void:
	_clear_container(_oven_container)
	var gameplay_active: bool = (
		session_service.run_state.run_phase == GameEnums.RunPhase.GAMEPLAY
		and interaction_state.get("pending_card_index", -1) == -1
	)
	for slot_index: int in range(session_service.cafe_state.oven_slots.size()):
		var slot: OvenSlotState = session_service.cafe_state.oven_slots[slot_index]
		if slot.item == null:
			_oven_container.add_child(_make_info_label("Slot %d: Empty" % [slot_index + 1]))
			continue
		var button: Button = Button.new()
		var ready_to_collect: bool = slot.remaining_turns <= 0
		var status: String = "Ready to collect" if ready_to_collect else "%d turn left" % [slot.remaining_turns]
		button.text = "Slot %d: %s (%s)" % [slot_index + 1, slot.item.get_display_name(), status]
		button.disabled = not (
			_is_zone_targetable(interaction_state, &"oven", slot_index)
			or (gameplay_active and ready_to_collect)
		)
		button.pressed.connect(_on_oven_item_pressed.bind(slot_index))
		_oven_container.add_child(button)

func _render_table(session_service: SessionService, interaction_state: Dictionary) -> void:
	_clear_container(_table_container)
	if session_service.cafe_state.table_items.is_empty():
		_table_container.add_child(_make_info_label("Table is empty."))
		return
	for item_index: int in range(session_service.cafe_state.table_items.size()):
		var item: ItemInstance = session_service.cafe_state.table_items[item_index]
		var button: Button = Button.new()
		button.text = _describe_item(item)
		button.disabled = not _is_zone_targetable(interaction_state, &"table", item_index)
		button.pressed.connect(_on_table_item_pressed.bind(item_index))
		_table_container.add_child(button)

func _render_rewards(reward_ids: PackedStringArray) -> void:
	_clear_container(_reward_container)
	var visible: bool = not reward_ids.is_empty()
	_reward_header.visible = visible
	_reward_container.visible = visible
	if not visible:
		return
	for reward_id in reward_ids:
		var button: Button = Button.new()
		button.text = _reward_label(StringName(reward_id))
		button.pressed.connect(_on_reward_pressed.bind(StringName(reward_id)))
		_reward_container.add_child(button)

func _render_event(description: String, option_ids: PackedStringArray) -> void:
	_clear_container(_event_container)
	var visible: bool = description != "" or not option_ids.is_empty()
	_event_header.visible = visible
	_event_container.visible = visible
	if not visible:
		return
	_event_container.add_child(_make_info_label(description))
	for option_id in option_ids:
		var button: Button = Button.new()
		button.text = _event_option_label(StringName(option_id))
		button.pressed.connect(_on_event_option_pressed.bind(StringName(option_id)))
		_event_container.add_child(button)

func _render_hand(
	hand: Array[CardInstance],
	current_energy: int,
	can_play: bool,
	interaction_state: Dictionary
) -> void:
	_clear_container(_hand_container)
	for index: int in range(hand.size()):
		var card: CardInstance = hand[index]
		var button: Button = Button.new()
		var is_pending: bool = interaction_state.get("pending_card_index", -1) == index
		button.text = "%s%s (Cost %d)\n%s" % [
			"[Selecting] " if is_pending else "",
			card.get_display_name(),
			card.get_cost(),
			card.get_preview_text(),
		]
		button.disabled = not can_play or card.get_cost() > current_energy
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(_on_card_button_pressed.bind(index))
		_hand_container.add_child(button)

func _default_status(session_service: SessionService, interaction_state: Dictionary) -> String:
	var pending_prompt: String = String(interaction_state.get("pending_prompt", ""))
	if pending_prompt != "":
		return pending_prompt
	if session_service.run_state.run_phase == GameEnums.RunPhase.REWARD:
		return "Choose one reward."
	if session_service.run_state.run_phase == GameEnums.RunPhase.EVENT:
		return session_service.run_state.pending_event_description
	if session_service.run_state.run_phase == GameEnums.RunPhase.RUN_END:
		return session_service.run_state.summary_message
	return "Serve customers before their patience runs out."

func _describe_item(item: ItemInstance) -> String:
	var tags: PackedStringArray = item.get_all_tags()
	return "%s | Q%d | %s" % [item.get_display_name(), item.quality, _join_packed_strings(tags)]

func _reward_label(reward_id: StringName) -> String:
	match reward_id:
		&"reward_chocolate":
			return "Chocolate"
		&"reward_flash_bake":
			return "Flash Bake"
		&"oven_capacity_upgrade":
			return "+1 Oven Slot"
		_:
			return String(reward_id)

func _event_option_label(option_id: StringName) -> String:
	match option_id:
		&"improvise":
			return "Improvise"
		&"play_it_safe":
			return "Play It Safe"
		_:
			return String(option_id)

func _format_preferences(preferences: PackedStringArray) -> String:
	if preferences.is_empty():
		return "Anything"
	return _join_packed_strings(preferences)

func _count_occupied_oven_slots(slots: Array[OvenSlotState]) -> int:
	var count: int = 0
	for slot in slots:
		if slot != null and slot.item != null:
			count += 1
	return count

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
		"select_one_item":
			return zone == &"prep" or zone == &"oven"
		_:
			return false

func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _make_info_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text_value
	return label

func _join_packed_strings(values: PackedStringArray) -> String:
	var output: String = ""
	for index: int in range(values.size()):
		if index > 0:
			output += ", "
		output += String(values[index])
	return output

func _on_end_turn_pressed() -> void:
	end_turn_requested.emit()

func _on_card_button_pressed(card_index: int) -> void:
	play_card_requested.emit(card_index)

func _on_prep_item_pressed(item_index: int) -> void:
	prep_item_requested.emit(item_index)

func _on_oven_item_pressed(slot_index: int) -> void:
	oven_item_requested.emit(slot_index)

func _on_table_item_pressed(item_index: int) -> void:
	table_item_requested.emit(item_index)

func _on_serve_pressed(customer_index: int, item_index: int) -> void:
	serve_requested.emit(customer_index, item_index)

func _on_reward_pressed(reward_id: StringName) -> void:
	reward_requested.emit(reward_id)

func _on_event_option_pressed(option_id: StringName) -> void:
	event_option_requested.emit(option_id)

func _run_phase_name(value: int) -> String:
	match value:
		GameEnums.RunPhase.PREP_PHASE:
			return "Prep Phase"
		GameEnums.RunPhase.GAMEPLAY:
			return "Gameplay"
		GameEnums.RunPhase.REWARD:
			return "Reward"
		GameEnums.RunPhase.EVENT:
			return "Event"
		GameEnums.RunPhase.DAY_END:
			return "Day End"
		GameEnums.RunPhase.RUN_END:
			return "Run End"
		_:
			return "Unknown"

func _turn_state_name(value: int) -> String:
	match value:
		GameEnums.TurnState.IDLE:
			return "Idle"
		GameEnums.TurnState.PLAYER_TURN:
			return "Player Turn"
		GameEnums.TurnState.RESOLVING_EFFECTS:
			return "Resolving Effects"
		GameEnums.TurnState.CUSTOMER_TURN:
			return "Customer Turn"
		GameEnums.TurnState.CHECK_END:
			return "Check End"
		_:
			return "Unknown"
