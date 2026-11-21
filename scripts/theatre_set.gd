class_name TheatreSet
extends Node3D

const GALLERY := 0
const START := 1
const CONTINUE := 2
const SETTINGS := 3
const QUIT := 4
const MODELS := "res://assets/models/theatre/"
const VELVET := preload("res://shaders/theatre_velvet.gdshader")
const FOIL := preload("res://shaders/theatre_foil.gdshader")
const BEAM := preload("res://shaders/theatre_beam.gdshader")
const FINISH := preload("res://shaders/theatre_finish.gdshader")
const FADER_TRAVEL := 0.194

@export var cat_scene: PackedScene
var props: Array[Node3D] = []
var base_positions: Array[Vector3] = []
var focus_tweens: Dictionary = {}
var curtains: Array[Node3D] = []
var sliders: Array[Node3D] = []
var fader_origins: Array[Vector3] = []
var gears: Array[Node3D] = []
var grips: Array[MeshInstance3D] = []
var grip_materials: Array[StandardMaterial3D] = []
var grip_tweens: Array[Tween] = []
var hot_fader := -1
var pressed_fader := -1
var cover: Node3D
var ticket: Node3D
var flat_ticket: Node3D
var mixer: Node3D
var _letter_font: SystemFont


func _ready() -> void:
	_letter_font = SystemFont.new()
	_letter_font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif", "serif"])
	_letter_font.font_weight = 700
	_room()
	_stage()
	_menu_props()


func _mesh(parent: Node3D, shape: Mesh, at: Vector3, material: Material = null) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.material_override = material
	item.position = at
	parent.add_child(item)
	return item


func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.65) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m


func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent, shape, at, material)


func _model(parent: Node3D, key: String, at: Vector3, size: Vector3, angles := Vector3.ZERO) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = key.to_pascal_case()
	parent.add_child(pivot)
	pivot.position = at
	pivot.scale = size
	pivot.rotation_degrees = angles
	var packed := load(MODELS + key + ".glb") as PackedScene
	pivot.add_child(packed.instantiate())
	return pivot


func _room() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#191522")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#ffead5")
	environment.ambient_light_energy = 0.37
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true
	environment.glow_intensity = 0.14
	environment.tonemap_exposure = 0.84
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var wall := _mat(Color("#161929"))
	var walnut := _mat(Color("#4e302c"))
	var gold := _mat(Color("#af8150"), 0.55, 0.34)
	_box(self, Vector3(0, 2.4, -5.5), Vector3(26, 10, 0.3), wall)
	for x in range(-10, 11, 2):
		_box(self, Vector3(x, 2.6, -5.22), Vector3(0.095, 7.0, 0.15), walnut)
		_box(self, Vector3(x + 0.75, 2.5, -5.25), Vector3(1.20, 2.7, 0.14), walnut)
		_box(self, Vector3(x + 0.75, 2.5, -5.13), Vector3(1.12, 2.60, 0.10), wall)
	var backdrop := _mat(Color("#bda9b1"))
	backdrop.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop.cull_mode = BaseMaterial3D.CULL_DISABLED
	backdrop.albedo_texture = preload("res://assets/models/theatre/backstage.jpg")
	for i in range(-3,4):
		var flat := QuadMesh.new()
		flat.size = Vector2(4.01,7.5)
		var scenery := _mesh(self,flat,Vector3(i*4.0,3.00,-4.98),backdrop)
		if posmod(i,2) == 1:
			scenery.scale.x = -1.0
	_box(self, Vector3(0, -0.22, 0.6), Vector3(19, 0.40, 10), walnut)
	var cloth := ShaderMaterial.new()
	cloth.shader = FINISH
	cloth.set_shader_parameter("fabric", true)
	cloth.set_shader_parameter("tint", Color("#51102e"))
	_box(self, Vector3(0, -0.029, 1.35), Vector3(9.72, 0.057, 8.1), cloth)
	for side in [-1, 1]:
		_box(self, Vector3(side * 4.78, 0.002, 1.35), Vector3(.024, .004, 8.1), gold)
		_model(self, "drape", Vector3(side * 7.12, 3.1, -3.2), Vector3(side * 6.5, 7.0, 3.1))
		var stand := _model(self, "small_brass", Vector3(side * 3.67, .63, -.75), Vector3.ONE * 1.30)
		var wax := CylinderMesh.new()
		wax.top_radius = .10
		wax.bottom_radius = .115
		wax.height = .48
		_mesh(stand, wax, Vector3(0, .64, 0), _mat(Color("#e6c59b")))
		var flame := SphereMesh.new()
		flame.radius = .050
		flame.height = .20
		var glow := _mat(Color("#fff0b9"))
		glow.emission_enabled = true
		glow.emission = Color("#ffaf51")
		glow.emission_energy_multiplier = 4.0
		_mesh(stand, flame, Vector3(.008, .947, 0), glow)
		_lamp(Vector3(side * 3.67, 1.98, -.62), Color("#ffae58"), 2.8, 4.0)
	_lamp(Vector3(0, 5.2, 3.3), Color("#ffdfaa"), 2.8, 9.0)
	_lamp(Vector3(-3.3, 3.7, 0.6), Color("#a5c6fc"), 2.0, 6.6)
	_lamp(Vector3(2.3, 3.4, -2.1), Color("#fff3c4"), 3.0, 6.2)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-49, -28, 0)
	sun.light_color = Color("#ffe7c8")
	sun.light_energy = 0.56
	sun.shadow_enabled = true
	var cone := CylinderMesh.new()
	cone.top_radius = .13
	cone.bottom_radius = 2.0
	cone.height = 6.0
	cone.cap_top = false
	cone.cap_bottom = false
	var beam := ShaderMaterial.new()
	beam.shader = BEAM
	var shaft := _mesh(self, cone, Vector3(0, 3.35, -.58), beam)
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dust()


