@tool
class_name ZoneItemCardView
extends Button

signal action_requested()

@export var fallback_texture: Texture2D
@export var normal_style: StyleBox
@export var targetable_style: StyleBox
@export var selected_style: StyleBox
@export var disabled_style: StyleBox
@export_group("Layout Scale")
@export var reference_size: Vector2 = Vector2(140.0, 166.0)
@export_range(0.5, 2.0, 0.01) var scale_min: float = 0.9
@export_range(0.5, 2.0, 0.01) var scale_max: float = 1.32
@export_group("Spacing")
@export var margin_base: float = 8.0
@export var margin_min: int = 6
@export var body_separation_base: float = 8.0
@export var body_separation_min: int = 6
@export_group("Icon")
@export var icon_frame_size: float = 104.0
@export var icon_frame_min_size: float = 92.0
@export var icon_size: float = 86.0
@export var icon_min_size: float = 72.0
@export_group("Typography")
@export var title_font_size: float = 14.0
@export var title_font_size_min: int = 12
@export var detail_font_size: float = 11.0
@export var detail_font_size_min: int = 10

@onready var _margin: MarginContainer = $Margin
@onready var _body: VBoxContainer = $Margin/Body
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
var _editor_refresh_signature: Array = []

func _ready() -> void:
	pressed.connect(_on_pressed)
	if Engine.is_editor_hint():
		_editor_refresh_signature = _make_editor_refresh_signature()
		set_process(true)
	_apply_configuration()
	_apply_layout_scale()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_apply_layout_scale")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var signature: Array = _make_editor_refresh_signature()
	if signature == _editor_refresh_signature:
		return
	_editor_refresh_signature = signature
	_refresh_editor_preview()

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

func _apply_layout_scale() -> void:
	if _margin == null or _body == null or _icon_frame == null:
		return
	var width_source: float = size.x if size.x > 0.0 else custom_minimum_size.x
	var height_source: float = size.y if size.y > 0.0 else custom_minimum_size.y
	var resolved_reference_size: Vector2 = Vector2(maxf(1.0, reference_size.x), maxf(1.0, reference_size.y))
	var scale_factor: float = clampf(
		minf(width_source / resolved_reference_size.x, height_source / resolved_reference_size.y),
		scale_min,
		scale_max
	)
	var margin_value: int = maxi(margin_min, int(round(margin_base * scale_factor)))
	_margin.add_theme_constant_override("margin_left", margin_value)
	_margin.add_theme_constant_override("margin_top", margin_value)
	_margin.add_theme_constant_override("margin_right", margin_value)
	_margin.add_theme_constant_override("margin_bottom", margin_value)
	_body.add_theme_constant_override("separation", maxi(body_separation_min, int(round(body_separation_base * scale_factor))))
	_icon_frame.custom_minimum_size = Vector2(
		maxf(icon_frame_min_size, icon_frame_size * scale_factor),
		maxf(icon_frame_min_size, icon_frame_size * scale_factor)
	)
	_icon.custom_minimum_size = Vector2(
		maxf(icon_min_size, icon_size * scale_factor),
		maxf(icon_min_size, icon_size * scale_factor)
	)
	_title_label.add_theme_font_size_override("font_size", maxi(title_font_size_min, int(round(title_font_size * scale_factor))))
	_detail_label.add_theme_font_size_override("font_size", maxi(detail_font_size_min, int(round(detail_font_size * scale_factor))))

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

func _make_editor_refresh_signature() -> Array:
	return [
		fallback_texture,
		normal_style,
		targetable_style,
		selected_style,
		disabled_style,
		reference_size,
		scale_min,
		scale_max,
		margin_base,
		margin_min,
		body_separation_base,
		body_separation_min,
		icon_frame_size,
		icon_frame_min_size,
		icon_size,
		icon_min_size,
		title_font_size,
		title_font_size_min,
		detail_font_size,
		detail_font_size_min,
	]

func _refresh_editor_preview() -> void:
	_apply_configuration()
	_apply_layout_scale()

func _on_pressed() -> void:
	action_requested.emit()
