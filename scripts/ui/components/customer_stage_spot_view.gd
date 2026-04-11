class_name CustomerStageSpotView
extends PanelContainer

signal focus_requested(customer_index: int)
signal target_requested(customer_index: int)

@export var stat_chip_scene: PackedScene
@export var normal_style: StyleBox
@export var focused_style: StyleBox
@export var targetable_style: StyleBox
@export var selected_style: StyleBox

@onready var _focus_button: Button = $FocusButton
@onready var _body_margin: MarginContainer = $BodyMargin
@onready var _stage_row: HBoxContainer = $BodyMargin/StageRow
@onready var _info_column: VBoxContainer = $BodyMargin/StageRow/InfoColumn
@onready var _actor_column: VBoxContainer = $BodyMargin/StageRow/ActorColumn
@onready var _portrait_shell: PanelContainer = $BodyMargin/StageRow/ActorColumn/PortraitShell
@onready var _portrait: TextureRect = $BodyMargin/StageRow/ActorColumn/PortraitShell/PortraitMargin/Portrait
@onready var _name_label: Label = $BodyMargin/StageRow/InfoColumn/NameLabel
@onready var _request_button: Button = $BodyMargin/StageRow/InfoColumn/RequestBubbleButton
@onready var _detail_stats: HFlowContainer = $BodyMargin/StageRow/InfoColumn/DetailedStats
@onready var _compact_request_label: Label = $BodyMargin/StageRow/ActorColumn/CompactRequestLabel
@onready var _compact_stats_label: Label = $BodyMargin/StageRow/ActorColumn/CompactStatsLabel
@onready var _patience_badge: PanelContainer = $BodyMargin/StageRow/ActorColumn/PortraitShell/PatienceBadge
@onready var _patience_value: Label = $BodyMargin/StageRow/ActorColumn/PortraitShell/PatienceBadge/PatienceValue
@onready var _hunger_badge: PanelContainer = $BodyMargin/StageRow/ActorColumn/PortraitShell/HungerBadge
@onready var _hunger_value: Label = $BodyMargin/StageRow/ActorColumn/PortraitShell/HungerBadge/HungerValue
@onready var _satisfaction_badge: PanelContainer = $BodyMargin/StageRow/ActorColumn/PortraitShell/SatisfactionBadge
@onready var _satisfaction_value: Label = $BodyMargin/StageRow/ActorColumn/PortraitShell/SatisfactionBadge/SatisfactionValue

var _customer_index: int = -1
var _customer: CustomerInstance
var _portrait_texture: Texture2D
var _is_focused: bool = false
var _is_selected: bool = false
var _is_targetable: bool = false
var _display_scale: float = 1.0
var _layout_variant: StringName = &"supporting"
var _request_text: String = ""

func _ready() -> void:
	_focus_button.pressed.connect(_on_focus_pressed)
	_request_button.pressed.connect(_on_request_pressed)
	_apply_configuration()

func configure(
	customer_index: int,
	customer: CustomerInstance,
	portrait_texture: Texture2D,
	focused: bool,
	selected: bool,
	targetable: bool,
	layout_variant: StringName = &"supporting"
) -> void:
	_customer_index = customer_index
	_customer = customer
	_portrait_texture = portrait_texture
	_is_focused = focused
	_is_selected = selected
	_is_targetable = targetable
	_layout_variant = layout_variant
	if is_node_ready():
		_apply_configuration()