func _lamp(at: Vector3, color: Color, energy: float, reach: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.position = at
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = reach
	add_child(lamp)


func _dust() -> void:
	var particles := GPUParticles3D.new()
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(2.45, 1.4, .85)
	process.gravity = Vector3(.006, .018, 0)
	process.scale_min = .42
	process.scale_max = 1.0
	process.turbulence_enabled = true
	process.turbulence_noise_strength = .11
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,.86,.51,.68), Color(1,.78,.4,0)])
	var sprite := GradientTexture2D.new()
	sprite.gradient = gradient
	sprite.fill = GradientTexture2D.FILL_RADIAL
	sprite.fill_from = Vector2(.5,.5)
	sprite.fill_to = Vector2(.98,.5)
	var m := _mat(Color.WHITE)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = sprite
	var q := QuadMesh.new()
	q.size = Vector2(.020,.020)
	q.material = m
	particles.amount = 52
	particles.lifetime = 9
	particles.preprocess = 9
	particles.process_material = process
	particles.draw_pass_1 = q
	particles.position = Vector3(0, 2.4, .4)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)


func _stage() -> void:
	var stage := _model(self, "playhouse", Vector3(0, 0, -.82), Vector3.ONE * 1.06)
	var timber := ShaderMaterial.new()
	timber.shader = FINISH
	timber.set_shader_parameter("tint", Color("#663820"))
	for part: Node in stage.find_children("*","MeshInstance3D",true,false):
		var surface := part as MeshInstance3D
		var original := surface.get_active_material(0)
		if original and "walnut" in original.resource_name.to_lower():
			surface.material_override = timber
	var cloth := ShaderMaterial.new()
	cloth.shader = VELVET
	for key in ["CurtainLeft", "CurtainRight"]:
		var panel := stage.find_child(key, true, false) as MeshInstance3D
		panel.material_override = cloth
		curtains.append(panel)
	for side in [-1, 1]:
		_model(stage, "drape", Vector3(side * 1.42, 2.12, .12), Vector3(side * 2.1, 2.59, 1.5))
	_letter(stage, "THE 22 ACTS OF THE", Vector3(0, 4.055, .343), Vector2(2.53, .245), Color("#ffda87"))
	_letter(stage, "BLACK CAT", Vector3(0, 3.72, .343), Vector2(2.96, .50), Color("#ffe5a2"))
	var anchor := Node3D.new()
	anchor.name = "CatAnchor"
	anchor.position = Vector3(1.70, .93, .96)
	stage.add_child(anchor)
	if cat_scene:
		anchor.add_child(cat_scene.instantiate())


