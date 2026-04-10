class_name KitchenStageAreaView
extends Control

@export var base_texture: Texture2D
@export var overlay_texture: Texture2D
@export var zone_scene: PackedScene
@export var title_text: String = ""

@onready var _background: TextureRect = $Background
@onready var _overlay: TextureRect = $Overlay
@onready var _title_label: Label = $TitleLabel
@onready var _content_anchor: Control = $ContentAnchor

var _resolved_base_texture: Texture2D
var _resolved_overlay_texture: Texture2D
var _zone_view: Control

func setup_stage() -> void:
	_resolved_base_texture = base_texture
	_resolved_overlay_texture = overlay_texture
	_apply_visuals()
	_instantiate_zone_view()

func set_runtime_textures(stage_base_texture: Texture2D, stage_overlay_texture: Texture2D = null) -> void:
	_resolved_base_texture = stage_base_texture
	_resolved_overlay_texture = stage_overlay_texture
	if is_node_ready():
		_apply_visuals()

func get_zone_view() -> Control:
	return _zone_view

func get_decoration_anchor() -> Control:
	return $DecorationAnchor

func _apply_visuals() -> void:
	_title_label.text = title_text
	_background.texture = _resolved_base_texture
	_background.visible = _resolved_base_texture != null
	_overlay.texture = _resolved_overlay_texture
	_overlay.visible = _resolved_overlay_texture != null

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
