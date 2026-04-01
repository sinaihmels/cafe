class_name DemoView
extends Control

signal dough_selected(dough_id: StringName)
signal card_play_requested(hand_index: int)
signal end_turn_requested()
signal serve_requested()
signal reward_selected(choice_index: int)
signal shop_buy_requested(offer_index: int)
signal shop_continue_requested()
signal advance_phase_requested()
signal restart_requested()

var _title_label: Label
var _background_art: TextureRect
var _phase_label: Label
var _stats_label: Label
var _customer_label: Label
var _food_label: Label
var _oven_label: Label
var _customer_art: TextureRect
var _dough_art: TextureRect
var _dish_art: TextureRect
var _oven_art: TextureRect
var _status_label: Label
var _serve_button: Button
var _end_turn_button: Button
var _options_header: Label
var _options_container: VBoxContainer

var _texture_cache: Dictionary[String, Texture2D] = {}
var _missing_texture_paths: Dictionary[String, bool] = {}

func _ready() -> void:
	_bind_nodes()
	var serve_callable: Callable = Callable(self, "_on_serve_pressed")
	var end_turn_callable: Callable = Callable(self, "_on_end_turn_pressed")
	if _serve_button != null and not _serve_button.pressed.is_connected(serve_callable):
		_serve_button.pressed.connect(serve_callable)
	if _end_turn_button != null and not _end_turn_button.pressed.is_connected(end_turn_callable):
		_end_turn_button.pressed.connect(end_turn_callable)

func render(model: Dictionary) -> void:
	if _title_label == null:
		_bind_nodes()
	if _title_label == null or _options_container == null:
		push_warning("DemoView nodes are not fully bound. Check scene structure.")
		return
	var phase: int = int(model.get("phase", DemoEnums.RunPhase.BOOT))
	_title_label.text = "Cozy Bakery Deckbuilder (Demo)"
	_phase_label.text = "Phase: %s | Encounter: %d / 6" % [
		String(model.get("phase_name", "Unknown")),
		int(model.get("encounter_index", 0)),
	]
	_stats_label.text = "Stress %d/%d | Mana %d/%d | Tips %d" % [
		int(model.get("stress", 0)),
		int(model.get("max_stress", 0)),
		int(model.get("mana", 0)),
		int(model.get("max_mana", 0)),
		int(model.get("tips", 0)),
	]
	_customer_label.text = String(model.get("customer_text", ""))
	_food_label.text = String(model.get("food_text", ""))
	if _oven_label != null:
		_oven_label.text = String(model.get("oven_text", "Oven: Empty"))
	_render_visual_art(model)
	_status_label.text = String(model.get("status_message", ""))
	_serve_button.visible = phase == DemoEnums.RunPhase.ENCOUNTER
	_end_turn_button.visible = phase == DemoEnums.RunPhase.ENCOUNTER
	_serve_button.disabled = not bool(model.get("can_serve", false))
	_end_turn_button.disabled = not bool(model.get("can_end_turn", false))
	_clear_options()
	match phase:
		DemoEnums.RunPhase.DOUGH_SELECT:
			_options_header.text = "Choose Dough"
			_render_dough_choices(model)
		DemoEnums.RunPhase.ENCOUNTER:
			_options_header.text = "Hand"
			_render_hand_cards(model)
		DemoEnums.RunPhase.REWARD:
			_options_header.text = "Choose Reward"
			_render_rewards(model)
		DemoEnums.RunPhase.SHOP:
			_options_header.text = "Shop Offers"
			_render_shop(model)
		DemoEnums.RunPhase.BOSS:
			_options_header.text = "Final Encounter"
			_render_boss_intro()
		DemoEnums.RunPhase.SUMMARY, DemoEnums.RunPhase.GAME_OVER:
			_options_header.text = "Run Complete"
			_render_summary(model)
		_:
			_options_header.text = "Options"

func _render_dough_choices(model: Dictionary) -> void:
	var dough_choices: Array = model.get("dough_choices", [])
	if dough_choices.is_empty():
		_options_container.add_child(_make_info_label("No dough definitions available."))
		return
	for entry in dough_choices:
		var dough_id: StringName = StringName(entry.get("id", ""))
		var button: Button = Button.new()
		button.icon = _resolve_texture([
			DemoArtCatalog.dough_path(dough_id),
			DemoArtCatalog.dough_placeholder_path(),
		])
		button.text = "%s\nDeck: %d cards\nPassive: %s" % [
			String(entry.get("name", "Unknown Dough")),
			int(entry.get("deck_count", 0)),
			_join_values(entry.get("passive_rules", [])),
		]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 78)
		button.pressed.connect(_on_dough_pressed.bind(dough_id))
		_options_container.add_child(button)

func _render_hand_cards(model: Dictionary) -> void:
	var hand_cards: Array = model.get("hand_cards", [])
	if hand_cards.is_empty():
		_options_container.add_child(_make_info_label("No cards in hand. End turn to draw."))
		return
	for entry in hand_cards:
		var index: int = int(entry.get("index", -1))
		var card_entry: Control = _make_hand_card_entry(entry, index)
		_options_container.add_child(card_entry)

