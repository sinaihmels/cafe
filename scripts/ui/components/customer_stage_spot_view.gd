@tool
class_name CustomerStageSpotView
extends PanelContainer

signal focus_requested(customer_index: int)
signal target_requested(customer_index: int)

@export var stat_chip_scene: PackedScene
@export var normal_style: StyleBox
@export var focused_style: StyleBox
@export var targetable_style: StyleBox
@export var selected_style: StyleBox
@export_group("Display Scale")
@export_range(0.5, 2.0, 0.01) var display_scale_min: float = 0.78
@export_range(0.5, 2.0, 0.01) var display_scale_max: float = 1.12
@export_group("Spacing")
@export var body_margin_base: float = 8.0
@export var body_margin_min: int = 4
@export var row_separation_default: float = 12.0
@export var row_separation_solo: float = 10.0
@export var row_separation_compact_focused: float = 9.0
@export var row_separation_compact_solo: float = 8.0
@export var row_separation_min: int = 6
@export var actor_column_separation: float = 6.0
@export var actor_column_separation_min: int = 4
@export var detail_stats_separation: float = 6.0
@export var compact_detail_stats_separation: float = 4.0
@export var detail_stats_separation_min: int = 4
@export_group("Portrait Sizes")
@export var solo_portrait_size: Vector2 = Vector2(122.0, 150.0)
@export var focused_portrait_size: Vector2 = Vector2(132.0, 162.0)
@export var supporting_portrait_size: Vector2 = Vector2(116.0, 138.0)
@export var compact_focused_portrait_size: Vector2 = Vector2(98.0, 118.0)
@export var regular_portrait_min_size: Vector2 = Vector2(100.0, 126.0)
@export var compact_portrait_min_size: Vector2 = Vector2(88.0, 108.0)
@export_group("Request Layout")
@export var request_width_source_fallback: float = 320.0
@export var default_detail_width: float = 212.0
@export var default_detail_width_min: float = 156.0
@export var default_request_width: float = 210.0
@export var default_request_width_min: float = 156.0
@export var default_request_height: float = 96.0
@export var default_request_height_min: float = 82.0
@export_range(0.1, 1.0, 0.01) var solo_detail_width_ratio: float = 0.56
@export var solo_detail_width_min: float = 196.0
@export var solo_detail_width_max: float = 328.0
@export_range(0.1, 1.0, 0.01) var solo_request_width_ratio: float = 0.52
@export var solo_request_width_min: float = 184.0
@export var solo_request_width_max: float = 300.0
@export var solo_request_height: float = 78.0
@export var solo_request_height_min: float = 64.0
@export_range(0.1, 1.0, 0.01) var focused_detail_width_ratio: float = 0.48
@export var focused_detail_width_min: float = 184.0
@export var focused_detail_width_max: float = 338.0
@export_range(0.1, 1.0, 0.01) var focused_request_width_ratio: float = 0.46
@export var focused_request_width_min: float = 176.0
@export var focused_request_width_max: float = 320.0
@export_range(0.1, 1.0, 0.01) var compact_detail_width_ratio: float = 0.40
@export var compact_detail_width_min: float = 146.0
@export var compact_detail_width_max: float = 214.0
@export_range(0.1, 1.0, 0.01) var compact_request_width_ratio: float = 0.38
@export var compact_request_width_min: float = 138.0
@export var compact_request_width_max: float = 204.0
@export var compact_request_height: float = 62.0
@export var compact_request_height_min: float = 54.0
@export_group("Badge and Type")
@export var supporting_badge_size: float = 34.0
@export var focused_badge_size: float = 38.0
@export var compact_badge_size: float = 30.0
@export var regular_badge_min_size: float = 28.0
@export var compact_badge_min_size: float = 24.0
@export var satisfaction_badge_extra_width: float = 8.0
@export var satisfaction_badge_min_width: float = 38.0
@export var regular_name_font_size: float = 22.0
@export var compact_name_font_size: float = 16.0
@export var name_font_size_min: int = 13
@export var regular_request_font_size: float = 15.0
@export var compact_request_font_size: float = 13.0
@export var request_font_size_min: int = 10
@export var compact_request_label_font_size: float = 11.0
@export var compact_stats_label_font_size: float = 12.0
@export var compact_labels_font_size_min: int = 10
@export var badge_value_font_size: float = 14.0
@export var badge_value_font_size_min: int = 11
@export_group("Compact Thresholds")
@export var focused_compact_width_threshold: float = 430.0
@export var focused_compact_height_threshold: float = 240.0
@export var solo_compact_width_threshold: float = 520.0
@export var solo_compact_height_threshold: float = 260.0
@export_group("Stat Chips")
@export_range(0.1, 1.0, 0.01) var regular_stat_chip_width_ratio: float = 0.48
@export var regular_stat_chip_width_min: float = 108.0
@export var regular_stat_chip_width_max: float = 148.0
@export var regular_stat_chip_height: float = 56.0
@export var regular_stat_chip_title_font_size: int = 11
@export var regular_stat_chip_value_font_size: int = 15
@export_range(0.1, 1.0, 0.01) var compact_stat_chip_width_ratio: float = 0.48
@export var compact_stat_chip_width_min: float = 76.0
@export var compact_stat_chip_width_max: float = 104.0
@export var compact_stat_chip_height: float = 36.0
@export var compact_stat_chip_title_font_size: int = 9
@export var compact_stat_chip_value_font_size: int = 11

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
var _editor_refresh_signature: Array = []