func set_display_scale(display_scale: float) -> void:
	_display_scale = clampf(display_scale, 0.78, 1.12)
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	UiSceneUtils.clear_children(_detail_stats)
	if _customer == null:
		return
	_request_text = UiTextFormatter.describe_customer_request(_customer)
	# Focused customers can switch between a richer desktop layout and a compact layout
	# once the lane has assigned a real size to this control.
	var show_detail: bool = _is_focused and _layout_variant != &"supporting"
	var use_compact_focus_layout: bool = show_detail and _uses_compact_focus_layout()
	_portrait.texture = _portrait_texture if _portrait_texture != null else UiTextureLibrary.customer_texture(null)
	_name_label.text = _customer.get_display_name().to_upper()
	_focus_button.tooltip_text = _customer.get_display_name()
	_info_column.visible = show_detail
	_request_button.visible = show_detail
	_request_button.text = _request_text
	_request_button.tooltip_text = _request_text
	_request_button.disabled = not (_is_selected or _is_targetable)
	_compact_request_label.visible = not show_detail
	_compact_request_label.text = _compact_request_text(_request_text)
	_compact_request_label.tooltip_text = _request_text
	_compact_stats_label.visible = not show_detail
	_compact_stats_label.text = _customer.get_display_name()
	_compact_stats_label.tooltip_text = _customer.get_display_name()
	_patience_value.text = str(_customer.current_patience)
	_hunger_value.text = str(_customer.remaining_hunger)
	_satisfaction_value.text = str(_customer.satisfaction_score)
	_patience_badge.visible = not _is_focused
	_hunger_badge.visible = not _is_focused
	_satisfaction_badge.visible = not _is_focused
	_patience_badge.tooltip_text = "Patience"
	_hunger_badge.tooltip_text = "Hunger"
	_satisfaction_badge.tooltip_text = "Satisfaction"
	_detail_stats.visible = show_detail
	if show_detail:
		_add_stat_chip("Patience", str(_customer.current_patience), _patience_tone(_customer.current_patience))
		_add_stat_chip("Hunger", str(_customer.remaining_hunger), _hunger_tone(_customer.remaining_hunger))
		_add_stat_chip("Satisfaction", str(_customer.satisfaction_score), _satisfaction_tone(_customer.satisfaction_score))
	_apply_style()
	_apply_layout_scale()

