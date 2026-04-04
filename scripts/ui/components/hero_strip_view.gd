class_name HeroStripView
extends HBoxContainer

@export var hero_card_scene: PackedScene

func render(session_service: SessionService) -> void:
	UiSceneUtils.clear_children(self)
	var dough_id: StringName = session_service.run_state.selected_dough_id
	if dough_id == &"":
		dough_id = &"sweet_dough"
	var dough_def: DoughDef = session_service.content_library.get_dough(dough_id)
	var dough_card: HeroCardView = _instantiate_hero_card()
	dough_card.configure(UiTextureLibrary.dough_texture(dough_def), "Dough")
	add_child(dough_card)
	var customer_texture: Texture2D = UiTextureLibrary.customer_texture(null)
	if not session_service.run_state.current_customer_ids.is_empty():
		var customer_id: StringName = StringName(session_service.run_state.current_customer_ids[0])
		var customer_def: CustomerDef = session_service.content_library.get_customer(customer_id)
		customer_texture = UiTextureLibrary.customer_texture(customer_def)
	var guest_card: HeroCardView = _instantiate_hero_card()
	guest_card.configure(customer_texture, "Guest")
	add_child(guest_card)

func _instantiate_hero_card() -> HeroCardView:
	var node: Node = UiSceneUtils.instantiate_required(hero_card_scene, "HeroStripView.hero_card_scene")
	var hero_card: HeroCardView = node as HeroCardView
	assert(hero_card != null, "HeroStripView.hero_card_scene must instantiate HeroCardView.")
	return hero_card
