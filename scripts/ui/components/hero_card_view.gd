class_name HeroCardView
extends PanelContainer

@export var fallback_texture: Texture2D

@onready var _art: TextureRect = $Margin/Body/Art
@onready var _caption: Label = $Margin/Body/Caption

var _configured_texture: Texture2D
var _configured_caption: String = ""

func _ready() -> void:
	_apply_configuration()

func configure(texture: Texture2D, caption_text: String) -> void:
	# Parent lists configure cards before add_child(), so cache data until the scene is ready.
	_configured_texture = texture
	_configured_caption = caption_text
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_art.texture = _configured_texture if _configured_texture != null else fallback_texture
	_caption.text = _configured_caption
