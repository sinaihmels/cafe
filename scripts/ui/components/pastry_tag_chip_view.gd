@tool
class_name PastryTagChipView
extends PanelContainer

const FALLBACK_FILL_COLOR: Color = Color(0.93, 0.88, 0.79, 0.96)
const FALLBACK_BORDER_COLOR: Color = Color(0.49, 0.36, 0.26, 0.96)
const FALLBACK_TEXT_COLOR: Color = Color(0.28, 0.20, 0.15, 1.0)

@onready var _body: VBoxContainer = $Padding/Body
@onready var _name_label: Label = $Padding/Body/NameLabel
@onready var _condition_label: Label = $Padding/Body/ConditionLabel

var _configured_label_text: String = ""
var _configured_condition_text: String = ""
var _configured_presentation: Dictionary = {}
var _configured_conditional: bool = false

func _ready() -> void:
	_apply_configuration()

func configure(
	label_text: String,
	presentation: Dictionary,
	conditional: bool = false,
	condition_text: String = ""
) -> void:
	_configured_label_text = label_text
	_configured_presentation = presentation.duplicate(true)
	_configured_conditional = conditional
	_configured_condition_text = condition_text
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_name_label.text = _configured_label_text
	var show_condition: bool = _configured_conditional and _configured_condition_text != ""
	_condition_label.visible = show_condition
	_condition_label.text = _configured_condition_text
	_body.add_theme_constant_override("separation", 1 if show_condition else 0)
	_apply_style(show_condition)

func _apply_style(show_condition: bool) -> void:
	var fill_color: Color = Color(_configured_presentation.get("fill_color", FALLBACK_FILL_COLOR))
	var border_color: Color = Color(_configured_presentation.get("border_color", FALLBACK_BORDER_COLOR))
	var text_color: Color = Color(_configured_presentation.get("text_color", FALLBACK_TEXT_COLOR))
	if _configured_conditional:
		fill_color = _soften_color(fill_color, 0.22, 0.86)
		border_color = _soften_color(border_color, 0.10, 0.88)
		text_color = _soften_color(text_color, 0.05, 0.92)
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = fill_color
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = border_color
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	add_theme_stylebox_override("panel", panel_style)
	_name_label.add_theme_color_override("font_color", text_color)
	if show_condition:
		var condition_text_color: Color = text_color
		condition_text_color.a = minf(condition_text_color.a, 0.82)
		_condition_label.add_theme_color_override("font_color", condition_text_color)

func _soften_color(base_color: Color, white_mix: float, alpha_multiplier: float) -> Color:
	var mixed_color: Color = base_color.lerp(Color(1, 1, 1, base_color.a), clampf(white_mix, 0.0, 1.0))
	mixed_color.a *= alpha_multiplier
	return mixed_color