func _render_rewards(model: Dictionary) -> void:
	var reward_choices: Array = model.get("reward_choices", [])
	if reward_choices.is_empty():
		_options_container.add_child(_make_info_label("No rewards available."))
		return
	for entry in reward_choices:
		var choice_index: int = int(entry.get("index", -1))
		var button: Button = Button.new()
		button.text = "%s\n%s" % [
			String(entry.get("label", "Reward")),
			String(entry.get("description", "")),
		]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 72)
		button.pressed.connect(_on_reward_pressed.bind(choice_index))
		_options_container.add_child(button)

func _render_shop(model: Dictionary) -> void:
	var offers: Array = model.get("shop_offers", [])
	if offers.is_empty():
		_options_container.add_child(_make_info_label("No offers left. Continue onward."))
	else:
		for entry in offers:
			var offer_index: int = int(entry.get("index", -1))
			var button: Button = Button.new()
			button.text = "%s (Cost %d)\n%s" % [
				String(entry.get("label", "Offer")),
				int(entry.get("cost", 0)),
				String(entry.get("description", "")),
			]
			button.disabled = not bool(entry.get("affordable", false))
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			button.custom_minimum_size = Vector2(0, 76)
			button.pressed.connect(_on_shop_buy_pressed.bind(offer_index))
			_options_container.add_child(button)
	var continue_button: Button = Button.new()
	continue_button.text = "Continue To Next Encounter"
	continue_button.pressed.connect(_on_shop_continue_pressed)
	_options_container.add_child(continue_button)

func _render_boss_intro() -> void:
	_options_container.add_child(_make_info_label("A final critic arrives. This decides the run."))
	var button: Button = Button.new()
	button.text = "Start Final Encounter"
	button.pressed.connect(_on_advance_phase_pressed)
	_options_container.add_child(button)

func _render_summary(model: Dictionary) -> void:
	_options_container.add_child(_make_info_label(String(model.get("summary_message", ""))))
	var button: Button = Button.new()
	button.text = "Back To Dough Select"
	button.pressed.connect(_on_restart_pressed)
	_options_container.add_child(button)

func _clear_options() -> void:
	if _options_container == null:
		return
	for child in _options_container.get_children():
		child.queue_free()

func _make_info_label(value: String) -> Label:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = value
	return label

func _make_hand_card_entry(entry: Dictionary, index: int) -> Control:
	var can_play: bool = bool(entry.get("can_play", false))
	var card_row: PanelContainer = PanelContainer.new()
	card_row.custom_minimum_size = Vector2(0, 132)
	card_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_row.mouse_filter = Control.MOUSE_FILTER_STOP
	card_row.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if can_play else Control.CURSOR_ARROW
	)
	card_row.gui_input.connect(_on_hand_card_gui_input.bind(index, can_play))
	if not can_play:
		card_row.modulate = Color(0.72, 0.72, 0.72, 0.95)
	var row_content: HBoxContainer = HBoxContainer.new()
	row_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_content.add_theme_constant_override("separation", 10)
	card_row.add_child(row_content)
	var card_id: StringName = StringName(entry.get("id", ""))
	var card_art: TextureRect = TextureRect.new()
	card_art.custom_minimum_size = Vector2(96, 120)
	card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_art.texture = _resolve_texture([
		DemoArtCatalog.card_path(card_id),
		DemoArtCatalog.card_base_path(),
	])
	row_content.add_child(card_art)
	var info_column: VBoxContainer = VBoxContainer.new()
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.add_theme_constant_override("separation", 5)
	row_content.add_child(info_column)
	var title_label: Label = Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.text = "%s (Cost %d)" % [
		String(entry.get("name", "Card")),
		int(entry.get("cost", 0)),
	]
	info_column.add_child(title_label)
	var description_label: Label = Label.new()
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.text = String(entry.get("description", ""))
	info_column.add_child(description_label)
	var hint_label: Label = Label.new()
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.text = "Click card to play" if can_play else "Not enough mana"
	info_column.add_child(hint_label)
	return card_row

func _join_values(values: Variant) -> String:
	var output: String = ""
	var array_value: Array = []
	if values is Array:
		array_value = values
	elif values is PackedStringArray:
		for value in values:
			array_value.append(value)
	for index in range(array_value.size()):
		if index > 0:
			output += ", "
		output += String(array_value[index])
	if output == "":
		return "None"
	return output

func _on_hand_card_gui_input(event: InputEvent, index: int, can_play: bool) -> void:
	if not can_play:
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event != null and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_on_card_pressed(index)

