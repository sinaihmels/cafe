class_name TitleScreenView
extends VBoxContainer

signal continue_requested()
signal reset_profile_requested()

@onready var _continue_button: Button = $ContinueButton
@onready var _reset_button: Button = $ResetProfileButton

func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)

func _on_continue_pressed() -> void:
	continue_requested.emit()

func _on_reset_pressed() -> void:
	reset_profile_requested.emit()
