class_name RestartButton3D
extends Node3D

signal pressed

const ICON := "res://assets/icons/refresh_dark.png"
const C_DISC := Color(1.0, 0.95, 0.85, 1.0)
const C_ICON := Color(0.30, 0.20, 0.13, 1.0)
const C_GLOW := Color(1.0, 0.72, 0.30, 1.0)

@onready var area: Area3D = $Area3D

var _body: Node3D
var _halo_root: Node3D
var _glow: MeshInstance3D
var _glow_material: StandardMaterial3D
var _rings: Array[Dictionary] = []
var _light: OmniLight3D
var _highlighted: bool = false
var _hovered: bool = false
var _time: float = 0.0
var _hover_tween: Tween
var _halo_tween: Tween


func _ready() -> void:
	area.input_event.connect(_on_area_input)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)
	_build_button()
	_build_halo()
	set_highlight(false)


func _build_button() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	var disc := MeshInstance3D.new()
	var disc_mesh := CylinderMesh.new()
	disc_mesh.top_radius = 0.38
	disc_mesh.bottom_radius = 0.40
	disc_mesh.height = 0.026
	disc_mesh.radial_segments = 48
	disc.mesh = disc_mesh
	disc.position.y = 0.013
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var disc_material := StandardMaterial3D.new()
	disc_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc_material.albedo_color = C_DISC
	disc.material_override = disc_material
	_body.add_child(disc)

	var icon := Sprite3D.new()
	icon.texture = load(ICON) as Texture2D
	icon.pixel_size = 0.34 / maxf(1.0, float(icon.texture.get_width()))
	icon.position = Vector3(0.0, 0.032, 0.0)
	icon.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	icon.modulate = C_ICON
	icon.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_body.add_child(icon)



func _build_halo() -> void:
	_halo_root = Node3D.new()
	_halo_root.name = "Halo"
	add_child(_halo_root)

	_glow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.4, 2.4)
	_glow.mesh = quad
	_glow.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_glow.position.y = 0.028
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glow_material = StandardMaterial3D.new()
	_glow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glow_material.albedo_color = Color(C_GLOW.r, C_GLOW.g, C_GLOW.b, 0.0)
	_glow_material.albedo_texture = _radial_glow_texture()
	_glow_material.disable_receive_shadows = true
	_glow.material_override = _glow_material
	_halo_root.add_child(_glow)

	for i in 2:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.52 + float(i) * 0.18
		torus.outer_radius = 0.57 + float(i) * 0.18
		torus.rings = 64
		torus.ring_segments = 12
		ring.mesh = torus
		ring.position.y = 0.034 + float(i) * 0.004
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		material.albedo_color = Color(C_GLOW.r, C_GLOW.g, C_GLOW.b, 0.0)
		material.emission_enabled = true
		material.emission = C_GLOW
		material.emission_energy_multiplier = 1.0
		material.disable_receive_shadows = true
		ring.material_override = material
		_halo_root.add_child(ring)
		_rings.append({"mesh": ring, "material": material, "phase": float(i) * 1.7})

	_light = OmniLight3D.new()
	_light.light_color = C_GLOW
	_light.light_energy = 0.0
	_light.omni_range = 3.2
	_light.position.y = 0.9
	_halo_root.add_child(_light)


func _radial_glow_texture() -> ImageTexture:
	var size := 96
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	for y in size:
		for x in size:
			var distance := Vector2(x, y).distance_to(center) / (float(size) * 0.5)
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			alpha = pow(alpha, 2.6)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


func _process(delta: float) -> void:
	if not _highlighted:
		return
	_time += delta
	var pulse := 0.5 + 0.5 * sin(_time * 2.8)
	_glow.scale = Vector3.ONE * (1.0 + 0.10 * sin(_time * 2.1))
	_glow_material.albedo_color.a = 0.22 + 0.34 * pulse
	for ring in _rings:
		var phase: float = float(ring["phase"])
		var ring_pulse := 0.5 + 0.5 * sin(_time * 2.6 + phase)
		var mesh: MeshInstance3D = ring["mesh"]
		var material: StandardMaterial3D = ring["material"]
		mesh.scale = Vector3.ONE * (1.0 + 0.10 * sin(_time * 2.2 + phase))
		material.albedo_color.a = 0.30 + 0.55 * ring_pulse
		material.emission_energy_multiplier = 1.0 + 2.2 * ring_pulse
	_light.light_energy = 0.35 + 0.65 * pulse


func set_highlight(value: bool) -> void:
	if _highlighted == value:
		return
	_highlighted = value
	if _halo_tween != null and _halo_tween.is_valid():
		_halo_tween.kill()
	_halo_root.visible = value
	if not value:
		return
	_time = 0.0
	_halo_root.scale = Vector3(0.72, 1.0, 0.72)
	_halo_tween = create_tween()
	_halo_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_halo_tween.tween_property(_halo_root, "scale", Vector3.ONE, 0.55)


func is_highlighted() -> bool:
	return _highlighted


func _on_mouse_entered() -> void:
	_hovered = true
	_apply_hover()


func _on_mouse_exited() -> void:
	_hovered = false
	_apply_hover()


func _apply_hover() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.set_parallel(true)
	_hover_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(_body, "position:y", 0.05 if _hovered else 0.0, 0.16)
	_hover_tween.tween_property(_body, "scale", Vector3.ONE * (1.06 if _hovered else 1.0), 0.16)


func _on_area_input(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			Audio.play_sfx("card_tap", -5.0)
			pressed.emit()
