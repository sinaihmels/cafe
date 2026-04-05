class_name HandCardView
extends Button

signal action_requested()
signal hover_started()
signal hover_ended()

@export var fallback_texture: Texture2D
@export var normal_style: StyleBox
@export var hover_style: StyleBox
@export var selected_style: StyleBox
@export var disabled_style: StyleBox

@onready var _cost_value: Label = $Margin/Body/TopRow/CostChip/ChipMargin/ChipBody/ValueLabel
@onready var _tag_label: Label = $Margin/Body/TopRow/TagLabel
@onready var _art: TextureRect = $Margin/Body/Art
@onready var _title_label: Label = $Margin/Body/TitleLabel
@onready var _detail_label: Label = $Margin/Body/DetailLabel


var _is_selected: bool = false
var _is_hovered: bool = false
var _configured_card: CardInstance
var _configured_icon_texture: Texture2D
var _configured_playable: bool = false

func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_configuration()

func configure(card: CardInstance, icon_texture: Texture2D, playable: bool, selected: bool) -> void:
	_configured_card = card
	_configured_icon_texture = icon_texture
	_configured_playable = playable
	_is_selected = selected
	if is_node_ready():
		_apply_configuration()

func set_hovered(hovered: bool) -> void:
	_is_hovered = hovered
	if is_node_ready():
		_apply_style()

func _apply_configuration() -> void:
	if _configured_card == null:
		return
	_cost_value.text = str(_configured_card.get_cost())
	_tag_label.text = UiTextFormatter.join_packed(_configured_card.get_all_tags())
	_art.texture = _configured_icon_texture if _configured_icon_texture != null else fallback_texture
	_title_label.text = _configured_card.get_display_name()
	_detail_label.text = _configured_card.get_preview_text()
	disabled = not _configured_playable
	_apply_style()

func _apply_style() -> void:
	var style: StyleBox = normal_style
	if disabled and disabled_style != null:
		style = disabled_style
	elif _is_selected and selected_style != null:
		style = selected_style
	elif _is_hovered and hover_style != null:
		style = hover_style
	if style != null:
		add_theme_stylebox_override("normal", style)
		add_theme_stylebox_override("hover", hover_style if hover_style != null else style)
		add_theme_stylebox_override("pressed", selected_style if selected_style != null else style)
		add_theme_stylebox_override("disabled", disabled_style if disabled_style != null else style)

func _on_pressed() -> void:
	action_requested.emit()

func _on_mouse_entered() -> void:
	hover_started.emit()

func _on_mouse_exited() -> void:
	hover_ended.emit()
