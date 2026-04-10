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
	targetable: bool
) -> void:
	_customer_index = customer_index
	_customer = customer
	_portrait_texture = portrait_texture
	_is_focused = focused
	_is_selected = selected
	_is_targetable = targetable
	if is_node_ready():
		_apply_configuration()

func set_display_scale(display_scale: float) -> void:
	_display_scale = clampf(display_scale, 0.78, 1.12)
	if is_node_ready():
		_apply_layout_scale()

func _apply_configuration() -> void:
	UiSceneUtils.clear_children(_detail_stats)
	if _customer == null:
		return
	var request_text: String = UiTextFormatter.describe_customer_request(_customer)
	_portrait.texture = _portrait_texture if _portrait_texture != null else UiTextureLibrary.customer_texture(null)
	_name_label.text = _customer.get_display_name().to_upper()
	_focus_button.tooltip_text = _customer.get_display_name()
	_info_column.visible = _is_focused
	_request_button.visible = _is_focused
	_request_button.text = request_text
	_request_button.tooltip_text = request_text
	_request_button.disabled = not (_is_selected or _is_targetable)
	_compact_request_label.visible = not _is_focused
	_compact_request_label.text = _compact_request_text(request_text)
	_compact_request_label.tooltip_text = request_text
	_compact_stats_label.visible = not _is_focused
	_compact_stats_label.text = _customer.get_display_name()
	_compact_stats_label.tooltip_text = _customer.get_display_name()
	_patience_value.text = str(_customer.current_patience)
	_hunger_value.text = str(_customer.remaining_hunger)
	_satisfaction_value.text = str(_customer.satisfaction_score)
	_patience_badge.tooltip_text = "Patience"
	_hunger_badge.tooltip_text = "Hunger"
	_satisfaction_badge.tooltip_text = "Satisfaction"
	_detail_stats.visible = _is_focused
	if _is_focused:
		_add_stat_chip("Patience", str(_customer.current_patience), _patience_tone(_customer.current_patience))
		_add_stat_chip("Hunger", str(_customer.remaining_hunger), _hunger_tone(_customer.remaining_hunger))
		_add_stat_chip("Satisfaction", str(_customer.satisfaction_score), _satisfaction_tone(_customer.satisfaction_score))
	_apply_style()
	_apply_layout_scale()

func _apply_layout_scale() -> void:
	var margin: int = maxi(4, int(round(8.0 * _display_scale)))
	_body_margin.add_theme_constant_override("margin_left", margin)
	_body_margin.add_theme_constant_override("margin_top", margin)
	_body_margin.add_theme_constant_override("margin_right", margin)
	_body_margin.add_theme_constant_override("margin_bottom", margin)
	_stage_row.add_theme_constant_override("separation", maxi(6, int(round(12.0 * _display_scale))))
	_actor_column.add_theme_constant_override("separation", maxi(4, int(round(6.0 * _display_scale))))
	var portrait_width: float = 132.0 if _is_focused else 116.0
	var portrait_height: float = 162.0 if _is_focused else 138.0
	_portrait_shell.custom_minimum_size = Vector2(maxf(100.0, portrait_width * _display_scale), maxf(126.0, portrait_height * _display_scale))
	_info_column.custom_minimum_size = Vector2(maxf(156.0, 212.0 * _display_scale), 0.0)
	_request_button.custom_minimum_size = Vector2(maxf(156.0, 210.0 * _display_scale), maxf(82.0, 96.0 * _display_scale))
	var badge_size: float = maxf(28.0, (38.0 if _is_focused else 34.0) * _display_scale)
	_patience_badge.custom_minimum_size = Vector2.ONE * badge_size
	_hunger_badge.custom_minimum_size = Vector2.ONE * badge_size
	_satisfaction_badge.custom_minimum_size = Vector2(maxf(badge_size + 8.0, 38.0), badge_size)
	_name_label.add_theme_font_size_override("font_size", maxi(16, int(round(22.0 * _display_scale))))
	_request_button.add_theme_font_size_override("font_size", maxi(11, int(round(15.0 * _display_scale))))
	_detail_stats.add_theme_constant_override("h_separation", maxi(4, int(round(6.0 * _display_scale))))
	_detail_stats.add_theme_constant_override("v_separation", maxi(4, int(round(6.0 * _display_scale))))
	_compact_request_label.add_theme_font_size_override("font_size", maxi(10, int(round(11.0 * _display_scale))))
	_compact_stats_label.add_theme_font_size_override("font_size", maxi(10, int(round(12.0 * _display_scale))))
	_patience_value.add_theme_font_size_override("font_size", maxi(11, int(round(14.0 * _display_scale))))
	_hunger_value.add_theme_font_size_override("font_size", maxi(11, int(round(14.0 * _display_scale))))
	_satisfaction_value.add_theme_font_size_override("font_size", maxi(11, int(round(14.0 * _display_scale))))

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

func _on_focus_pressed() -> void:
	if _customer_index >= 0:
		focus_requested.emit(_customer_index)

func _on_request_pressed() -> void:
	if _customer_index >= 0:
		target_requested.emit(_customer_index)