func _render_visual_art(model: Dictionary) -> void:
	var customer_id: StringName = StringName(model.get("active_customer_id", ""))
	var dough_id: StringName = StringName(model.get("selected_dough_id", ""))
	var dish_stage_key: StringName = StringName(model.get("dish_stage_key", ""))
	var oven_stage_key: StringName = StringName(model.get("oven_stage_key", ""))
	if _background_art != null:
		_background_art.texture = _load_texture(DemoArtCatalog.background_path())
	if _customer_art != null:
		_customer_art.texture = _resolve_texture([
			DemoArtCatalog.customer_path(customer_id),
			DemoArtCatalog.customer_placeholder_path(),
		])
	if _dough_art != null:
		_dough_art.texture = _resolve_texture([
			DemoArtCatalog.dough_path(dough_id),
			DemoArtCatalog.dough_placeholder_path(),
		])
	if _dish_art != null:
		_dish_art.texture = _resolve_texture([
			DemoArtCatalog.dish_stage_path(dish_stage_key),
			DemoArtCatalog.dish_placeholder_path(),
		])
	if _oven_art != null:
		_oven_art.texture = _resolve_texture([
			DemoArtCatalog.oven_stage_path(oven_stage_key),
			DemoArtCatalog.oven_placeholder_path(),
		])

func _resolve_texture(candidate_paths: Array[String]) -> Texture2D:
	for path_value in candidate_paths:
		var path: String = path_value
		var texture: Texture2D = _load_texture(path)
		if texture != null:
			return texture
	return null

func _load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	if _texture_cache.has(path):
		return _texture_cache[path]
	if _missing_texture_paths.has(path):
		return null
	if not ResourceLoader.exists(path):
		_missing_texture_paths[path] = true
		return null
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		_missing_texture_paths[path] = true
		return null
	_texture_cache[path] = texture
	return texture

func _on_dough_pressed(dough_id: StringName) -> void:
	dough_selected.emit(dough_id)

func _on_card_pressed(index: int) -> void:
	card_play_requested.emit(index)

func _on_end_turn_pressed() -> void:
	end_turn_requested.emit()

func _on_serve_pressed() -> void:
	serve_requested.emit()

func _on_reward_pressed(index: int) -> void:
	reward_selected.emit(index)

func _on_shop_buy_pressed(index: int) -> void:
	shop_buy_requested.emit(index)

func _on_shop_continue_pressed() -> void:
	shop_continue_requested.emit()

func _on_advance_phase_pressed() -> void:
	advance_phase_requested.emit()

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _bind_nodes() -> void:
	_title_label = _pick_node(["Margin/Root/TitleLabel", "MarginContainer/Root/TitleLabel"]) as Label
	_background_art = _pick_node(["BackgroundArt"]) as TextureRect
	_phase_label = _pick_node(["Margin/Root/PhaseLabel", "MarginContainer/Root/PhaseLabel"]) as Label
	_stats_label = _pick_node(["Margin/Root/StatsLabel", "MarginContainer/Root/StatsLabel"]) as Label
	_customer_label = _pick_node(["Margin/Root/CustomerLabel", "MarginContainer/Root/CustomerLabel"]) as Label
	_food_label = _pick_node(["Margin/Root/FoodLabel", "MarginContainer/Root/FoodLabel"]) as Label
	_customer_art = _pick_node([
		"Margin/Root/VisualsRow/CustomerPanel/CustomerMargin/CustomerColumn/CustomerArt",
		"MarginContainer/Root/VisualsRow/CustomerPanel/CustomerMargin/CustomerColumn/CustomerArt",
	]) as TextureRect
	_dough_art = _pick_node([
		"Margin/Root/VisualsRow/DoughPanel/DoughMargin/DoughColumn/DoughArt",
		"MarginContainer/Root/VisualsRow/DoughPanel/DoughMargin/DoughColumn/DoughArt",
	]) as TextureRect
	_dish_art = _pick_node([
		"Margin/Root/VisualsRow/DishPanel/DishMargin/DishColumn/DishArt",
		"MarginContainer/Root/VisualsRow/DishPanel/DishMargin/DishColumn/DishArt",
	]) as TextureRect
	_oven_art = _pick_node([
		"Margin/Root/VisualsRow/OvenVisualPanel/OvenVisualMargin/OvenVisualColumn/OvenArt",
		"MarginContainer/Root/VisualsRow/OvenVisualPanel/OvenVisualMargin/OvenVisualColumn/OvenArt",
	]) as TextureRect
	_oven_label = _pick_node([
		"Margin/Root/OvenPanel/OvenMargin/OvenLabel",
		"MarginContainer/Root/OvenPanel/OvenMargin/OvenLabel",
	]) as Label
	_status_label = _pick_node(["Margin/Root/StatusLabel", "MarginContainer/Root/StatusLabel"]) as Label
	_serve_button = _pick_node([
		"Margin/Root/EncounterActions/ServeButton",
		"MarginContainer/Root/EncounterActions/ServeButton",
	]) as Button
	_end_turn_button = _pick_node([
		"Margin/Root/EncounterActions/EndTurnButton",
		"MarginContainer/Root/EncounterActions/EndTurnButton",
	]) as Button
	_options_header = _pick_node(["Margin/Root/OptionsHeader", "MarginContainer/Root/OptionsHeader"]) as Label
	_options_container = _pick_node([
		"Margin/Root/OptionsScroll/OptionsContainer",
		"MarginContainer/Root/OptionsScroll/OptionsContainer",
	]) as VBoxContainer

func _pick_node(paths: Array[String]) -> Node:
	for path in paths:
		var node: Node = get_node_or_null(path)
		if node != null:
			return node
	return null
