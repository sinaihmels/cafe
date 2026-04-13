@tool
class_name EncounterCounterView
extends Control

@export var counter_texture: Texture2D:
	set(value):
		counter_texture = value
		if is_node_ready():
			_apply_visuals()

@export var texture_modulate: Color = Color(1, 1, 1, 1):
	set(value):
		texture_modulate = value
		if is_node_ready() and _texture != null:
			_texture.modulate = texture_modulate

@export_range(0.08, 0.25, 0.005) var surface_height_ratio: float = 0.152
@export_range(0.05, 0.22, 0.005) var front_top_ratio: float = 0.138
@export_group("Layout Bounds")
@export var layout_min_size: Vector2 = Vector2(180.0, 180.0)
@export var surface_height_min: float = 48.0
@export var surface_height_max: float = 104.0
@export var front_top_min: float = 40.0
@export var front_bottom_clearance: float = 120.0
@export var front_surface_overlap: float = 2.0
@export_range(0.0, 0.1, 0.001) var front_surface_overlap_ratio: float = 0.01

@onready var _texture: TextureRect = $CounterTexture
@onready var _fallback_front: PanelContainer = $FallbackFront
@onready var _fallback_surface: PanelContainer = $FallbackSurface
var _editor_refresh_signature: Array = []

func _ready() -> void:
	if Engine.is_editor_hint():
		_editor_refresh_signature = _make_editor_refresh_signature()
		set_process(true)
	_apply_visuals()
	_layout_children()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_children")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var signature: Array = _make_editor_refresh_signature()
	if signature == _editor_refresh_signature:
		return
	_editor_refresh_signature = signature
	_refresh_editor_preview()

func _apply_visuals() -> void:
	if _texture == null or _fallback_front == null or _fallback_surface == null:
		return
	_texture.texture = counter_texture
	_texture.modulate = texture_modulate
	var use_texture: bool = counter_texture != null
	_texture.visible = use_texture
	_fallback_front.visible = not use_texture
	_fallback_surface.visible = not use_texture
	_layout_children()

func _layout_children() -> void:
	if _texture == null or _fallback_front == null or _fallback_surface == null:
		return
	var resolved_size: Vector2 = Vector2(maxf(layout_min_size.x, size.x), maxf(layout_min_size.y, size.y))
	_apply_rect(_texture, Rect2(Vector2.ZERO, resolved_size))
	var surface_height: float = clampf(resolved_size.y * surface_height_ratio, surface_height_min, surface_height_max)
	var front_top: float = clampf(
		resolved_size.y * front_top_ratio,
		front_top_min,
		resolved_size.y - front_bottom_clearance
	)
	front_top = minf(
		front_top,
		surface_height - front_surface_overlap + maxf(0.0, resolved_size.y * front_surface_overlap_ratio)
	)
	_apply_rect(_fallback_surface, Rect2(Vector2.ZERO, Vector2(resolved_size.x, surface_height)))
	_apply_rect(
		_fallback_front,
		Rect2(Vector2(0.0, front_top), Vector2(resolved_size.x, resolved_size.y - front_top))
	)

func _apply_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y

func _make_editor_refresh_signature() -> Array:
	return [
		counter_texture,
		texture_modulate,
		surface_height_ratio,
		front_top_ratio,
		layout_min_size,
		surface_height_min,
		surface_height_max,
		front_top_min,
		front_bottom_clearance,
		front_surface_overlap,
		front_surface_overlap_ratio,
	]

func _refresh_editor_preview() -> void:
	_apply_visuals()
	_layout_children()
