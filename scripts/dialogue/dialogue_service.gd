class_name DialogueService
extends Node

signal presentation_changed()

const AUTO_ADVANCE_SECONDS: float = 1.4
const FALLBACK_DIALOGUE_PATH: String = "res://data/dialogue/customers/fallback.dialogue"

var _session_service: SessionService
var _event_bus: EventBus
var _queue: Array[DialogueRequest] = []
var _active_request: DialogueRequest
var _active_bridge: EncounterDialogueBridge
var _active_nodes_by_id: Dictionary = {}
var _active_responses: Array[Dictionary] = []
var _active_request_is_modal: bool = false
var _current_node_id: StringName = &""
var _presentation_state: DialoguePresentationState = DialoguePresentationState.new()
var _dialogue_cache: Dictionary = {}
var _revision_counter: int = 0
var _saved_turn_state: int = GameEnums.TurnState.IDLE
var _has_saved_turn_state: bool = false

func configure(session_service: SessionService, event_bus: EventBus) -> void:
	_session_service = session_service
	var handler: Callable = Callable(self, "_on_dialogue_requested")
	if _event_bus != null and _event_bus.is_connected(&"dialogue_requested", handler):
		_event_bus.disconnect(&"dialogue_requested", handler)
	_event_bus = event_bus
	if _event_bus != null and not _event_bus.is_connected(&"dialogue_requested", handler):
		_event_bus.connect(&"dialogue_requested", handler)

func get_presentation_state() -> DialoguePresentationState:
	return _presentation_state.duplicate_state()

func has_active_dialogue() -> bool:
	return _presentation_state.visible

func is_blocking_input() -> bool:
	return _presentation_state.visible and _presentation_state.blocking_input

func clear_dialogue() -> void:
	_queue.clear()
	_active_request = null
	_active_bridge = null
	_active_nodes_by_id.clear()
	_active_responses.clear()
	_current_node_id = &""
	_active_request_is_modal = false
	_restore_turn_state()
	_presentation_state = DialoguePresentationState.new()
	presentation_changed.emit()

func advance_dialogue() -> void:
	if _active_request == null:
		return
	var node: Dictionary = _current_node()
	if node.is_empty():
		_finish_active_dialogue()
		return
	var next_node_id: StringName = StringName(node.get("next", ""))
	if next_node_id == &"":
		_finish_active_dialogue()
		return
	_move_to_node(next_node_id)

func choose_response(response_index: int) -> void:
	if _active_request == null:
		return
	if response_index < 0 or response_index >= _active_responses.size():
		return
	var response: Dictionary = _active_responses[response_index]
	_apply_actions(response.get("actions", []))
	var next_node_id: StringName = StringName(response.get("next", ""))
	if next_node_id == &"":
		_finish_active_dialogue()
		return
	_move_to_node(next_node_id)

func _on_dialogue_requested(request: DialogueRequest) -> void:
	if request == null:
		return
	_queue.append(request.duplicate_request())
	_pump_queue()

func _pump_queue() -> void:
	if _active_request != null:
		return
	while not _queue.is_empty():
		var request: DialogueRequest = _queue.pop_front()
		if request == null:
			continue
		var bridge: EncounterDialogueBridge = EncounterDialogueBridge.new()
		bridge.session_service = _session_service
		bridge.dialogue_request = request
		var dialogue_path: String = _resolve_dialogue_path(request)
		var script_data: Dictionary = _load_dialogue_data(dialogue_path)
		var cue_data: Dictionary = _cue_data(script_data, request.cue)
		if cue_data.is_empty() and dialogue_path != FALLBACK_DIALOGUE_PATH:
			script_data = _load_dialogue_data(FALLBACK_DIALOGUE_PATH)
			cue_data = _cue_data(script_data, request.cue)
		if cue_data.is_empty():
			continue
		var nodes_by_id: Dictionary = _build_nodes_by_id(cue_data.get("nodes", []))
		if nodes_by_id.is_empty():
			continue
		var entry_node_id: StringName = _resolve_entry_node_id(cue_data, bridge)
		if entry_node_id == &"":
			continue
		_active_request = request
		_active_bridge = bridge
		_active_nodes_by_id = nodes_by_id
		_active_request_is_modal = request.modal
		_capture_turn_state()
		_move_to_node(entry_node_id)
		return
	_presentation_state = DialoguePresentationState.new()
	presentation_changed.emit()

