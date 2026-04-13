@tool
class_name KitchenStageAreaView
extends Control

@export var base_texture: Texture2D
@export var overlay_texture: Texture2D
@export var zone_scene: PackedScene
@export var title_text: String = ""
@export_range(0.0, 0.2, 0.005) var shell_top_ratio: float = 0.04
@export_range(0.0, 0.2, 0.005) var shell_bottom_ratio: float = 0.03
@export_range(0.0, 0.3, 0.005) var inset_side_ratio: float = 0.055
@export_range(0.0, 0.3, 0.005) var inset_top_ratio: float = 0.19
@export_range(0.0, 0.3, 0.005) var inset_bottom_ratio: float = 0.055
@export_range(0.0, 0.3, 0.005) var content_side_ratio: float = 0.09
@export_range(0.0, 0.4, 0.005) var content_top_ratio: float = 0.25
@export_range(0.0, 0.3, 0.005) var content_bottom_ratio: float = 0.07
@export_range(0.0, 0.2, 0.005) var title_top_ratio: float = 0.05
@export_range(0.2, 1.0, 0.01) var title_width_ratio: float = 0.58
@export_range(0.05, 0.3, 0.005) var title_height_ratio: float = 0.14
@export_range(0.1, 0.5, 0.01) var decoration_width_ratio: float = 0.28
@export_range(0.1, 0.5, 0.01) var decoration_height_ratio: float = 0.34
@export_group("Layout Bounds")
@export var layout_min_size: Vector2 = Vector2(220.0, 180.0)
@export var shell_top_min: float = 4.0
@export var shell_top_max: float = 26.0
@export var shell_bottom_min: float = 8.0
@export var shell_bottom_max: float = 24.0
@export var shell_height_min: float = 110.0
@export var title_top_min: float = 10.0
@export var title_top_max: float = 22.0
@export var title_height_min: float = 28.0
@export var title_height_max: float = 48.0
@export var title_width_min: float = 120.0
@export var title_side_padding: float = 18.0
@export var inset_side_min: float = 12.0
@export var inset_side_max: float = 34.0
@export_range(0.0, 0.2, 0.005) var title_gap_ratio: float = 0.03
@export var title_gap_min: float = 8.0
@export var title_gap_max: float = 18.0
@export var inset_top_min: float = 22.0
@export var inset_top_max: float = 64.0
@export var inset_bottom_min: float = 10.0
@export var inset_bottom_max: float = 24.0
@export var inset_width_min: float = 88.0
@export var inset_height_min: float = 92.0
@export var content_side_extra_min: float = 6.0
@export var content_side_extra_max: float = 40.0
@export_range(0.0, 0.2, 0.005) var content_gap_ratio: float = 0.03
@export var content_gap_min: float = 8.0
@export var content_gap_max: float = 18.0
@export var content_bottom_min: float = 10.0
@export var content_bottom_max: float = 28.0
@export var content_width_min: float = 72.0
@export var content_height_min: float = 80.0
@export var decoration_width_min: float = 78.0
@export var decoration_width_max: float = 148.0
@export var decoration_height_min: float = 78.0
@export var decoration_height_max: float = 148.0
@export var decoration_side_padding_min: float = 12.0
@export var decoration_top_offset: float = 4.0

@onready var _background: TextureRect = $Background
@onready var _overlay: TextureRect = $Overlay
@onready var _station_shell: Control = $StationShell
@onready var _station_inset: Control = $StationInset
@onready var _title_label: Label = $TitleLabel
@onready var _decoration_anchor: Control = $DecorationAnchor
@onready var _content_anchor: Control = $ContentAnchor

var _resolved_base_texture: Texture2D
var _resolved_overlay_texture: Texture2D
var _zone_view: Control
var _editor_refresh_signature: Array = []

func setup_stage() -> void:
	_resolved_base_texture = base_texture
	_resolved_overlay_texture = overlay_texture
	_apply_visuals()
	_instantiate_zone_view()
	_layout_stage_art()
	if Engine.is_editor_hint():
		_editor_refresh_signature = _make_editor_refresh_signature()
		set_process(true)

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_stage_art")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() or not is_node_ready():
		return
	var signature: Array = _make_editor_refresh_signature()
	if signature == _editor_refresh_signature:
		return
	_editor_refresh_signature = signature
	_refresh_editor_preview()

func set_runtime_textures(stage_base_texture: Texture2D, stage_overlay_texture: Texture2D = null) -> void:
	_resolved_base_texture = stage_base_texture
	_resolved_overlay_texture = stage_overlay_texture
	if is_node_ready():
		_apply_visuals()

func get_zone_view() -> Control:
	return _zone_view

func get_decoration_anchor() -> Control:
	return _decoration_anchor

func _apply_visuals() -> void:
	_title_label.text = title_text
	_background.texture = _resolved_base_texture
	_background.visible = _resolved_base_texture != null
	_overlay.texture = _resolved_overlay_texture
	_overlay.visible = _resolved_overlay_texture != null