func _menu_props() -> void:
	for i in 5:
		var root := Node3D.new()
		root.name = ["Gallery", "Start", "Continue", "Settings", "Quit"][i]
		add_child(root)
		props.append(root)
	var chest := _model(props[GALLERY], "card_box", Vector3.ZERO, Vector3.ONE * 2.02)
	props[GALLERY].position = Vector3(-3.85,.51,1.70)
	props[GALLERY].rotation_degrees.y = 13
	_hit(props[GALLERY], GALLERY, Vector3(0,.46,-.05), Vector3(2.03,1.78,1.56))
	var lid := chest.find_child("Lid",true,false) as Node3D
	lid.rotation_degrees.x = -76
	_letter(lid, "GALLERY", Vector3(0,-.012,.440), Vector2(.72,.146), Color("#e5c88f"), Vector3(90,0,0))
	for i in 3:
		var card := QuadMesh.new()
		card.size = Vector2(.295,.432)
		var m := _mat(Color.WHITE)
		m.albedo_texture = load(CardDatabase.texture_path([1,11,0][i]))
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var face := _mesh(chest, card, Vector3((i-1)*.210,.151,.109+.018*i), m)
		face.rotation_degrees = Vector3(-24, 0, 8.0-i*6.0)
	props[START].position = Vector3(-1.73,.43,2.76)
	ticket = _ticket(props[START], Vector3(0,.13,0), Vector3(-12,4,6))
	flat_ticket = _ticket(props[START], Vector3(-.09,-.32,.58), Vector3(-76,1,6))
	_hit(props[START], START, ticket.position, Vector3(1.98,.67,.11), ticket.rotation)
	_hit(props[START], START, flat_ticket.position, Vector3(1.98,.67,.11), flat_ticket.rotation)
	props[CONTINUE].position = Vector3(.94,.39,2.62)
	props[CONTINUE].rotation_degrees = Vector3(12,-9,0)
	var book := _model(props[CONTINUE], "libretto", Vector3.ZERO, Vector3(2.34,2.10,2.60))
	cover = book.find_child("Cover",true,false)
	var bookmark := _mat(Color("#8d7753") if TheatreSession.checkpoint.is_empty() else Color("#ffcd72"),.72,.26)
	if not TheatreSession.checkpoint.is_empty():
		bookmark.emission_enabled = true
		bookmark.emission = Color("#926529")
	for toe: Node in cover.find_children("Bookmark*","MeshInstance3D",true,false):
		(toe as MeshInstance3D).material_override = bookmark
	_letter(cover, "CONTINUE", Vector3(0,.064,.35), Vector2(.78,.195), Color("#ffdb8b"), Vector3(-90,0,0))
	_hit(props[CONTINUE], CONTINUE, Vector3.ZERO, Vector3(2.26,.61,2.00))
	props[SETTINGS].position = Vector3(3.01,.56,1.58)
	props[SETTINGS].rotation_degrees.y = -11
	mixer = _model(props[SETTINGS], "mixer", Vector3.ZERO, Vector3.ONE * 1.78)
	_hit(props[SETTINGS], SETTINGS, Vector3.ZERO, Vector3(1.70,1.13,.81))
	for i in 2:
		var fader := mixer.find_child("Fader%d" % i,true,false) as Node3D
		sliders.append(fader)
		fader_origins.append(fader.position)
		var grip := fader.get_node("Grip%d" % i) as MeshInstance3D
		var finish := grip.get_active_material(0).duplicate() as StandardMaterial3D
		finish.emission_enabled = true
		finish.emission = Color("#ffc56f")
		finish.emission_texture = finish.albedo_texture
		finish.emission_energy_multiplier = 0.0
		grip.material_override = finish
		grips.append(grip)
		grip_materials.append(finish)
		grip_tweens.append(null)
	for part in ["GearTop", "GearLower", "GearPinion"]:
		gears.append(mixer.find_child(part,true,false))
	update_mixer()
	props[QUIT].position = Vector3(4.40,.62,2.14)
	var bell := _model(props[QUIT], "desk_brass", Vector3.ZERO, Vector3.ONE * 1.29)
	_hit(props[QUIT], QUIT, Vector3.ZERO, Vector3(.95,1.32,.95))
	_letter(bell, "QUIT", Vector3(0,-.435,.47), Vector2(.53,.16), Color("#edcf8f"), Vector3(-34,0,0))
	for prop in props:
		base_positions.append(prop.position)
	var loose := QuadMesh.new()
	loose.size = Vector2(.66,.91)
	var illustrated := _mat(Color.WHITE)
	illustrated.albedo_texture = load(CardDatabase.texture_path(0))
	var card := _mesh(self,loose,Vector3(-.61,.025,3.24),illustrated)
	card.rotation_degrees = Vector3(-89,0,-13)