func _move_to_node(node_id: StringName) -> void:
	if node_id == &"":
		_finish_active_dialogue()
		return
	var node: Dictionary = _active_nodes_by_id.get(node_id, {})
	if node.is_empty():
		_finish_active_dialogue()
		return
	if not _conditions_met(node.get("conditions", [])):
		var fallback_next: StringName = StringName(node.get("next", ""))
		if fallback_next != &"":
			_move_to_node(fallback_next)
		else:
			_finish_active_dialogue()
		return
	_current_node_id = node_id
	_apply_actions(node.get("actions", []))
	_present_node(node)

func _present_node(node: Dictionary) -> void:
	var presentation: DialoguePresentationState = DialoguePresentationState.new()
	_revision_counter += 1
	presentation.revision = _revision_counter
	presentation.visible = true
	presentation.blocking_input = true
	presentation.customer_runtime_id = _active_request.customer_runtime_id if _active_request != null else 0
	presentation.customer_index = _active_bridge.get_customer_index() if _active_bridge != null else -1
	presentation.cue = _active_request.cue if _active_request != null else &""
	presentation.speaker_kind = StringName(node.get("speaker", "customer"))
	presentation.text = String(node.get("text", ""))
	var customer: CustomerInstance = _active_bridge.get_customer() if _active_bridge != null else null
	if presentation.speaker_kind == &"player":
		presentation.speaker_name = "You"
		presentation.portrait = null
	else:
		presentation.speaker_name = customer.get_display_name() if customer != null else "Customer"
		presentation.portrait = customer.customer_def.portrait if customer != null and customer.customer_def != null else null
	_active_responses = _build_visible_responses(node.get("responses", []))
	for response_def in _active_responses:
		var option: DialogueResponseOption = DialogueResponseOption.new()
		option.response_id = StringName(response_def.get("id", ""))
		option.text = String(response_def.get("text", ""))
		option.next_node_id = StringName(response_def.get("next", ""))
		option.disabled = false
		presentation.responses.append(option)
	presentation.modal = _active_request_is_modal or bool(node.get("modal", false)) or not presentation.responses.is_empty()
	presentation.allow_continue = presentation.responses.is_empty()
	if not presentation.modal and presentation.responses.is_empty():
		presentation.auto_advance_seconds = AUTO_ADVANCE_SECONDS
	_presentation_state = presentation
	presentation_changed.emit()
	if presentation.auto_advance_seconds > 0.0:
		_schedule_auto_advance(presentation.revision, presentation.auto_advance_seconds)

func _schedule_auto_advance(revision: int, duration: float) -> void:
	if not is_inside_tree():
		return
	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	timer.timeout.connect(func() -> void:
		if _presentation_state.visible and _presentation_state.revision == revision:
			advance_dialogue()
	)

func _finish_active_dialogue() -> void:
	var finished_request: DialogueRequest = _active_request
	_active_request = null
	_active_bridge = null
	_active_nodes_by_id.clear()
	_active_responses.clear()
	_current_node_id = &""
	_active_request_is_modal = false
	_restore_turn_state()
	_presentation_state = DialoguePresentationState.new()
	presentation_changed.emit()
	if _session_service != null and finished_request != null and finished_request.cue == &"leave":
		_session_service.finalize_customer_departure(finished_request.customer_runtime_id)
	_pump_queue()

func _resolve_dialogue_path(request: DialogueRequest) -> String:
	if request != null and request.dialogue_path != "":
		return request.dialogue_path
	return FALLBACK_DIALOGUE_PATH

func _load_dialogue_data(path: String) -> Dictionary:
	if path == "":
		return {}
	if _dialogue_cache.has(path):
		return _dialogue_cache[path]
	if not FileAccess.file_exists(path):
		return {}
	var raw_text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		return {}
	var parsed_dict: Dictionary = parsed
	_dialogue_cache[path] = parsed_dict
	return parsed_dict

func _cue_data(script_data: Dictionary, cue: StringName) -> Dictionary:
	var cues: Dictionary = script_data.get("cues", {})
	if cues.has(String(cue)):
		return cues.get(String(cue), {})
	return {}

