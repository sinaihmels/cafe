class_name ZoneItemCardView
extends Button

signal action_requested()

@export var fallback_texture: Texture2D
@export var normal_style: StyleBox
@export var targetable_style: StyleBox
@export var selected_style: StyleBox
@export var disabled_style: StyleBox

@onready var _icon: TextureRect = $Margin/Body/Icon
@onready var _title_label: Label = $Margin/Body/TitleLabel
@onready var _detail_label: Label = $Margin/Body/DetailLabel

var _configured_icon_texture: Texture2D
var _configured_title_text: String = ""
var _configured_detail_text: String = ""
var _configured_interactable: bool = false
var _configured_selected: bool = false
var _configured_targetable: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	_apply_configuration()

func configure(
	icon_texture: Texture2D,
	title_text: String,
	detail_text: String,
	interactable: bool,
	selected: bool,
	targetable: bool
) -> void:
	_configured_icon_texture = icon_texture
	_configured_title_text = title_text
	_configured_detail_text = detail_text
	_configured_interactable = interactable
	_configured_selected = selected
	_configured_targetable = targetable
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_icon.texture = _configured_icon_texture if _configured_icon_texture != null else fallback_texture
	_title_label.text = _configured_title_text
	_detail_label.text = _configured_detail_text
	disabled = not _configured_interactable
	_apply_style(_configured_selected, _configured_targetable, disabled)

func _apply_style(selected: bool, targetable: bool, is_disabled: bool) -> void:
	var style: StyleBox = normal_style
	if selected and selected_style != null:
		style = selected_style
	elif targetable and targetable_style != null:
		style = targetable_style
	elif is_disabled and disabled_style != null:
		style = disabled_style
	if style != null:
		add_theme_stylebox_override("normal", style)
		add_theme_stylebox_override("hover", style)
		add_theme_stylebox_override("pressed", style)
		add_theme_stylebox_override("disabled", disabled_style if disabled_style != null else style)

func _on_pressed() -> void:
	action_requested.emit()
