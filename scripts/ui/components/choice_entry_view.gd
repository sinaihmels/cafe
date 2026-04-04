class_name ChoiceEntryView
extends PanelContainer

signal primary_action_requested()
signal secondary_action_requested()

@export var placeholder_texture: Texture2D

@onready var _icon: TextureRect = $Margin/Body/Icon
@onready var _title_label: Label = $Margin/Body/TitleLabel
@onready var _description_label: Label = $Margin/Body/DescriptionLabel
@onready var _status_label: Label = $Margin/Body/StatusLabel
@onready var _actions_row: HBoxContainer = $Margin/Body/ActionsRow
@onready var _primary_button: Button = $Margin/Body/ActionsRow/PrimaryButton
@onready var _secondary_button: Button = $Margin/Body/ActionsRow/SecondaryButton

var _configured_icon_texture: Texture2D
var _configured_title_text: String = ""
var _configured_description_text: String = ""
var _configured_status_text: String = ""
var _configured_primary_text: String = ""
var _configured_secondary_text: String = ""
var _configured_primary_enabled: bool = true
var _configured_secondary_enabled: bool = true

func _ready() -> void:
	_primary_button.pressed.connect(_on_primary_pressed)
	_secondary_button.pressed.connect(_on_secondary_pressed)
	_apply_configuration()

func configure(
	icon_texture: Texture2D,
	title_text: String,
	description_text: String,
	status_text: String = "",
	primary_text: String = "",
	secondary_text: String = "",
	primary_enabled: bool = true,
	secondary_enabled: bool = true
) -> void:
	# Dynamic screen lists configure entries before they enter the tree, so apply lazily once nodes exist.
	_configured_icon_texture = icon_texture
	_configured_title_text = title_text
	_configured_description_text = description_text
	_configured_status_text = status_text
	_configured_primary_text = primary_text
	_configured_secondary_text = secondary_text
	_configured_primary_enabled = primary_enabled
	_configured_secondary_enabled = secondary_enabled
	if is_node_ready():
		_apply_configuration()

func _apply_configuration() -> void:
	_icon.texture = _configured_icon_texture if _configured_icon_texture != null else placeholder_texture
	_title_label.text = _configured_title_text
	_description_label.text = _configured_description_text
	_status_label.visible = _configured_status_text != ""
	_status_label.text = _configured_status_text
	_primary_button.visible = _configured_primary_text != ""
	_primary_button.text = _configured_primary_text
	_primary_button.disabled = not _configured_primary_enabled
	_secondary_button.visible = _configured_secondary_text != ""
	_secondary_button.text = _configured_secondary_text
	_secondary_button.disabled = not _configured_secondary_enabled
	_actions_row.visible = _primary_button.visible or _secondary_button.visible

func _on_primary_pressed() -> void:
	primary_action_requested.emit()

func _on_secondary_pressed() -> void:
	secondary_action_requested.emit()
