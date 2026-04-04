extends SceneTree

func _init() -> void:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	session.initialize(meta, event_bus)
	meta.reset_profile(session.content_library)

	var sweet_customer: CustomerInstance = CustomerInstance.new()
	sweet_customer.reset_from_def(session.content_library.get_customer(&"sweet_tooth_customer"))
	var chocolate_pastry: PastryInstance = session._create_pastry_from_dough(&"sweet_dough")
	chocolate_pastry.add_pastry_state(&"baked")
	chocolate_pastry.add_pastry_tag(&"chocolaty")
	assert(chocolate_pastry != null, "Chocolate pastry should be creatable from the sweet dough seed.")
	var sweet_outcome: Dictionary = session._score_pastry_for_customer(chocolate_pastry, sweet_customer)
	assert(int(sweet_outcome.get("reputation_delta", 0)) == 3, "Sweet Tooth should reward both the sweet base and the chocolate bonus tag.")
	assert(int(sweet_outcome.get("tips", 0)) == 4, "Sweet Tooth should pay base reward plus the sweet and chocolate bonus tags.")

	var quality_customer: CustomerInstance = CustomerInstance.new()
	quality_customer.reset_from_def(session.content_library.get_customer(&"quality_customer"))
	var plain_pastry: PastryInstance = session._create_pastry_from_dough(&"sweet_dough")
	plain_pastry.add_pastry_state(&"baked")
	assert(plain_pastry != null, "Plain sweet pastry should be creatable from the dough seed.")
	var quality_fail: Dictionary = session._score_pastry_for_customer(plain_pastry, quality_customer)
	assert(int(quality_fail.get("reputation_delta", 0)) < 0, "Quality Seeker should reject pastries missing the required decorated tag.")

	var quality_pastry: PastryInstance = session._create_pastry_from_dough(&"sweet_dough")
	quality_pastry.add_pastry_state(&"baked")
	quality_pastry.add_pastry_state(&"decorated")
	quality_pastry.quality = 1
	assert(quality_pastry != null, "Decorated quality pastry should be creatable from the dough seed.")
	var quality_success: Dictionary = session._score_pastry_for_customer(quality_pastry, quality_customer)
	assert(int(quality_success.get("reputation_delta", 0)) == 4, "Quality Seeker should reward decorated pastries that meet the quality threshold and bonus tags.")
	assert(int(quality_success.get("tips", 0)) == 5, "Quality Seeker should pay base reward plus both quality-related bonus tags.")
	quit()