func _apply_layout_scale() -> void:
	var is_solo: bool = _layout_variant == &"solo"
	var is_supporting: bool = _layout_variant == &"supporting"
	var is_compact_focused: bool = _uses_compact_focus_layout()
	var margin: int = maxi(4, int(round(8.0 * _display_scale)))
	_body_margin.add_theme_constant_override("margin_left", margin)
	_body_margin.add_theme_constant_override("margin_top", margin)
	_body_margin.add_theme_constant_override("margin_right", margin)
	_body_margin.add_theme_constant_override("margin_bottom", margin)
	var row_separation_base: float = 12.0
	if is_solo:
		row_separation_base = 10.0
	if is_compact_focused:
		row_separation_base = 8.0 if is_solo else 9.0
	_stage_row.add_theme_constant_override("separation", maxi(6, int(round(row_separation_base * _display_scale))))
	_actor_column.add_theme_constant_override("separation", maxi(4, int(round(6.0 * _display_scale))))
	var portrait_width: float = 122.0 if is_solo else (98.0 if is_compact_focused else (132.0 if _is_focused else 116.0))
	var portrait_height: float = 150.0 if is_solo else (118.0 if is_compact_focused else (162.0 if _is_focused else 138.0))
	var portrait_min_width: float = 88.0 if is_compact_focused else 100.0
	var portrait_min_height: float = 108.0 if is_compact_focused else 126.0
	_portrait_shell.custom_minimum_size = Vector2(maxf(portrait_min_width, portrait_width * _display_scale), maxf(portrait_min_height, portrait_height * _display_scale))
	var request_width_source: float = size.x if size.x > 0.0 else custom_minimum_size.x
	if request_width_source <= 0.0:
		request_width_source = 320.0
	var detail_width: float = maxf(156.0, 212.0 * _display_scale)
	var request_width: float = maxf(156.0, 210.0 * _display_scale)
	var request_height: float = maxf(82.0, 96.0 * _display_scale)
	if is_solo:
		detail_width = clampf(request_width_source * 0.56, 196.0, 328.0)
		request_width = clampf(request_width_source * 0.52, 184.0, 300.0)
		request_height = maxf(64.0, 78.0 * _display_scale)
	elif _is_focused:
		detail_width = clampf(request_width_source * 0.48, 184.0, 338.0)
		request_width = clampf(request_width_source * 0.46, 176.0, 320.0)
	if is_compact_focused:
		# Compact focused mode is the main safety valve for 1152x648 and 1280x800.
		# Tune this block first if the customer stack starts overflowing again.
		detail_width = clampf(request_width_source * 0.40, 146.0, 214.0)
		request_width = clampf(request_width_source * 0.38, 138.0, 204.0)
		request_height = maxf(54.0, 62.0 * _display_scale)
	_info_column.custom_minimum_size = Vector2(detail_width, 0.0)
	_request_button.custom_minimum_size = Vector2(request_width, request_height)
	_info_column.size_flags_horizontal = 0 if is_solo or is_compact_focused else Control.SIZE_FILL
	_request_button.size_flags_horizontal = 0 if is_solo or is_compact_focused else Control.SIZE_FILL
	_detail_stats.size_flags_horizontal = 0 if is_solo or is_compact_focused else Control.SIZE_FILL
	_actor_column.size_flags_horizontal = 0 if is_solo or is_supporting or is_compact_focused else Control.SIZE_FILL
	if is_solo:
		_stage_row.alignment = BoxContainer.ALIGNMENT_END
	elif is_supporting:
		_stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		_stage_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	var body_font_color: Color = Color(0.28, 0.21, 0.16)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92))
	_compact_request_label.add_theme_color_override("font_color", Color(0.94, 0.91, 0.85))
	_compact_stats_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.88))
	_request_button.add_theme_color_override("font_color", body_font_color)
	_request_button.add_theme_color_override("font_hover_color", body_font_color)
	_request_button.add_theme_color_override("font_pressed_color", Color(1.0, 0.97, 0.93))
	_request_button.add_theme_color_override("font_disabled_color", body_font_color)
	var badge_base: float = 30.0 if is_compact_focused else (38.0 if _is_focused else 34.0)
	var badge_size: float = maxf(24.0 if is_compact_focused else 28.0, badge_base * _display_scale)
	_patience_badge.custom_minimum_size = Vector2.ONE * badge_size
	_hunger_badge.custom_minimum_size = Vector2.ONE * badge_size
	_satisfaction_badge.custom_minimum_size = Vector2(maxf(badge_size + 8.0, 38.0), badge_size)
	_name_label.add_theme_font_size_override("font_size", maxi(13, int(round((16.0 if is_compact_focused else 22.0) * _display_scale))))
	_request_button.add_theme_font_size_override("font_size", maxi(10, int(round((13.0 if is_compact_focused else 15.0) * _display_scale))))
	_detail_stats.add_theme_constant_override("h_separation", maxi(4, int(round((4.0 if is_compact_focused else 6.0) * _display_scale))))
	_detail_stats.add_theme_constant_override("v_separation", maxi(4, int(round((4.0 if is_compact_focused else 6.0) * _display_scale))))
	_detail_stats.custom_minimum_size = Vector2(request_width, 0.0)
	_compact_request_label.add_theme_font_size_override("font_size", maxi(10, int(round(11.0 * _display_scale))))
	_compact_stats_label.add_theme_font_size_override("font_size", maxi(10, int(round(12.0 * _display_scale))))
	_patience_value.add_theme_font_size_override("font_size", maxi(11, int(round(14.0 * _display_scale))))
	_hunger_value.add_theme_font_size_override("font_size", maxi(11, int(round(14.0 * _display_scale))))
	_satisfaction_value.add_theme_font_size_override("font_size", maxi(11, int(round(14.0 * _display_scale))))
	_request_button.text = _detail_request_text(_request_text)
	_request_button.tooltip_text = _request_text
	_apply_stat_chip_scale(request_width, is_compact_focused)

func _apply_style() -> void:
	var panel_style: StyleBox = normal_style
	if _is_selected and selected_style != null:
		panel_style = selected_style
	elif _is_targetable and targetable_style != null:
		panel_style = targetable_style
	elif _is_focused and focused_style != null:
		panel_style = focused_style
	if panel_style != null:
		_portrait_shell.add_theme_stylebox_override("panel", panel_style)

func _compact_request_text(request_text: String) -> String:
	var cleaned: String = request_text.replace("Request: ", "").strip_edges()
	var pieces: PackedStringArray = cleaned.split(" | ", false)
	var lines: Array[String] = []
	for piece in pieces:
		var segment: String = piece.strip_edges()
		if segment.begins_with("Needs:"):
			lines.append(segment.replace("Needs: ", "Need "))
			break
	for piece in pieces:
		var segment: String = piece.strip_edges()
		if segment.begins_with("Hunger:"):
			lines.append(segment)
			break
	for piece in pieces:
		var segment: String = piece.strip_edges()
		if segment == "" or lines.has(segment):
			continue
		if segment.begins_with("Likes:"):
			segment = segment.replace("Likes: ", "")
		lines.append(segment)
		if lines.size() >= 2:
			break
	if lines.is_empty():
		lines.append(cleaned)
	return "\n".join(lines.slice(0, mini(2, lines.size())))

