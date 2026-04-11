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

func setup_stage() -> void:
	_resolved_base_texture = base_texture
	_resolved_overlay_texture = overlay_texture
	_apply_visuals()
	_instantiate_zone_view()
	_layout_stage_art()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what == NOTIFICATION_RESIZED:
		call_deferred("_layout_stage_art")

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
	# Stage shells are driven from ratios so each station keeps the same visual structure
	# across desktop and handheld-sized windows.
	var resolved_size: Vector2 = Vector2(maxf(220.0, size.x), maxf(180.0, size.y))
	var compactness: float = clampf(
		maxf((440.0 - resolved_size.x) / 180.0, (320.0 - resolved_size.y) / 120.0),
		0.0,
		1.0
	)
	var shell_top: float = clampf(resolved_size.y * lerpf(shell_top_ratio, shell_top_ratio * 0.72, compactness), 4.0, 26.0)
	var shell_bottom: float = clampf(resolved_size.y * lerpf(shell_bottom_ratio, shell_bottom_ratio * 0.8, compactness), 8.0, 24.0)
	var shell_rect: Rect2 = Rect2(
		Vector2.ZERO,
		Vector2(resolved_size.x, maxf(110.0, resolved_size.y - shell_top - shell_bottom))
	)
	shell_rect.position.y = shell_top
	_apply_node_rect(_station_shell, shell_rect)
	var title_top: float = clampf(resolved_size.y * title_top_ratio, 10.0, 22.0)
	var title_height: float = clampf(resolved_size.y * title_height_ratio, 28.0, 48.0)
	var title_width: float = clampf(resolved_size.x * title_width_ratio, 120.0, resolved_size.x - 18.0)
	_apply_node_rect(
		_title_label,
		Rect2(
			Vector2((resolved_size.x - title_width) * 0.5, title_top),
			Vector2(title_width, title_height)
		)
	)
	var inset_side: float = clampf(resolved_size.x * lerpf(inset_side_ratio, inset_side_ratio * 0.85, compactness), 12.0, 34.0)
	var inset_top: float = maxf(
		title_top + title_height + clampf(resolved_size.y * 0.03, 8.0, 18.0),
		shell_top + clampf(resolved_size.y * lerpf(inset_top_ratio, inset_top_ratio * 0.88, compactness), 22.0, 64.0)
	)
	var inset_bottom: float = clampf(resolved_size.y * lerpf(inset_bottom_ratio, inset_bottom_ratio * 0.85, compactness), 10.0, 24.0)
	_apply_node_rect(
		_station_inset,
		Rect2(
			Vector2(inset_side, inset_top),
			Vector2(
				maxf(88.0, resolved_size.x - inset_side * 2.0),
				maxf(92.0, resolved_size.y - inset_top - inset_bottom)
			)
		)
	)
	var content_side: float = clampf(
		resolved_size.x * lerpf(content_side_ratio, content_side_ratio * 0.85, compactness),
		inset_side + 6.0,
		inset_side + 40.0
	)
	var content_top: float = maxf(
		inset_top + clampf(resolved_size.y * 0.03, 8.0, 18.0),
		resolved_size.y * lerpf(content_top_ratio, content_top_ratio * 0.88, compactness)
	)
	var content_bottom: float = clampf(
		resolved_size.y * lerpf(content_bottom_ratio, content_bottom_ratio * 0.85, compactness),
		10.0,
		28.0
	)
	_apply_node_rect(
		_content_anchor,
		Rect2(
			Vector2(content_side, content_top),
			Vector2(
				maxf(72.0, resolved_size.x - content_side * 2.0),
				maxf(80.0, resolved_size.y - content_top - content_bottom)
			)
		)
	)
	if _decoration_anchor != null:
		var decoration_width: float = clampf(resolved_size.x * decoration_width_ratio, 78.0, 148.0)
		var decoration_height: float = clampf(resolved_size.y * decoration_height_ratio, 78.0, 148.0)
		_apply_node_rect(
			_decoration_anchor,
			Rect2(
				Vector2(
					resolved_size.x - decoration_width - maxf(12.0, inset_side * 0.8),
					title_top + 4.0
				),
				Vector2(decoration_width, decoration_height)
			)
		)

func _instantiate_zone_view() -> void:
	UiSceneUtils.clear_children(_content_anchor)
	_zone_view = null
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

func _apply_node_rect(control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.position.x + rect.size.x
	control.offset_bottom = rect.position.y + rect.size.y
