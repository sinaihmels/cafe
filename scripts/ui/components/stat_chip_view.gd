class_name StatChipView
extends PanelContainer

@export var paper_style: StyleBox
@export var accent_style: StyleBox
@export var gold_style: StyleBox
@export var danger_style: StyleBox
@export var paper_title_color: Color = Color(0.38, 0.31, 0.26)
@export var paper_value_color: Color = Color(0.20, 0.13, 0.10)
@export var accent_title_color: Color = Color(1.0, 0.97, 0.93, 0.88)
@export var accent_value_color: Color = Color(1.0, 0.98, 0.96)
@export var gold_title_color: Color = Color(1.0, 0.97, 0.93, 0.88)
@export var gold_value_color: Color = Color(1.0, 0.98, 0.96)
@export var danger_title_color: Color = Color(1.0, 0.97, 0.93, 0.88)
@export var danger_value_color: Color = Color(1.0, 0.98, 0.96)

@onready var _title_label: Label = $Margin/Body/TitleLabel
@onready var _value_label: Label = $Margin/Body/ValueLabel

var _configured_label_text: String = ""
var _configured_value_text: String = ""
var _configured_tone: String = "paper"

func _ready() -> void:
	_apply_configuration()

func configure(label_text: String, value_text: String, tone: String = "paper") -> void:
	_configured_label_text = label_text
	_configured_value_text = value_text
	_configured_tone = tone
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_title_label.text = _configured_label_text.to_upper()
	_value_label.text = _configured_value_text
	_apply_tone(_configured_tone)

func _apply_tone(tone: String) -> void:
	var panel_style: StyleBox = paper_style
	var title_color: Color = paper_title_color
	var value_color: Color = paper_value_color
	match tone:
		"accent":
			panel_style = accent_style if accent_style != null else paper_style
			title_color = accent_title_color
			value_color = accent_value_color
		"gold":
			panel_style = gold_style if gold_style != null else paper_style
			title_color = gold_title_color
			value_color = gold_value_color
		"danger":
			panel_style = danger_style if danger_style != null else paper_style
			title_color = danger_title_color
			value_color = danger_value_color
		_:
			panel_style = paper_style
	if panel_style != null:
		add_theme_stylebox_override("panel", panel_style)
	_title_label.add_theme_color_override("font_color", title_color)
	_value_label.add_theme_color_override("font_color", value_color)
