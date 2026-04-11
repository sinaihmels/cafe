@tool
class_name EncounterResourcesView
extends PanelContainer

@onready var _mana_value: Label = $Padding/Body/ManaValue
@onready var _stress_value: Label = $Padding/Body/StressValue
@onready var _stress_meter: Control = $Padding/Body/StressMeter
@onready var _meter_fill: ColorRect = $Padding/Body/StressMeter/MeterFill

var _stress_fraction: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		render_editor_preview()

func render(session_service: SessionService) -> void:
	_mana_value.text = str(session_service.player_state.energy)
	_stress_value.text = "%d/%d" % [session_service.player_state.stress, session_service.player_state.max_stress]
	_stress_fraction = clampf(
		float(session_service.player_state.stress) / maxf(1.0, float(session_service.player_state.max_stress)),
		0.0,
		1.0
	)
	_apply_meter()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_meter")

func _apply_meter() -> void:
	if _stress_meter == null or _meter_fill == null:
		return
	var meter_width: float = maxf(4.0, _stress_meter.size.x - 4.0)
	_meter_fill.position = Vector2(2.0, 2.0)
	_meter_fill.size = Vector2(
		maxf(6.0, meter_width * _stress_fraction),
		maxf(4.0, _stress_meter.size.y - 4.0)
	)

func render_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var preview_session: SessionService = EncounterEditorPreview.build_session()
	render(preview_session)
