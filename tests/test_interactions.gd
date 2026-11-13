extends Node

var main: Node
var ui: Node
var failed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	ui = main.get_node("UI")

	GameManager.debug_clear_field()
	GameManager.debug_set_field_card(0, 13, "REVERSED")
	GameManager.debug_set_field_card(1, 17, "UPRIGHT")
	GameManager.debug_set_field_card(2, 0, "UPRIGHT")
	await get_tree().process_frame
	check(not main._slot_cards[0].front.visible, "card starts face down on the draw pile")
	check(absf(main._slot_cards[0].front.rotation.z) < 0.01, "reversed card stays upright while moving into place")
	await get_tree().create_timer(1.0).timeout
	check(main._slot_cards[0].front.visible, "card flips face up before moving")
	check(absf(main._slot_cards[0].front.rotation.z - PI) < 0.01, "reversed card flips after arriving")

	# Rolling is independent of selection and applies to every field card.
	GameManager.debug_force_rolls([1])
	main._on_die_clicked()
	await get_tree().create_timer(1.2).timeout
	check_eq(GameManager.selected_slot, -1, "die works before any card is selected")
	var death: Dictionary = GameManager.field_cards[0]
	var tower: Dictionary = GameManager.field_cards[1]
	var fool: Dictionary = GameManager.field_cards[2]
	check_eq(str(death["orientation"]), "REVERSED", "die 1 makes Death reversed")
	check_eq(str(tower["orientation"]), "UPRIGHT", "die 1 makes Tower upright")
	check_eq(str(fool["orientation"]), "UPRIGHT", "die 1 makes Fool upright")
	check_eq(int(death["last_roll"]), 1, "Death uses die 1")
	check_eq(int(tower["last_roll"]), 1, "Tower uses die 1")
	check_eq(int(fool["last_roll"]), 1, "Fool uses die 1")
	check(absf(main._slot_cards[0].front.rotation.z - PI) < 0.01, "reversed card is visibly inverted")
	check(absf(main._slot_cards[1].front.rotation.z) < 0.01, "upright card is not inverted")
	for card in main._slot_cards:
		check(card._action_root == null or not card._action_root.visible, "card actions need a selected card")

	main._on_card_clicked(13)
	await get_tree().process_frame
	check_eq(GameManager.selected_slot, 0, "click selects Death")
	check(main._slot_cards[0]._action_root != null and main._slot_cards[0]._action_root.visible, "Death actions visible")

	main._on_card_clicked(17)
	await get_tree().process_frame
	check_eq(GameManager.selected_slot, 1, "switch selected card")
	check(not main._slot_cards[0]._action_root.visible, "previous card actions hidden")
	check(main._slot_cards[1]._action_root.visible, "Tower actions visible")
	check_eq(str(GameManager.field_cards[0]["orientation"]), "REVERSED", "previous card result persists")

	GameManager.debug_force_rolls([4])
	main._on_die_clicked()
	await get_tree().create_timer(1.2).timeout
	check_eq(str(GameManager.field_cards[0]["orientation"]), "UPRIGHT", "whole field rerolls to Death upright")
	check_eq(str(GameManager.field_cards[1]["orientation"]), "REVERSED", "whole field rerolls to Tower reversed")
	check(absf(main._slot_cards[1].front.rotation.z - PI) < 0.01, "Tower flips visually")

	main._on_card_clicked(13)
	await get_tree().process_frame
	main._slot_cards[0].refuse_pressed.emit()
	check(not main._slot_cards[0]._action_root.visible, "actions hide when refusing")
	await get_tree().create_timer(1.4).timeout
	check_eq(GameManager.choices_completed, 1, "refuse resolves the choice")
	check_eq(GameManager.marks.size(), 0, "refuse gains no mark")
	await get_tree().create_timer(1.3).timeout
	check(main._slot_cards[0] != null and is_instance_valid(main._slot_cards[0]), "refused slot has a card")
	check_eq(int(main._slot_cards[0].card_id), int(GameManager.field_cards[0]["card_id"]), "refused slot refills from the deck")

	Loc.toggle_language()
	await get_tree().process_frame
	check_eq(Loc.language, "en", "language toggles to English")
	Loc.toggle_language()
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout

	print("Interaction smoke failures: %d" % failed)
	get_tree().quit(1 if failed > 0 else 0)


func check(condition: bool, label: String) -> void:
	if not condition:
		failed += 1
		push_error("FAIL " + label)


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		return
	failed += 1
	push_error("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])
