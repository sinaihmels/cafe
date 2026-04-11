@tool
class_name CustomerSelectorView
extends Button

signal selected()

@export var normal_style: StyleBox
@export var selected_style: StyleBox

@onready var _index_label: Label = $Margin/Body/IndexLabel
@onready var _name_label: Label = $Margin/Body/NameLabel

var _configured_index_text: String = ""
var _configured_customer_name: String = ""
var _configured_selected: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	_apply_configuration()

func configure(index_text: String, customer_name: String, is_selected: bool) -> void:
	_configured_index_text = index_text
	_configured_customer_name = customer_name
	_configured_selected = is_selected
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_index_label.text = _configured_index_text
	_name_label.text = _configured_customer_name
	var style: StyleBox = selected_style if _configured_selected and selected_style != null else normal_style
	if style != null:
		add_theme_stylebox_override("normal", style)
		add_theme_stylebox_override("hover", style)
		add_theme_stylebox_override("pressed", style)

func _on_pressed() -> void:
	selected.emit()