func _ready() -> void:
	_focus_button.pressed.connect(_on_focus_pressed)
	_request_button.pressed.connect(_on_request_pressed)
	if Engine.is_editor_hint():
		_editor_refresh_signature = _make_editor_refresh_signature()
		set_process(true)
		if _customer == null:
			_render_editor_preview()
			return
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
	_display_scale = clampf(display_scale, display_scale_min, display_scale_max)
	if is_node_ready():
		_apply_configuration()

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var signature: Array = _make_editor_refresh_signature()
	if signature == _editor_refresh_signature:
		return
	_editor_refresh_signature = signature
	_refresh_editor_preview()

func _apply_configuration() -> void:
	UiSceneUtils.clear_children(_detail_stats)
	if _customer == null:
		_request_text = _request_button.text
		_apply_style()
		_apply_layout_scale()
		return
	_request_text = UiTextFormatter.describe_customer_request(_customer)
	# Focused customers switch to a tighter layout when the lane gives them a narrow card.
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
	var margin: int = maxi(body_margin_min, int(round(body_margin_base * _display_scale)))
	_body_margin.add_theme_constant_override("margin_left", margin)
	_body_margin.add_theme_constant_override("margin_top", margin)
	_body_margin.add_theme_constant_override("margin_right", margin)
	_body_margin.add_theme_constant_override("margin_bottom", margin)
	var row_separation_base: float = row_separation_default
	if is_solo:
		row_separation_base = row_separation_solo
	if is_compact_focused:
		row_separation_base = row_separation_compact_solo if is_solo else row_separation_compact_focused
	_stage_row.add_theme_constant_override("separation", maxi(row_separation_min, int(round(row_separation_base * _display_scale))))
	_actor_column.add_theme_constant_override("separation", maxi(actor_column_separation_min, int(round(actor_column_separation * _display_scale))))
	var portrait_size: Vector2 = supporting_portrait_size
	if is_solo:
		portrait_size = solo_portrait_size
	elif is_compact_focused:
		portrait_size = compact_focused_portrait_size
	elif _is_focused:
		portrait_size = focused_portrait_size
	var portrait_min_size: Vector2 = compact_portrait_min_size if is_compact_focused else regular_portrait_min_size
	_portrait_shell.custom_minimum_size = Vector2(
		maxf(portrait_min_size.x, portrait_size.x * _display_scale),
		maxf(portrait_min_size.y, portrait_size.y * _display_scale)
	)
	var request_width_source: float = size.x if size.x > 0.0 else custom_minimum_size.x
	if request_width_source <= 0.0:
		request_width_source = request_width_source_fallback
	var detail_width: float = maxf(default_detail_width_min, default_detail_width * _display_scale)
	var request_width: float = maxf(default_request_width_min, default_request_width * _display_scale)
	var request_height: float = maxf(default_request_height_min, default_request_height * _display_scale)
	if is_solo:
		detail_width = clampf(request_width_source * solo_detail_width_ratio, solo_detail_width_min, solo_detail_width_max)
		request_width = clampf(request_width_source * solo_request_width_ratio, solo_request_width_min, solo_request_width_max)
		request_height = maxf(solo_request_height_min, solo_request_height * _display_scale)
	elif _is_focused:
		detail_width = clampf(request_width_source * focused_detail_width_ratio, focused_detail_width_min, focused_detail_width_max)
		request_width = clampf(request_width_source * focused_request_width_ratio, focused_request_width_min, focused_request_width_max)
	if is_compact_focused:
		# Compact focused mode keeps the detail view readable when the lane is shared.
		detail_width = clampf(request_width_source * compact_detail_width_ratio, compact_detail_width_min, compact_detail_width_max)
		request_width = clampf(request_width_source * compact_request_width_ratio, compact_request_width_min, compact_request_width_max)
		request_height = maxf(compact_request_height_min, compact_request_height * _display_scale)
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
	var badge_base: float = compact_badge_size if is_compact_focused else (focused_badge_size if _is_focused else supporting_badge_size)
	var badge_min_size: float = compact_badge_min_size if is_compact_focused else regular_badge_min_size
	var badge_size: float = maxf(badge_min_size, badge_base * _display_scale)
	_patience_badge.custom_minimum_size = Vector2.ONE * badge_size
	_hunger_badge.custom_minimum_size = Vector2.ONE * badge_size
	_satisfaction_badge.custom_minimum_size = Vector2(
		maxf(badge_size + satisfaction_badge_extra_width, satisfaction_badge_min_width),
		badge_size
	)
	_name_label.add_theme_font_size_override(
		"font_size",
		maxi(name_font_size_min, int(round((compact_name_font_size if is_compact_focused else regular_name_font_size) * _display_scale)))
	)
	_request_button.add_theme_font_size_override(
		"font_size",
		maxi(request_font_size_min, int(round((compact_request_font_size if is_compact_focused else regular_request_font_size) * _display_scale)))
	)
	var detail_stat_spacing: float = compact_detail_stats_separation if is_compact_focused else detail_stats_separation
	_detail_stats.add_theme_constant_override("h_separation", maxi(detail_stats_separation_min, int(round(detail_stat_spacing * _display_scale))))
	_detail_stats.add_theme_constant_override("v_separation", maxi(detail_stats_separation_min, int(round(detail_stat_spacing * _display_scale))))
	_detail_stats.custom_minimum_size = Vector2(request_width, 0.0)
	_compact_request_label.add_theme_font_size_override("font_size", maxi(compact_labels_font_size_min, int(round(compact_request_label_font_size * _display_scale))))
	_compact_stats_label.add_theme_font_size_override("font_size", maxi(compact_labels_font_size_min, int(round(compact_stats_label_font_size * _display_scale))))
	_patience_value.add_theme_font_size_override("font_size", maxi(badge_value_font_size_min, int(round(badge_value_font_size * _display_scale))))
	_hunger_value.add_theme_font_size_override("font_size", maxi(badge_value_font_size_min, int(round(badge_value_font_size * _display_scale))))
	_satisfaction_value.add_theme_font_size_override("font_size", maxi(badge_value_font_size_min, int(round(badge_value_font_size * _display_scale))))
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
		var compact_width: float = clampf(
			request_width * compact_stat_chip_width_ratio,
			compact_stat_chip_width_min,
			compact_stat_chip_width_max
		)
		var regular_width: float = clampf(
			request_width * regular_stat_chip_width_ratio,
			regular_stat_chip_width_min,
			regular_stat_chip_width_max
		)
		chip.custom_minimum_size = Vector2(
			compact_width if is_compact_focused else regular_width,
			compact_stat_chip_height if is_compact_focused else regular_stat_chip_height
		)
		var title_font_size: int = compact_stat_chip_title_font_size if is_compact_focused else regular_stat_chip_title_font_size
		var value_font_size: int = compact_stat_chip_value_font_size if is_compact_focused else regular_stat_chip_value_font_size
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
		return width_source < solo_compact_width_threshold or height_source < solo_compact_height_threshold
	return width_source < focused_compact_width_threshold or height_source < focused_compact_height_threshold

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