func _layout_stage_art() -> void:
	if _station_shell == null or _station_inset == null or _title_label == null or _content_anchor == null:
		return
	# Stage shells use one consistent ratio-based composition for the fixed demo layout.
	var resolved_size: Vector2 = Vector2(maxf(layout_min_size.x, size.x), maxf(layout_min_size.y, size.y))
	var shell_top: float = clampf(resolved_size.y * shell_top_ratio, shell_top_min, shell_top_max)
	var shell_bottom: float = clampf(resolved_size.y * shell_bottom_ratio, shell_bottom_min, shell_bottom_max)
	var shell_rect: Rect2 = Rect2(
		Vector2.ZERO,
		Vector2(resolved_size.x, maxf(shell_height_min, resolved_size.y - shell_top - shell_bottom))
	)
	shell_rect.position.y = shell_top
	_apply_node_rect(_station_shell, shell_rect)
	var title_top: float = clampf(resolved_size.y * title_top_ratio, title_top_min, title_top_max)
	var title_height: float = clampf(resolved_size.y * title_height_ratio, title_height_min, title_height_max)
	var title_width: float = clampf(
		resolved_size.x * title_width_ratio,
		title_width_min,
		resolved_size.x - title_side_padding
	)
	_apply_node_rect(
		_title_label,
		Rect2(
			Vector2((resolved_size.x - title_width) * 0.5, title_top),
			Vector2(title_width, title_height)
		)
	)
	var inset_side: float = clampf(resolved_size.x * inset_side_ratio, inset_side_min, inset_side_max)
	var inset_top: float = maxf(
		title_top + title_height + clampf(resolved_size.y * title_gap_ratio, title_gap_min, title_gap_max),
		shell_top + clampf(resolved_size.y * inset_top_ratio, inset_top_min, inset_top_max)
	)
	var inset_bottom: float = clampf(resolved_size.y * inset_bottom_ratio, inset_bottom_min, inset_bottom_max)
	_apply_node_rect(
		_station_inset,
		Rect2(
			Vector2(inset_side, inset_top),
			Vector2(
				maxf(inset_width_min, resolved_size.x - inset_side * 2.0),
				maxf(inset_height_min, resolved_size.y - inset_top - inset_bottom)
			)
		)
	)
	var content_side: float = clampf(
		resolved_size.x * content_side_ratio,
		inset_side + content_side_extra_min,
		inset_side + content_side_extra_max
	)
	var content_top: float = maxf(
		inset_top + clampf(resolved_size.y * content_gap_ratio, content_gap_min, content_gap_max),
		resolved_size.y * content_top_ratio
	)
	var content_bottom: float = clampf(
		resolved_size.y * content_bottom_ratio,
		content_bottom_min,
		content_bottom_max
	)
	_apply_node_rect(
		_content_anchor,
		Rect2(
			Vector2(content_side, content_top),
			Vector2(
				maxf(content_width_min, resolved_size.x - content_side * 2.0),
				maxf(content_height_min, resolved_size.y - content_top - content_bottom)
			)
		)
	)
	if _decoration_anchor != null:
		var decoration_width: float = clampf(resolved_size.x * decoration_width_ratio, decoration_width_min, decoration_width_max)
		var decoration_height: float = clampf(resolved_size.y * decoration_height_ratio, decoration_height_min, decoration_height_max)
		_apply_node_rect(
			_decoration_anchor,
			Rect2(
				Vector2(
					resolved_size.x - decoration_width - maxf(decoration_side_padding_min, inset_side * 0.8),
					title_top + decoration_top_offset
				),
				Vector2(decoration_width, decoration_height)
			)
		)

func _instantiate_zone_view() -> void:
	_zone_view = null
	for child in _content_anchor.get_children():
		var existing_control: Control = child as Control
		if existing_control == null:
			continue
		_zone_view = existing_control
		break
	if _zone_view == null:
		UiSceneUtils.clear_children(_content_anchor)
		if zone_scene == null:
			return
		var node: Node = UiSceneUtils.instantiate_required(zone_scene, "%s.zone_scene" % name)
		_content_anchor.add_child(node)
		_zone_view = node as Control
	assert(_zone_view != null, "%s.zone_scene must instantiate a Control." % name)
	_zone_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zone_view.offset_left = 0.0
	_zone_view.offset_top = 0.0
	_zone_view.offset_right = 0.0
	_zone_view.offset_bottom = 0.0

func _make_editor_refresh_signature() -> Array:
	return [
		base_texture,
		overlay_texture,
		zone_scene,
		title_text,
		shell_top_ratio,
		shell_bottom_ratio,
		inset_side_ratio,
		inset_top_ratio,
		inset_bottom_ratio,
		content_side_ratio,
		content_top_ratio,
		content_bottom_ratio,
		title_top_ratio,
		title_width_ratio,
		title_height_ratio,
		decoration_width_ratio,
		decoration_height_ratio,
		layout_min_size,
		shell_top_min,
		shell_top_max,
		shell_bottom_min,
		shell_bottom_max,
		shell_height_min,
		title_top_min,
		title_top_max,
		title_height_min,
		title_height_max,
		title_width_min,
		title_side_padding,
		inset_side_min,
		inset_side_max,
		title_gap_ratio,
		title_gap_min,
		title_gap_max,
		inset_top_min,
		inset_top_max,
		inset_bottom_min,
		inset_bottom_max,
		inset_width_min,
		inset_height_min,
		content_side_extra_min,
		content_side_extra_max,
		content_gap_ratio,
		content_gap_min,
		content_gap_max,
		content_bottom_min,
		content_bottom_max,
		content_width_min,
		content_height_min,
		decoration_width_min,
		decoration_width_max,
		decoration_height_min,
		decoration_height_max,
		decoration_side_padding_min,
		decoration_top_offset,
	]

func _refresh_editor_preview() -> void:
	_resolved_base_texture = base_texture
	_resolved_overlay_texture = overlay_texture
	_instantiate_zone_view()
	_layout_stage_art()
	if has_method("render_editor_preview"):
		call_deferred("render_editor_preview")
	else:
		_apply_visuals()

func _apply_node_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
