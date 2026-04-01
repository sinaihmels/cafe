class_name DemoDeckState
extends Resource

@export var draw_pile: Array[DemoCardInstance] = []
@export var discard_pile: Array[DemoCardInstance] = []
@export var hand: Array[DemoCardInstance] = []
@export var exhaust_pile: Array[DemoCardInstance] = []

func reset_from_defs(card_defs: Array[DemoCardDef]) -> void:
	draw_pile.clear()
	discard_pile.clear()
	hand.clear()
	exhaust_pile.clear()
	for card_def in card_defs:
		if card_def == null:
			continue
		var instance: DemoCardInstance = DemoCardInstance.new()
		instance.card_def = card_def
		draw_pile.append(instance)
	draw_pile.shuffle()

func draw_one() -> DemoCardInstance:
	if draw_pile.is_empty():
		reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card: DemoCardInstance = draw_pile.pop_front()
	hand.append(card)
	return card

func draw_to_hand_size(target_size: int) -> void:
	while hand.size() < target_size:
		var card: DemoCardInstance = draw_one()
		if card == null:
			return

func discard_card_from_hand(index: int) -> DemoCardInstance:
	if index < 0 or index >= hand.size():
		return null
	var card: DemoCardInstance = hand[index]
	hand.remove_at(index)
	discard_pile.append(card)
	return card

func discard_hand() -> void:
	while not hand.is_empty():
		var card: DemoCardInstance = hand.pop_back()
		discard_pile.append(card)

func add_card_to_discard(card_def: DemoCardDef) -> void:
	if card_def == null:
		return
	var card: DemoCardInstance = DemoCardInstance.new()
	card.card_def = card_def
	discard_pile.append(card)

func reshuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile.shuffle()
