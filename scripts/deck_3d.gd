extends Node3D

const TOTAL_VISUAL_CARDS := 22
const DRAWABLE_CARDS := 21
const CARD_WIDTH := 1.5
const CARD_DEPTH := 2.5
const CARD_THICKNESS := 0.008
const TOP_RAISE := 0.03

var _cards: Array[MeshInstance3D] = []
var _top_visual: Node3D
var _remaining := DRAWABLE_CARDS
var _top_tween: Tween


func _ready() -> void:
	_build()


func _build() -> void:
	var deck_material := StandardMaterial3D.new()
	deck_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	deck_material.albedo_color = Color(0.29, 0.14, 0.3, 1.0)
	var icon_material := StandardMaterial3D.new()
	icon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	icon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	icon_material.albedo_color = Color(1.0, 1.0, 1.0, 0.95)
	icon_material.albedo_texture = load("res://assets/icons/cat.png") as Texture2D

	for i in TOTAL_VISUAL_CARDS:
		var card := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(CARD_WIDTH, CARD_THICKNESS, CARD_DEPTH)
		card.mesh = box
		card.material_override = deck_material
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		card.position.y = CARD_THICKNESS * (i + 0.5)
		add_child(card)
		_cards.append(card)

	_top_visual = Node3D.new()
	add_child(_top_visual)
	var face := MeshInstance3D.new()
	var face_box := BoxMesh.new()
	face_box.size = Vector3(CARD_WIDTH, 0.002, CARD_DEPTH)
	face.mesh = face_box
	face.material_override = deck_material
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	face.position.y = 0.002
	_top_visual.add_child(face)
	var icon := MeshInstance3D.new()
	var icon_quad := QuadMesh.new()
	icon_quad.size = Vector2(0.72, 0.72)
	icon.mesh = icon_quad
	icon.material_override = icon_material
	icon.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	icon.position.y = 0.004
	icon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_top_visual.add_child(icon)

	reset()


func reset() -> void:
	_remaining = DRAWABLE_CARDS
	_refresh(false)


func draw_cards(count: int) -> void:
	if count <= 0:
		return
	_remaining = clampi(_remaining - count, 0, DRAWABLE_CARDS)
	_refresh(true)


func top_card_position() -> Vector3:
	var surface := float(_remaining + 1) * CARD_THICKNESS
	return to_global(Vector3(0.0, surface + TOP_RAISE, 0.0))


func _refresh(animate: bool) -> void:
	for i in TOTAL_VISUAL_CARDS:
		_cards[i].visible = i <= _remaining
	var target := float(_remaining + 1) * CARD_THICKNESS
	if _top_tween != null and _top_tween.is_valid():
		_top_tween.kill()
	if not animate:
		_top_visual.position.y = target
		return
	_top_tween = create_tween()
	_top_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_top_tween.tween_property(_top_visual, "position:y", target, 0.25)