func get_customer_index() -> int:
	return _customer_index

func _on_focus_pressed() -> void:
	if _customer_index >= 0:
		focus_requested.emit(_customer_index)

func _on_request_pressed() -> void:
	if _customer_index >= 0:
		target_requested.emit(_customer_index)

func _render_editor_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var preview_session: SessionService = EncounterEditorPreview.build_session()
	if preview_session == null or preview_session.combat_state.active_customers.is_empty():
		_apply_configuration()
		return
	var preview_customer: CustomerInstance = preview_session.combat_state.active_customers[0]
	var portrait_texture: Texture2D = UiTextureLibrary.customer_texture(preview_customer.customer_def) if preview_customer.customer_def != null else null
	configure(0, preview_customer, portrait_texture, true, false, true, &"focused")

func _make_editor_refresh_signature() -> Array:
	return [
		stat_chip_scene,
		normal_style,
		focused_style,
		targetable_style,
		selected_style,
		display_scale_min,
		display_scale_max,
		body_margin_base,
		body_margin_min,
		row_separation_default,
		row_separation_solo,
		row_separation_compact_focused,
		row_separation_compact_solo,
		row_separation_min,
		actor_column_separation,
		actor_column_separation_min,
		detail_stats_separation,
		compact_detail_stats_separation,
		detail_stats_separation_min,
		solo_portrait_size,
		focused_portrait_size,
		supporting_portrait_size,
		compact_focused_portrait_size,
		regular_portrait_min_size,
		compact_portrait_min_size,
		request_width_source_fallback,
		default_detail_width,
		default_detail_width_min,
		default_request_width,
		default_request_width_min,
		default_request_height,
		default_request_height_min,
		solo_detail_width_ratio,
		solo_detail_width_min,
		solo_detail_width_max,
		solo_request_width_ratio,
		solo_request_width_min,
		solo_request_width_max,
		solo_request_height,
		solo_request_height_min,
		focused_detail_width_ratio,
		focused_detail_width_min,
		focused_detail_width_max,
		focused_request_width_ratio,
		focused_request_width_min,
		focused_request_width_max,
		compact_detail_width_ratio,
		compact_detail_width_min,
		compact_detail_width_max,
		compact_request_width_ratio,
		compact_request_width_min,
		compact_request_width_max,
		compact_request_height,
		compact_request_height_min,
		supporting_badge_size,
		focused_badge_size,
		compact_badge_size,
		regular_badge_min_size,
		compact_badge_min_size,
		satisfaction_badge_extra_width,
		satisfaction_badge_min_width,
		regular_name_font_size,
		compact_name_font_size,
		name_font_size_min,
		regular_request_font_size,
		compact_request_font_size,
		request_font_size_min,
		compact_request_label_font_size,
		compact_stats_label_font_size,
		compact_labels_font_size_min,
		badge_value_font_size,
		badge_value_font_size_min,
		focused_compact_width_threshold,
		focused_compact_height_threshold,
		solo_compact_width_threshold,
		solo_compact_height_threshold,
		regular_stat_chip_width_ratio,
		regular_stat_chip_width_min,
		regular_stat_chip_width_max,
		regular_stat_chip_height,
		regular_stat_chip_title_font_size,
		regular_stat_chip_value_font_size,
		compact_stat_chip_width_ratio,
		compact_stat_chip_width_min,
		compact_stat_chip_width_max,
		compact_stat_chip_height,
		compact_stat_chip_title_font_size,
		compact_stat_chip_value_font_size,
	]

func _refresh_editor_preview() -> void:
	if _customer == null:
		_render_editor_preview()
		return
	_apply_configuration()
