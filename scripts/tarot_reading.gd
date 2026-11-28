class_name TarotReading
extends RefCounted

## Composes a deterministic tarot reading from the marks a player kept and the
## final stat balance. No external model, no randomness: variety comes from the
## combination of card, orientation, position, and stat profile.

const POSITION_KEYS := [
	"reading.pos_past",
	"reading.pos_obstacle",
	"reading.pos_desire",
	"reading.pos_price",
	"reading.pos_path",
]


static func compose(marks: Array, stats: Dictionary, won: bool) -> String:
	var zh := Loc.language == "zh"
	var lines: PackedStringArray = []
	lines.append(_stat_lead(stats))
	var count := mini(marks.size(), POSITION_KEYS.size())
	if count == 0:
		lines.append("")
		lines.append(Loc.t("reading.no_marks"))
	else:
		lines.append("")
		for i in count:
			lines.append(_position_line(i, marks[i], zh))
	lines.append("")
	lines.append(_closing(stats, won))
	return "\n".join(lines)


static func _stat_lead(stats: Dictionary) -> String:
	var highest := _highest_stat(stats)
	return Loc.t("reading.stat_" + highest)


static func _highest_stat(stats: Dictionary) -> String:
	var best := GameManager.STAT_KEYS[0]
	for key: String in GameManager.STAT_KEYS:
		if int(stats[key]) > int(stats[best]):
			best = key
	return best


static func _position_line(index: int, mark: Dictionary, zh: bool) -> String:
	var card_id := int(mark["card_id"])
	var orientation := str(mark["orientation"])
	var name := Loc.card_name(card_id)
	var orient := Loc.orientation_name(orientation)
	var meaning := CardMeanings.get_meaning(card_id, orientation)
	var keywords := str(meaning["keywords"])
	var line_meaning := str(meaning["meaning"])
	var position := Loc.t(POSITION_KEYS[index])
	if zh:
		return "【%s】%s（%s）· %s ｜ %s" % [position, name, orient, keywords, line_meaning]
	return "[%s] %s (%s) · %s | %s" % [position, name, orient, keywords, line_meaning]


static func _closing(stats: Dictionary, won: bool) -> String:
	if won:
		return Loc.t("reading.closing_won")
	return Loc.tf("reading.closing_death", [Loc.stat_name(_crossed_stat(stats))])


static func _crossed_stat(stats: Dictionary) -> String:
	for key: String in GameManager.STAT_KEYS:
		var value := int(stats[key])
		if value <= 0 or value >= 10:
			return key
	return GameManager.STAT_KEYS[0]
