class_name DialogueResponseOptionView
extends Button

signal response_selected(response_index: int)

@export var dialogue_theme: DialogueThemeDef

var _response_index: int = -1

func _ready() -> void:
	_apply_dialogue_theme()
	pressed.connect(_on_pressed)

func configure(response_index: int, option: DialogueResponseOption) -> void:
	_response_index = response_index
	text = option.text
	disabled = option.disabled
	_apply_dialogue_theme()

func set_dialogue_theme(theme_def: DialogueThemeDef) -> void:
	dialogue_theme = theme_def
	_apply_dialogue_theme()

func _on_pressed() -> void:
	if _response_index >= 0:
		response_selected.emit(_response_index)

func _apply_dialogue_theme() -> void:
	if dialogue_theme == null or not is_node_ready():
		return
	custom_minimum_size.y = dialogue_theme.response_button_min_height
	add_theme_font_size_override("font_size", dialogue_theme.response_font_size)
	add_theme_color_override("font_color", dialogue_theme.button_text_color)
	add_theme_color_override("font_hover_color", dialogue_theme.button_text_color)
	add_theme_color_override("font_pressed_color", dialogue_theme.button_text_pressed_color)
	add_theme_color_override("font_disabled_color", dialogue_theme.button_text_disabled_color)
	add_theme_stylebox_override(
		"normal",
		dialogue_theme.build_response_button_style(
			dialogue_theme.response_button_color,
			dialogue_theme.response_button_border_color
		)
	)
	add_theme_stylebox_override(
		"hover",
		dialogue_theme.build_response_button_style(
			dialogue_theme.response_button_hover_color,
			dialogue_theme.response_button_hover_border_color
		)
	)
	add_theme_stylebox_override(
		"pressed",
		dialogue_theme.build_response_button_style(
			dialogue_theme.response_button_pressed_color,
			dialogue_theme.response_button_hover_border_color
		)
	)
	add_theme_stylebox_override(
		"focus",
		dialogue_theme.build_response_button_style(
			dialogue_theme.response_button_hover_color,
			dialogue_theme.response_button_hover_border_color
		)
	)
	add_theme_stylebox_override(
		"disabled",
		dialogue_theme.build_response_button_style(
			dialogue_theme.response_button_disabled_color,
			dialogue_theme.response_button_disabled_border_color
		)
	)
	if dialogue_theme.button_font != null:
		add_theme_font_override("font", dialogue_theme.button_font)
