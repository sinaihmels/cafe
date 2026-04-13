class_name EncounterDialogueOverlayView
extends Control

signal continue_requested()
signal response_requested(response_index: int)

@export var response_option_scene: PackedScene
@export var dialogue_theme: DialogueThemeDef

@onready var _modal_backdrop: ColorRect = $ModalBackdrop
@onready var _modal_panel: PanelContainer = $ModalBackdrop/ModalPanel
@onready var _modal_margin: MarginContainer = $ModalBackdrop/ModalPanel/ModalMargin
@onready var _content: VBoxContainer = $ModalBackdrop/ModalPanel/ModalMargin/Content
@onready var _top_row: HBoxContainer = $ModalBackdrop/ModalPanel/ModalMargin/Content/TopRow
@onready var _portrait_shell: PanelContainer = $ModalBackdrop/ModalPanel/ModalMargin/Content/TopRow/PortraitShell
@onready var _portrait: TextureRect = $ModalBackdrop/ModalPanel/ModalMargin/Content/TopRow/PortraitShell/Portrait
@onready var _speaker_label: Label = $ModalBackdrop/ModalPanel/ModalMargin/Content/TopRow/SpeakerColumn/SpeakerLabel
@onready var _text_label: Label = $ModalBackdrop/ModalPanel/ModalMargin/Content/TextLabel
@onready var _responses_column: VBoxContainer = $ModalBackdrop/ModalPanel/ModalMargin/Content/ResponsesColumn
@onready var _continue_button: Button = $ModalBackdrop/ModalPanel/ModalMargin/Content/ContinueButton
@onready var _bubble_panel: PanelContainer = $BubblePanel
@onready var _bubble_margin: MarginContainer = $BubblePanel/BubbleMargin
@onready var _bubble_column: VBoxContainer = $BubblePanel/BubbleMargin/BubbleColumn
@onready var _bubble_name_label: Label = $BubblePanel/BubbleMargin/BubbleColumn/BubbleNameLabel
@onready var _bubble_text_label: Label = $BubblePanel/BubbleMargin/BubbleColumn/BubbleTextLabel

var _anchor_provider: Callable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	_bubble_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_dialogue_theme()
	_continue_button.pressed.connect(func() -> void:
		continue_requested.emit()
	)

func set_anchor_provider(anchor_provider: Callable) -> void:
	_anchor_provider = anchor_provider

func render(state: DialoguePresentationState) -> void:
	var is_visible: bool = state != null and state.visible
	visible = is_visible
	if not is_visible:
		return
	_modal_backdrop.visible = state.modal
	_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP if state.modal else Control.MOUSE_FILTER_IGNORE
	_bubble_panel.visible = not state.modal
	if state.modal:
		_render_modal(state)
	else:
		_render_bubble(state)

func _render_modal(state: DialoguePresentationState) -> void:
	_portrait.visible = state.portrait != null
	_portrait.texture = state.portrait
	_speaker_label.text = state.speaker_name
	_text_label.text = state.text
	UiSceneUtils.clear_children(_responses_column)
	for response_index in range(state.responses.size()):
		var option: DialogueResponseOptionView = _instantiate_response_option()
		option.set_dialogue_theme(dialogue_theme)
		option.configure(response_index, state.responses[response_index])
		option.response_selected.connect(func(selected_index: int) -> void:
			response_requested.emit(selected_index)
		)
		_responses_column.add_child(option)
	_responses_column.visible = not state.responses.is_empty()
	_continue_button.visible = state.allow_continue and state.responses.is_empty()

func _render_bubble(state: DialoguePresentationState) -> void:
	_bubble_name_label.text = state.speaker_name
	_bubble_text_label.text = state.text
	if not _anchor_provider.is_valid():
		return
	var anchor_variant: Variant = _anchor_provider.call(state.customer_index)
	if not (anchor_variant is Rect2):
		return
	var anchor_rect: Rect2 = anchor_variant
	if anchor_rect.size == Vector2.ZERO:
		return
	var bubble_size: Vector2 = _bubble_panel.get_combined_minimum_size()
	_bubble_panel.position = Vector2(
		anchor_rect.position.x + (anchor_rect.size.x - bubble_size.x) * 0.5,
		maxf(0.0, anchor_rect.position.y - bubble_size.y - 18.0)
	)

func _instantiate_response_option() -> DialogueResponseOptionView:
	var node: Node = UiSceneUtils.instantiate_required(response_option_scene, "EncounterDialogueOverlayView.response_option_scene")
	var option: DialogueResponseOptionView = node as DialogueResponseOptionView
	assert(option != null, "EncounterDialogueOverlayView.response_option_scene must instantiate DialogueResponseOptionView.")
	return option

