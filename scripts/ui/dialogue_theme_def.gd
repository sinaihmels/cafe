class_name DialogueThemeDef
extends Resource

@export_group("Fonts")
@export var title_font: Font
@export var body_font: Font
@export var button_font: Font

@export_group("Text Colors")
@export var title_text_color: Color = Color(0.99, 0.97, 0.94, 1.0)
@export var body_text_color: Color = Color(0.98, 0.95, 0.90, 1.0)
@export var bubble_name_color: Color = Color(0.34, 0.21, 0.12, 1.0)
@export var bubble_text_color: Color = Color(0.24, 0.16, 0.11, 1.0)
@export var button_text_color: Color = Color(0.27, 0.18, 0.11, 1.0)
@export var button_text_pressed_color: Color = Color(0.99, 0.97, 0.94, 1.0)
@export var button_text_disabled_color: Color = Color(0.67, 0.62, 0.57, 1.0)

@export_group("Surfaces")
@export var backdrop_color: Color = Color(0.08, 0.06, 0.05, 0.42)
@export var modal_background_color: Color = Color(0.96, 0.93, 0.88, 0.98)
@export var modal_border_color: Color = Color(0.47, 0.31, 0.20, 0.98)
@export var modal_shadow_color: Color = Color(0.14, 0.09, 0.06, 0.66)
@export var portrait_background_color: Color = Color(0.85, 0.76, 0.66, 0.98)
@export var bubble_background_color: Color = Color(0.98, 0.95, 0.91, 0.98)
@export var bubble_border_color: Color = Color(0.45, 0.30, 0.20, 0.98)
@export var bubble_shadow_color: Color = Color(0.14, 0.09, 0.06, 0.44)
@export var continue_button_color: Color = Color(0.56, 0.35, 0.23, 1.0)
@export var continue_button_hover_color: Color = Color(0.64, 0.41, 0.26, 1.0)
@export var continue_button_pressed_color: Color = Color(0.44, 0.27, 0.18, 1.0)
@export var continue_button_border_color: Color = Color(0.95, 0.88, 0.80, 1.0)
@export var response_button_color: Color = Color(0.96, 0.88, 0.78, 0.98)
@export var response_button_hover_color: Color = Color(1.0, 0.92, 0.80, 1.0)
@export var response_button_pressed_color: Color = Color(0.93, 0.84, 0.73, 1.0)
@export var response_button_disabled_color: Color = Color(0.78, 0.74, 0.70, 0.82)
@export var response_button_border_color: Color = Color(0.39, 0.27, 0.18, 0.98)
@export var response_button_hover_border_color: Color = Color(0.55, 0.34, 0.20, 1.0)
@export var response_button_disabled_border_color: Color = Color(0.49, 0.43, 0.37, 0.60)

@export_group("Typography")
@export_range(8, 64, 1) var title_font_size: int = 26
@export_range(8, 48, 1) var body_font_size: int = 22
@export_range(8, 48, 1) var response_font_size: int = 18
@export_range(8, 48, 1) var continue_font_size: int = 20
@export_range(8, 32, 1) var bubble_name_font_size: int = 16
@export_range(8, 32, 1) var bubble_text_font_size: int = 17

@export_group("Layout")
@export var modal_min_size: Vector2 = Vector2(520, 280)
@export var portrait_shell_size: Vector2 = Vector2(92, 92)
@export var response_button_min_height: float = 48.0
@export var continue_button_min_height: float = 46.0
@export var bubble_min_size: Vector2 = Vector2(240, 84)
@export_range(0, 64, 1) var modal_padding_horizontal: int = 20
@export_range(0, 64, 1) var modal_padding_vertical: int = 18
@export_range(0, 48, 1) var modal_header_spacing: int = 14
@export_range(0, 48, 1) var response_spacing: int = 10
@export_range(0, 48, 1) var modal_content_spacing: int = 16
@export_range(0, 48, 1) var bubble_padding_horizontal: int = 14
@export_range(0, 48, 1) var bubble_padding_vertical: int = 10
@export_range(0, 48, 1) var bubble_content_spacing: int = 4

@export_group("Shape")
@export_range(0, 48, 1) var modal_corner_radius: int = 24
@export_range(0, 48, 1) var portrait_corner_radius: int = 18
@export_range(0, 48, 1) var bubble_corner_radius: int = 22
@export_range(0, 48, 1) var button_corner_radius: int = 18
@export_range(0, 12, 1) var modal_border_width: int = 3
@export_range(0, 12, 1) var bubble_border_width: int = 2
@export_range(0, 12, 1) var button_border_width: int = 2
@export_range(0, 24, 1) var modal_shadow_size: int = 12
@export_range(0, 24, 1) var bubble_shadow_size: int = 10
@export var modal_shadow_offset: Vector2 = Vector2(0, 3)
@export var bubble_shadow_offset: Vector2 = Vector2(0, 2)

func build_modal_panel_style() -> StyleBoxFlat:
	return _build_box(
		modal_background_color,
		modal_border_color,
		modal_corner_radius,
		modal_border_width,
		modal_shadow_color,
		modal_shadow_size,
		modal_shadow_offset
	)

func build_portrait_shell_style() -> StyleBoxFlat:
	return _build_box(
		portrait_background_color,
		Color(0, 0, 0, 0),
		portrait_corner_radius,
		0,
		Color(0, 0, 0, 0),
		0,
		Vector2.ZERO
	)

func build_bubble_panel_style() -> StyleBoxFlat:
	return _build_box(
		bubble_background_color,
		bubble_border_color,
		bubble_corner_radius,
		bubble_border_width,
		bubble_shadow_color,
		bubble_shadow_size,
		bubble_shadow_offset
	)

func build_continue_button_style(background_color: Color) -> StyleBoxFlat:
	return _build_box(
		background_color,
		continue_button_border_color,
		button_corner_radius,
		button_border_width,
		Color(0, 0, 0, 0),
		0,
		Vector2.ZERO
	)

func build_response_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	return _build_box(
		background_color,
		border_color,
		button_corner_radius,
		button_border_width,
		Color(0, 0, 0, 0),
		0,
		Vector2.ZERO
	)

func _build_box(
	background_color: Color,
	border_color: Color,
	corner_radius: int,
	border_width: int,
	shadow_color: Color,
	shadow_size: int,
	shadow_offset: Vector2
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = shadow_offset
	return style
