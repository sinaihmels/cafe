class_name HandCardView
extends Control

signal action_requested()
signal hover_started()
signal hover_ended()

@export var normal_modulate: Color = Color(1, 1, 1, 1)
@export var hover_modulate: Color = Color(1, 0.99, 0.96, 1)
@export var selected_modulate: Color = Color(1, 0.96, 0.90, 1)
@export var disabled_modulate: Color = Color(0.78, 0.78, 0.78, 0.82)
@export var hide_art_when_matching_background: bool = true

const DESIGN_SIZE: Vector2 = Vector2(154, 214)

@onready var _content_root: Control = $CardContent
@onready var _background: TextureRect = $CardContent/CardBackground
@onready var _cost_label: Label = $CardContent/EnergyCostLabel
@onready var _display_name_label: Label = $CardContent/DisplayNameLabel
@onready var _pastry_tags_label: Label = $CardContent/PastryTagsLabel
@onready var _preview_label: Label = $CardContent/PreviewLabel
@onready var _art_frame: Control = $CardContent/CardArtFrame
@onready var _card_image: Sprite2D = $CardContent/CardArtFrame/CardImage

var _is_selected: bool = false
var _is_hovered: bool = false
var _configured_card: CardInstance
var _configured_playable: bool = false

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_layout_content_root()
	_apply_configuration()

func configure(card: CardInstance, playable: bool, selected: bool) -> void:
	_configured_card = card
	_configured_playable = playable
	_is_selected = selected
	if is_node_ready():
		_apply_configuration()

func set_hovered(hovered: bool) -> void:
	_is_hovered = hovered
	if is_node_ready():
		_apply_visual_state()

func _gui_input(event: InputEvent) -> void:
	if not _configured_playable:
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed or mouse_event.is_echo():
		return
	accept_event()
	action_requested.emit()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		_layout_content_root()
		_layout_card_art()

func _apply_configuration() -> void:
	if _configured_card == null:
		return
	_cost_label.text = str(_configured_card.get_cost())
	_display_name_label.text = _configured_card.get_display_name()
	_pastry_tags_label.text = _build_pastry_tags_line(_configured_card)
	_preview_label.text = _configured_card.get_preview_text()
	_apply_card_art()
	_apply_visual_state()

func _layout_content_root() -> void:
	if _content_root == null:
		return
	var width_scale: float = size.x / DESIGN_SIZE.x if DESIGN_SIZE.x > 0.0 else 1.0
	var height_scale: float = size.y / DESIGN_SIZE.y if DESIGN_SIZE.y > 0.0 else 1.0
	_content_root.scale = Vector2(width_scale, height_scale)

func _apply_card_art() -> void:
	var art_texture: Texture2D = null
	if _configured_card != null:
		art_texture = _configured_card.get_art_texture()
	var background_texture: Texture2D = _background.texture
	var should_hide_art: bool = art_texture == null
	if hide_art_when_matching_background and art_texture != null and art_texture == background_texture:
		should_hide_art = true
	_card_image.visible = not should_hide_art
	if should_hide_art:
		_card_image.texture = null
		return
	_card_image.texture = art_texture
	_layout_card_art()

func _layout_card_art() -> void:
	if _card_image == null or _card_image.texture == null:
		return
	var frame_size: Vector2 = _art_frame.size
	if frame_size == Vector2.ZERO:
		return
	var texture_size: Vector2 = _card_image.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	_card_image.centered = true
	_card_image.position = frame_size * 0.5
	var scale_factor: float = minf(frame_size.x / texture_size.x, frame_size.y / texture_size.y)
	_card_image.scale = Vector2.ONE * scale_factor

func _build_pastry_tags_line(card: CardInstance) -> String:
	if card == null:
		return "Adds: none"
	var added_tags: PackedStringArray = card.get_pastry_tags_added()
	if added_tags.is_empty():
		return "Adds: none"
	return "Adds: %s" % UiTextFormatter.join_packed(added_tags)

func _apply_visual_state() -> void:
	if not _configured_playable:
		self_modulate = disabled_modulate
	elif _is_selected:
		self_modulate = selected_modulate
	elif _is_hovered:
		self_modulate = hover_modulate
	else:
		self_modulate = normal_modulate

func _on_mouse_entered() -> void:
	hover_started.emit()

func _on_mouse_exited() -> void:
	hover_ended.emit()
