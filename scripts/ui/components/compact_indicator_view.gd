class_name CompactIndicatorView
extends PanelContainer

@export var paper_style: StyleBox
@export var accent_style: StyleBox
@export var gold_style: StyleBox
@export var danger_style: StyleBox

@onready var _label: Label = $Padding/Label

var _display_text: String = ""
var _tone: String = "paper"
var _hint_text: String = ""

func _ready() -> void:
	_apply_configuration()

func configure(display_text: String, tone: String = "paper", hint_text: String = "") -> void:
	_display_text = display_text
	_tone = tone
	_hint_text = hint_text
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	if _label == null:
		return
	_label.text = _display_text
	tooltip_text = _hint_text
	_apply_tone(_tone)

func _apply_tone(tone: String) -> void:
	var panel_style: StyleBox = paper_style
	match tone:
		"accent":
			panel_style = accent_style if accent_style != null else paper_style
		"gold":
			panel_style = gold_style if gold_style != null else paper_style
		"danger":
			panel_style = danger_style if danger_style != null else paper_style
		_:
			panel_style = paper_style
	if panel_style != null:
		add_theme_stylebox_override("panel", panel_style)