func _build_nodes_by_id(raw_nodes: Array) -> Dictionary:
	var nodes_by_id: Dictionary = {}
	for node_value in raw_nodes:
		var node: Dictionary = node_value
		var node_id: StringName = StringName(node.get("id", ""))
		if node_id == &"":
			continue
		nodes_by_id[node_id] = node.duplicate(true)
	return nodes_by_id

func _resolve_entry_node_id(cue_data: Dictionary, bridge: EncounterDialogueBridge) -> StringName:
	var nodes: Array = cue_data.get("nodes", [])
	for node_value in nodes:
		var node: Dictionary = node_value
		if not bool(node.get("entry", false)):
			continue
		if _conditions_met(node.get("conditions", []), bridge):
			return StringName(node.get("id", ""))
	var default_entry: StringName = StringName(cue_data.get("default_entry", ""))
	if default_entry != &"":
		return default_entry
	if nodes.is_empty():
		return &""
	return StringName((nodes[0] as Dictionary).get("id", ""))

func _current_node() -> Dictionary:
	return _active_nodes_by_id.get(_current_node_id, {})

func _build_visible_responses(raw_responses: Array) -> Array[Dictionary]:
	var visible_responses: Array[Dictionary] = []
	if _active_request == null or not _active_request.allow_choices:
		return visible_responses
	for response_value in raw_responses:
		var response: Dictionary = response_value
		if not _conditions_met(response.get("conditions", [])):
			continue
		visible_responses.append(response.duplicate(true))
	return visible_responses

func _conditions_met(raw_conditions: Variant, override_bridge: EncounterDialogueBridge = null) -> bool:
	if raw_conditions == null:
		return true
	var bridge: EncounterDialogueBridge = override_bridge if override_bridge != null else _active_bridge
	if bridge == null:
		return true
	for condition_value in raw_conditions:
		var condition: Dictionary = condition_value
		if not _condition_met(condition, bridge):
			return false
	return true

func _condition_met(condition: Dictionary, bridge: EncounterDialogueBridge) -> bool:
	var field_name: String = String(condition.get("field", ""))
	var current_value: Variant = bridge.get_value(field_name)
	if condition.has("equals"):
		return _compare_value(current_value, condition.get("equals"))
	if condition.has("not_equals"):
		return not _compare_value(current_value, condition.get("not_equals"))
	if condition.has("has"):
		return _value_has(current_value, condition.get("has"))
	if condition.has("not_has"):
		return not _value_has(current_value, condition.get("not_has"))
	if condition.has("truthy"):
		return bool(current_value) == bool(condition.get("truthy"))
	return true

func _compare_value(left: Variant, right: Variant) -> bool:
	if left is StringName:
		return String(left) == String(right)
	return left == right

func _value_has(current_value: Variant, desired_value: Variant) -> bool:
	if current_value is PackedStringArray:
		return (current_value as PackedStringArray).has(StringName(desired_value))
	if current_value is Array:
		return (current_value as Array).has(desired_value)
	if current_value is Dictionary:
		return bool((current_value as Dictionary).get(StringName(desired_value), false))
	return false

func _apply_actions(raw_actions: Variant) -> void:
	if _active_bridge == null or raw_actions == null:
		return
	for action_value in raw_actions:
		var action: Dictionary = action_value
		var action_type: StringName = StringName(action.get("type", ""))
		match action_type:
			&"remember_choice":
				_active_bridge.remember_choice(
					StringName(action.get("key", "")),
					action.get("value", true)
				)
			&"apply_outcome":
				_active_bridge.apply_outcome(StringName(action.get("outcome_id", "")))
			_:
				pass

func _capture_turn_state() -> void:
	if _session_service == null:
		return
	if _session_service.run_state.screen != GameEnums.Screen.ENCOUNTER:
		return
	if not _has_saved_turn_state:
		_saved_turn_state = _session_service.combat_state.turn_state
		_has_saved_turn_state = true
	_session_service.combat_state.turn_state = GameEnums.TurnState.DIALOGUE

func _restore_turn_state() -> void:
	if _session_service == null or not _has_saved_turn_state:
		return
	if _session_service.run_state.screen == GameEnums.Screen.ENCOUNTER:
		_session_service.combat_state.turn_state = _saved_turn_state
	_has_saved_turn_state = false
