@tool
class_name EncounterHudView
extends Control

@export var indicator_scene: PackedScene

@onready var _meta_flow: VBoxContainer = $MetaFlow
@onready var _buff_flow: HBoxContainer = $BuffFlow

func _ready() -> void:
	if Engine.is_editor_hint():
		render_editor_preview()

func render(session_service: SessionService) -> void:
	UiSceneUtils.clear_children(_meta_flow)
	UiSceneUtils.clear_children(_buff_flow)
	_add_indicator(_meta_flow, "TIP %d" % session_service.player_state.tips, "gold", "Tips")
	_add_indicator(_meta_flow, "DAY %d" % session_service.run_state.day_number, "paper", "Day")
	_add_indicator(_meta_flow, "TURN %d" % session_service.combat_state.turn_number, "paper", "Turn")

	var buff_lines: Array[String] = UiTextFormatter.build_modifier_lines(session_service)
	for buff_line in buff_lines:
		_add_indicator(_buff_flow, _buff_abbreviation(buff_line), "accent", buff_line)
	if buff_lines.is_empty():
		_add_indicator(_buff_flow, "BUFF 0", "paper", "No active buffs.")

func _add_indicator(container: Container, display_text: String, tone: String, hint_text: String) -> void:
	var indicator: CompactIndicatorView = _instantiate_indicator()
	indicator.configure(display_text, tone, hint_text)
	container.add_child(indicator)

func _buff_abbreviation(buff_line: String) -> String:
	var sanitized: String = buff_line.strip_edges()
	if sanitized == "":
		return "BUFF"
	var pieces: PackedStringArray = sanitized.split(" ", false)
	if pieces.size() >= 2:
		var combined: String = ""
		for piece in pieces:
			if piece == "":
				continue
			combined += piece.substr(0, 1).to_upper()
			if combined.length() >= 3:
				break
		if combined != "":
			return combined
	var compact: String = sanitized.replace(" ", "").replace("+", "").replace("-", "")
	if compact.length() <= 4:
		return compact.to_upper()
	return compact.substr(0, 4).to_upper()

func _instantiate_indicator() -> CompactIndicatorView:
	var node: Node = UiSceneUtils.instantiate_required(indicator_scene, "EncounterHudView.indicator_scene")
	var indicator: CompactIndicatorView = node as CompactIndicatorView
	assert(indicator != null, "EncounterHudView.indicator_scene must instantiate CompactIndicatorView.")
	return indicator

func render_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var preview_session: SessionService = EncounterEditorPreview.build_session()
	render(preview_session)