func _ticket(parent: Node3D, at: Vector3, angles: Vector3) -> Node3D:
	var stub := _model(parent, "ticket", at, Vector3(2.10,2.42,2.1), angles)
	_letter(stub, "START PLAY", Vector3(0,0,.008), Vector2(.71,.165), Color("#593819"))
	var q := QuadMesh.new()
	q.size = Vector2(.939,.273)
	var foil := ShaderMaterial.new()
	foil.shader = FOIL
	_mesh(stub,q,Vector3(0,0,.007),foil)
	return stub


func _hit(parent: Node3D, id: int, at: Vector3, size: Vector3, angles := Vector3.ZERO) -> void:
	var area := Area3D.new()
	area.position = at
	area.rotation = angles
	area.collision_layer = 2
	area.collision_mask = 0
	area.set_meta("menu_id", id)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	col.shape = box
	area.add_child(col)
	# The picking volume stays at rest while the model moves.
	add_child(area)
	area.global_transform = parent.global_transform * Transform3D(Basis.from_euler(angles), at)


func _letter(parent: Node3D, words: String, at: Vector3, size: Vector2, color: Color, angles := Vector3.ZERO) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(960, maxi(72,roundi(960.0*size.y/size.x)))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(vp)
	var label := Label.new()
	label.size = Vector2(vp.size)
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", _letter_font)
	var fit := minf(vp.size.y*.82, vp.size.x*100.0/_letter_font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,100).x*.96)
	label.add_theme_font_size_override("font_size",maxi(12,int(fit)))
	label.add_theme_color_override("font_color",color)
	vp.add_child(label)
	var m := _mat(Color.WHITE)
	m.albedo_texture = vp.get_texture()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var q := QuadMesh.new()
	q.size = size
	var sign_mesh := _mesh(parent,q,at,m)
	sign_mesh.rotation_degrees = angles
	sign_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func focus_prop(index: int, active: bool) -> void:
	var prop := props[index]
	if focus_tweens.has(index):
		(focus_tweens[index] as Tween).kill()
	var tween := create_tween().set_parallel(true)
	focus_tweens[index] = tween
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(prop,"position",base_positions[index]+Vector3.UP*(.073 if active else 0.0),.23)
	tween.tween_property(prop,"scale",Vector3.ONE*(1.038 if active else 1.0),.23)


func update_mixer() -> void:
	for i in sliders.size():
		var level := TheatreSession.levels[i]
		sliders[i].position = fader_origins[i] + sliders[i].basis.y * ((level - 0.5) * FADER_TRAVEL)
	# Zero rotation corresponds to the meshed teeth in the authored pose.
	var angle := (TheatreSession.levels[0] - 0.5) * 1.9 + (TheatreSession.levels[1] - 0.5) * 2.2
	gears[0].rotation.z = angle
	gears[1].rotation.z = -angle * 1.16
	gears[2].rotation.z = -angle * 2.0


func set_fader_feedback(hot: int, pressed: int) -> void:
	if hot == hot_fader and pressed == pressed_fader:
		return
	hot_fader = hot
	pressed_fader = pressed
	for i in grips.size():
		if grip_tweens[i] != null:
			grip_tweens[i].kill()
		var light := 0.0
		var depth := 0.0
		if i == pressed:
			light = 0.42
			depth = -0.010
		elif i == hot:
			light = 0.20
		var tween := create_tween().set_parallel(true)
		grip_tweens[i] = tween
		tween.tween_property(grip_materials[i], "emission_energy_multiplier", light, 0.10)
		tween.tween_property(grips[i], "position:z", depth, 0.09)