func _detail_request_text(request_text: String) -> String:
	if request_text == "":
		return ""
	if not _uses_compact_focus_layout():
		return request_text
	var cleaned: String = request_text.replace("Request: ", "").strip_edges()
	var pieces: PackedStringArray = cleaned.split(" | ", false)
	var lines: Array[String] = []
	for piece in pieces:
		var segment: String = piece.strip_edges()
		if segment.begins_with("Needs:"):
			lines.append(segment)
		elif segment.begins_with("Hunger:"):
			lines.append(segment)
		elif segment.begins_with("Likes:"):
			lines.append(_truncate(segment, 28))
		if lines.size() >= 3:
			break
	if lines.is_empty():
		return _truncate(cleaned, 56)
	return "\n".join(lines)

func _apply_stat_chip_scale(request_width: float, is_compact_focused: bool) -> void:
	for chip_node in _detail_stats.get_children():
		var chip: StatChipView = chip_node as StatChipView
		if chip == null:
			continue
		var compact_width: float = clampf(request_width * 0.48, 76.0, 104.0)
		var regular_width: float = clampf(request_width * 0.48, 108.0, 148.0)
		chip.custom_minimum_size = Vector2(
			compact_width if is_compact_focused else regular_width,
			36.0 if is_compact_focused else 56.0
		)
		var title_font_size: int = 9 if is_compact_focused else 11
		var value_font_size: int = 11 if is_compact_focused else 15
		var title_label: Label = chip.get_node("Margin/Body/TitleLabel") as Label
		var value_label: Label = chip.get_node("Margin/Body/ValueLabel") as Label
		if title_label != null:
			title_label.add_theme_font_size_override("font_size", title_font_size)
		if value_label != null:
			value_label.add_theme_font_size_override("font_size", value_font_size)

func _uses_compact_focus_layout() -> bool:
	if not _is_focused or _layout_variant == &"supporting":
		return false
	# Use the actual resolved size when available so the component can react after the
	# lane finishes sizing it.
	var width_source: float = size.x if size.x > 0.0 else custom_minimum_size.x
	var height_source: float = size.y if size.y > 0.0 else custom_minimum_size.y
	if _layout_variant == &"solo":
		return width_source < 520.0 or height_source < 260.0
	return width_source < 430.0 or height_source < 240.0

func _add_stat_chip(label_text: String, value_text: String, tone: String) -> void:
	var chip: StatChipView = _instantiate_stat_chip()
	chip.configure(label_text, value_text, tone)
	_detail_stats.add_child(chip)

func _instantiate_stat_chip() -> StatChipView:
	var node: Node = UiSceneUtils.instantiate_required(stat_chip_scene, "CustomerStageSpotView.stat_chip_scene")
	var chip: StatChipView = node as StatChipView
	assert(chip != null, "CustomerStageSpotView.stat_chip_scene must instantiate StatChipView.")
	return chip

func _patience_tone(current_patience: int) -> String:
	if current_patience <= 1:
		return "danger"
	if current_patience <= 2:
		return "gold"
	return "accent"

func _hunger_tone(remaining_hunger: int) -> String:
	if remaining_hunger >= 3:
		return "danger"
	if remaining_hunger == 2:
		return "gold"
	return "paper"

func _satisfaction_tone(satisfaction_score: int) -> String:
	if satisfaction_score >= CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD:
		return "gold"
	if satisfaction_score >= CustomerInstance.SATISFIED_THRESHOLD:
		return "accent"
	return "paper"

func _truncate(value: String, max_length: int) -> String:
	if value.length() <= max_length:
		return value
	return "%s..." % value.substr(0, max_length - 3)

func _on_focus_pressed() -> void:
	if _customer_index >= 0:
		focus_requested.emit(_customer_index)

func _on_request_pressed() -> void:
	if _customer_index >= 0:
		target_requested.emit(_customer_index)
