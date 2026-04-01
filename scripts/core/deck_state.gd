class_name DeckState
extends Resource

@export var draw_pile: Array[CardInstance] = []
@export var discard_pile: Array[CardInstance] = []
@export var hand: Array[CardInstance] = []

func reset_from_cards(cards: Array[CardInstance]) -> void:
	draw_pile.clear()
	for card in cards:
		if card != null:
			draw_pile.append(card.duplicate(true) as CardInstance)
	discard_pile.clear()
	hand.clear()

func draw_one() -> CardInstance:
	if draw_pile.is_empty():
		reshuffle_discard_into_draw()
	if draw_pile.is_empty():
		return null
	var card: CardInstance = draw_pile.pop_front() as CardInstance
	hand.append(card)
	return card

func discard_from_hand(card: CardInstance) -> void:
	var index: int = hand.find(card)
	if index >= 0:
		hand.remove_at(index)
		discard_pile.append(card)

func discard_all_hand() -> void:
	while not hand.is_empty():
		var card: CardInstance = hand.pop_back() as CardInstance
		discard_pile.append(card)

func draw_to_hand_size(hand_size: int) -> void:
	while hand.size() < hand_size:
		var card: CardInstance = draw_one()
		if card == null:
			return

func add_to_discard(card: CardInstance) -> void:
	if card != null:
		discard_pile.append(card)

func reshuffle_discard_into_draw() -> void:
	if discard_pile.is_empty():
		return
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