func _apply_dialogue_theme() -> void:
	if dialogue_theme == null or not is_node_ready():
		return
	_modal_backdrop.color = dialogue_theme.backdrop_color
	_modal_panel.custom_minimum_size = dialogue_theme.modal_min_size
	var half_modal_size: Vector2 = dialogue_theme.modal_min_size * 0.5
	_modal_panel.offset_left = -half_modal_size.x
	_modal_panel.offset_top = -half_modal_size.y
	_modal_panel.offset_right = half_modal_size.x
	_modal_panel.offset_bottom = half_modal_size.y
	_portrait_shell.custom_minimum_size = dialogue_theme.portrait_shell_size
	_portrait.custom_minimum_size = dialogue_theme.portrait_shell_size
	_bubble_panel.custom_minimum_size = dialogue_theme.bubble_min_size
	_modal_margin.add_theme_constant_override("margin_left", dialogue_theme.modal_padding_horizontal)
	_modal_margin.add_theme_constant_override("margin_top", dialogue_theme.modal_padding_vertical)
	_modal_margin.add_theme_constant_override("margin_right", dialogue_theme.modal_padding_horizontal)
	_modal_margin.add_theme_constant_override("margin_bottom", dialogue_theme.modal_padding_vertical)
	_bubble_margin.add_theme_constant_override("margin_left", dialogue_theme.bubble_padding_horizontal)
	_bubble_margin.add_theme_constant_override("margin_top", dialogue_theme.bubble_padding_vertical)
	_bubble_margin.add_theme_constant_override("margin_right", dialogue_theme.bubble_padding_horizontal)
	_bubble_margin.add_theme_constant_override("margin_bottom", dialogue_theme.bubble_padding_vertical)
	_content.add_theme_constant_override("separation", dialogue_theme.modal_content_spacing)
	_top_row.add_theme_constant_override("separation", dialogue_theme.modal_header_spacing)
	_responses_column.add_theme_constant_override("separation", dialogue_theme.response_spacing)
	_bubble_column.add_theme_constant_override("separation", dialogue_theme.bubble_content_spacing)
	_modal_panel.add_theme_stylebox_override("panel", dialogue_theme.build_modal_panel_style())
	_portrait_shell.add_theme_stylebox_override("panel", dialogue_theme.build_portrait_shell_style())
	_bubble_panel.add_theme_stylebox_override("panel", dialogue_theme.build_bubble_panel_style())
	_speaker_label.add_theme_color_override("font_color", dialogue_theme.title_text_color)
	_text_label.add_theme_color_override("font_color", dialogue_theme.body_text_color)
	_bubble_name_label.add_theme_color_override("font_color", dialogue_theme.bubble_name_color)
	_bubble_text_label.add_theme_color_override("font_color", dialogue_theme.bubble_text_color)
	_speaker_label.add_theme_font_size_override("font_size", dialogue_theme.title_font_size)
	_text_label.add_theme_font_size_override("font_size", dialogue_theme.body_font_size)
	_bubble_name_label.add_theme_font_size_override("font_size", dialogue_theme.bubble_name_font_size)
	_bubble_text_label.add_theme_font_size_override("font_size", dialogue_theme.bubble_text_font_size)
	_continue_button.custom_minimum_size.y = dialogue_theme.continue_button_min_height
	_continue_button.add_theme_font_size_override("font_size", dialogue_theme.continue_font_size)
	_continue_button.add_theme_color_override("font_color", dialogue_theme.button_text_color)
	_continue_button.add_theme_color_override("font_hover_color", dialogue_theme.button_text_color)
	_continue_button.add_theme_color_override("font_pressed_color", dialogue_theme.button_text_pressed_color)
	_continue_button.add_theme_color_override("font_disabled_color", dialogue_theme.button_text_disabled_color)
	_continue_button.add_theme_stylebox_override(
		"normal",
		dialogue_theme.build_continue_button_style(dialogue_theme.continue_button_color)
	)
	_continue_button.add_theme_stylebox_override(
		"hover",
		dialogue_theme.build_continue_button_style(dialogue_theme.continue_button_hover_color)
	)
	_continue_button.add_theme_stylebox_override(
		"pressed",
		dialogue_theme.build_continue_button_style(dialogue_theme.continue_button_pressed_color)
	)
	_continue_button.add_theme_stylebox_override(
		"focus",
		dialogue_theme.build_continue_button_style(dialogue_theme.continue_button_hover_color)
	)
	_continue_button.add_theme_stylebox_override(
		"disabled",
		dialogue_theme.build_continue_button_style(dialogue_theme.continue_button_color.darkened(0.18))
	)
	if dialogue_theme.title_font != null:
		_speaker_label.add_theme_font_override("font", dialogue_theme.title_font)
		_bubble_name_label.add_theme_font_override("font", dialogue_theme.title_font)
	if dialogue_theme.body_font != null:
		_text_label.add_theme_font_override("font", dialogue_theme.body_font)
		_bubble_text_label.add_theme_font_override("font", dialogue_theme.body_font)
	if dialogue_theme.button_font != null:
		_continue_button.add_theme_font_override("font", dialogue_theme.button_font)
