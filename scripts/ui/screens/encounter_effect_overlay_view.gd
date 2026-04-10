class_name EncounterEffectOverlayView
extends Control

@export var pastry_tag_chip_scene: PackedScene

@onready var _effects_layer: Control = $EffectsLayer

var _event_bus: EventBus
var _anchor_provider: Callable

func configure(event_bus: EventBus) -> void:
	var handler: Callable = Callable(self, "_on_pastry_feedback_requested")
	if _event_bus != null and _event_bus.is_connected(&"pastry_feedback_requested", handler):
		_event_bus.disconnect(&"pastry_feedback_requested", handler)
	_event_bus = event_bus
	if _event_bus != null and not _event_bus.is_connected(&"pastry_feedback_requested", handler):
		_event_bus.connect(&"pastry_feedback_requested", handler)

func set_anchor_provider(anchor_provider: Callable) -> void:
	_anchor_provider = anchor_provider

func active_feedback_count() -> int:
	return _effects_layer.get_child_count()

func _on_pastry_feedback_requested(feedback: PastryFeedbackEvent) -> void:
	if feedback == null or not feedback.has_visible_feedback() or not is_visible_in_tree():
		return
	if not _anchor_provider.is_valid():
		return
	var anchor_rect_variant: Variant = _anchor_provider.call(feedback)
	if not (anchor_rect_variant is Rect2):
		return
	var anchor_rect: Rect2 = anchor_rect_variant
	if anchor_rect.size == Vector2.ZERO:
		return
	_spawn_feedback(feedback, anchor_rect)

func _spawn_feedback(feedback: PastryFeedbackEvent, anchor_rect: Rect2) -> void:
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stack: VBoxContainer = VBoxContainer.new()
	stack.name = "Stack"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 4)
	root.add_child(stack)
	for raw_tag in feedback.added_tags:
		var tag_id: StringName = StringName(raw_tag)
		if tag_id == &"":
			continue
		var tag_chip: PastryTagChipView = _instantiate_chip()
		tag_chip.configure(
			UiPastryTagCatalog.label_for_tag(tag_id),
			UiPastryTagCatalog.presentation_for_tag(tag_id)
		)
		stack.add_child(tag_chip)
	for raw_state in feedback.added_states:
		var state_id: StringName = StringName(raw_state)
		if state_id == &"":
			continue
		var state_chip: PastryTagChipView = _instantiate_chip()
		state_chip.configure(
			UiPastryTagCatalog.label_for_state(state_id),
			UiPastryTagCatalog.presentation_for_state(state_id)
		)
		stack.add_child(state_chip)
	if feedback.quality_delta != 0:
		var quality_chip: PastryTagChipView = _instantiate_chip()
		quality_chip.configure(
			UiPastryTagCatalog.quality_label(feedback.quality_delta),
			UiPastryTagCatalog.presentation_for_quality_delta(feedback.quality_delta)
		)
		stack.add_child(quality_chip)
	_effects_layer.add_child(root)
	call_deferred("_layout_and_animate_feedback", root, anchor_rect)

func _layout_and_animate_feedback(root: Control, anchor_rect: Rect2) -> void:
	if not is_instance_valid(root):
		return
	var stack: VBoxContainer = root.get_node("Stack") as VBoxContainer
	if stack == null:
		root.queue_free()
		return
	var stack_size: Vector2 = stack.get_combined_minimum_size()
	root.size = stack_size
	root.position = Vector2(
		anchor_rect.position.x + (anchor_rect.size.x - stack_size.x) * 0.5,
		maxf(0.0, anchor_rect.position.y - stack_size.y - 12.0)
	)
	root.modulate = Color(1, 1, 1, 0)
	var tween: Tween = create_tween()
	tween.tween_property(root, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(root, "position:y", root.position.y - 18.0, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.16)
	tween.tween_property(root, "modulate:a", 0.0, 0.26)
	tween.finished.connect(func() -> void:
		if is_instance_valid(root):
			root.queue_free()
	)

func _instantiate_chip() -> PastryTagChipView:
	var node: Node = UiSceneUtils.instantiate_required(pastry_tag_chip_scene, "EncounterEffectOverlayView.pastry_tag_chip_scene")
	var chip: PastryTagChipView = node as PastryTagChipView
	assert(chip != null, "EncounterEffectOverlayView.pastry_tag_chip_scene must instantiate PastryTagChipView.")
	return chip
