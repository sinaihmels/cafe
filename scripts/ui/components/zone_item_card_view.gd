class_name ZoneItemCardView
extends Button

signal action_requested()

@export var fallback_texture: Texture2D
@export var normal_style: StyleBox
@export var targetable_style: StyleBox
@export var selected_style: StyleBox
@export var disabled_style: StyleBox

@onready var _icon_frame: PanelContainer = $Margin/Body/IconFrame
@onready var _icon: TextureRect = $Margin/Body/IconFrame/IconMargin/Icon
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
	_title_label.text = _compact_title_text(_configured_title_text)
	var compact_detail: String = _compact_detail_text(_configured_detail_text)
	_detail_label.text = compact_detail
	_detail_label.visible = compact_detail != ""
	tooltip_text = _configured_detail_text
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
		_icon_frame.add_theme_stylebox_override("panel", style)

func _compact_title_text(title_text: String) -> String:
	return title_text.strip_edges()

func _compact_detail_text(detail_text: String) -> String:
	var cleaned: String = detail_text.replace("\n", " ").strip_edges()
	if cleaned == "":
		return ""
	var pieces: PackedStringArray = cleaned.split("|", false)
	var lines: Array[String] = []
	for raw_piece in pieces:
		var piece: String = raw_piece.strip_edges()
		if piece == "" or piece == _configured_title_text:
			continue
		lines.append(piece)
		if lines.size() >= 2:
			break
	if lines.is_empty():
		return _truncate(cleaned, 44)
	return _truncate("\n".join(lines), 56)

func _truncate(value: String, max_length: int) -> String:
	if value.length() <= max_length:
		return value
	return "%s..." % value.substr(0, max_length - 3)

func _on_pressed() -> void:
	action_requested.emit()
