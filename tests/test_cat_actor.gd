extends Node

const BlackCatActor := preload("res://scripts/black_cat_actor.gd")
const CAT_SCENE_PATH := "res://scenes/cat_placeholder.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const SPLASH_SCENE_PATH := "res://scenes/splash_screen.tscn"

const EXPECTED_CLIPS: Array[StringName] = [
	&"sit_idle",
	&"sit_look_around",
	&"sit_groom_paw",
	&"sit_catnap_nod",
	&"sit_chest_stretch",
	&"sit_to_stand",
	&"walk",
	&"stand_to_sit",
]
const IDLE_CLIPS: Array[StringName] = [
	&"sit_idle",
	&"sit_look_around",
	&"sit_groom_paw",
	&"sit_catnap_nod",
	&"sit_chest_stretch",
]
const IK_PAIRS: Array = [
	["leg3_R", "leg3_control_R"],
	["leg3_L", "leg3_control_L"],
	["paw2_R", "paw_control_R"],
	["paw2_L", "paw_control_L"],
]
const IK_TOLERANCE := 0.015

var passed: int = 0
var failed: int = 0
var _profile: String = ""
var _saved_agent_enabled: bool = false


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_saved_agent_enabled = AgentSettings.enabled
	AgentSettings.enabled = false
	_profile = "user://test_cat_actor_%d.dat" % OS.get_process_id()
	TheatreSession.profile_path = _profile
	TheatreSession.tracking = false
	TheatreSession.resume_requested = false
	TheatreSession.consume_enter_transition()
	TheatreSession.consume_return_transition()
	TheatreSession.read_profile()

	var tree := get_tree()
	await _test_scene_materials_and_clips(tree)
	await _test_ik_and_motion_invariants(tree)
	await _test_full_lifecycle_and_memory_release(tree)

	Audio.stop_music()
	TheatreSession.tracking = false
	TheatreSession.resume_requested = false
	TheatreSession.consume_enter_transition()
	TheatreSession.consume_return_transition()
	AgentSettings.enabled = _saved_agent_enabled
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_profile + suffix):
			DirAccess.remove_absolute(_profile + suffix)

	print("CatActor test results: %d passed, %d failed" % [passed, failed])
	tree.quit(1 if failed > 0 else 0)


func _test_scene_materials_and_clips(tree: SceneTree) -> void:
	var tscn_text := FileAccess.get_file_as_string(CAT_SCENE_PATH)
	check(not tscn_text.is_empty(), "cat_placeholder.tscn readable")
	check(not tscn_text.contains(".blend"), "cat_placeholder.tscn has zero .blend references")

	var packed := load(CAT_SCENE_PATH) as PackedScene
	check(packed != null, "cat_placeholder.tscn loads as PackedScene")
	if packed == null:
		return

	var cat := packed.instantiate() as BlackCatActor
	check(cat != null, "cat_placeholder.tscn root is BlackCatActor")
	if cat == null:
		return

	check(not cat.is_model_loaded(), "cat model is unloaded before entering scene tree")
	add_child(cat)
	await tree.process_frame

	check(cat.is_model_loaded(), "cat model loads on _ready when start_loaded is true")
	check_eq(cat.state, BlackCatActor.State.SITTING_IDLE, "cat starts in State.SITTING_IDLE")

	var skel := cat.get_skeleton()
	check(skel != null, "get_skeleton() returns valid Skeleton3D")
	if skel != null:
		check_eq(skel.get_bone_count(), 32, "Skeleton3D has exactly 32 bones")

		var fur_mesh := skel.find_child("sculpt_001", false, false) as MeshInstance3D
		check(fur_mesh != null, "sculpt_001 MeshInstance3D exists")
		if fur_mesh != null:
			check_eq(fur_mesh.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "sculpt_001 casts shadows")
			var fur_mat := fur_mesh.get_active_material(0) as ShaderMaterial
			check(fur_mat != null, "sculpt_001 uses a ShaderMaterial")
			if fur_mat != null:
				check(
					fur_mat.shader != null and fur_mat.shader.resource_path.ends_with("black_cat_fur.gdshader"),
					"sculpt_001 uses black_cat_fur.gdshader"
				)

		var eye_mesh := skel.find_child("Eye1", false, false) as MeshInstance3D
		check(eye_mesh != null, "Eye1 MeshInstance3D exists")
		if eye_mesh != null:
			var iris_mat := eye_mesh.get_active_material(0) as StandardMaterial3D
			check(iris_mat != null, "Eye1 surface 0 uses StandardMaterial3D")
			if iris_mat != null:
				var c := iris_mat.albedo_color
				check(c.r > 0.80 and c.g > 0.50 and c.b < 0.35, "Eye1 surface 0 has golden iris albedo")
				check(iris_mat.emission_enabled and iris_mat.emission.r > 0.50, "Eye1 surface 0 has warm golden emission")

	var ap := cat.get_animation_player()
	check(ap != null, "get_animation_player() returns valid AnimationPlayer")
	if ap != null:
		for clip_name in EXPECTED_CLIPS:
			check(ap.has_animation(clip_name), "AnimationPlayer has clip '%s'" % String(clip_name))

	var idle_names := cat.get_available_idle_animations()
	check_eq(idle_names.size(), IDLE_CLIPS.size(), "get_available_idle_animations() lists all 5 idle clips")
	for clip_name in IDLE_CLIPS:
		check(idle_names.has(String(clip_name)), "idle list includes '%s'" % String(clip_name))
	check(cat.play_idle_animation(&"sit_groom_paw", 0.1), "play_idle_animation('sit_groom_paw') succeeds")

	cat.release_model()
	check(not cat.is_model_loaded(), "release_model() unloads model")
	check_eq(cat.state, BlackCatActor.State.BACKSTAGE_RELEASED, "release_model() sets BACKSTAGE_RELEASED")
	cat.queue_free()
	await tree.process_frame


func _test_ik_and_motion_invariants(tree: SceneTree) -> void:
	var packed := load(CAT_SCENE_PATH) as PackedScene
	if packed == null:
		return
	var cat := packed.instantiate() as BlackCatActor
	if cat == null:
		return
	add_child(cat)
	await tree.process_frame

	var skel := cat.get_skeleton()
	var ap := cat.get_animation_player()
	if skel == null or ap == null:
		cat.queue_free()
		return

	# Pause actor _process so manual AnimationPlayer sampling isn't overwritten.
	cat.set_process(false)

	var pair_data: Array = []
	for pair in IK_PAIRS:
		var limb_name: String = pair[0]
		var ctrl_name: String = pair[1]
		var limb_idx := skel.find_bone(limb_name)
		var ctrl_idx := skel.find_bone(ctrl_name)
		check(limb_idx >= 0 and ctrl_idx >= 0, "bone pair %s -> %s exists" % [limb_name, ctrl_name])
		if limb_idx >= 0 and ctrl_idx >= 0:
			var rest_limb := skel.get_bone_global_rest(limb_idx)
			var rest_ctrl := skel.get_bone_global_rest(ctrl_idx)
			var tip_local := rest_limb.affine_inverse() * rest_ctrl.origin
			pair_data.append({
				"limb_name": limb_name,
				"ctrl_name": ctrl_name,
				"limb_idx": limb_idx,
				"ctrl_idx": ctrl_idx,
				"tip_local": tip_local,
			})

	var bone_count := skel.get_bone_count()
	var norm_times := [0.0, 0.25, 0.5, 0.75, 1.0]

	for clip_name in EXPECTED_CLIPS:
		if not ap.has_animation(clip_name):
			continue
		var anim := ap.get_animation(clip_name)
		var max_ik_dist := 0.0
		var worst_pair := ""
		var worst_u := 0.0

		var first_positions: Array[Vector3] = []
		var first_rotations: Array[Quaternion] = []
		var max_pos_delta := 0.0
		var max_rot_delta := 0.0

		for u_idx in norm_times.size():
			var u: float = norm_times[u_idx]
			var t := clampf(u * anim.length, 0.0, anim.length)
			ap.stop()
			ap.play(clip_name, 0.0)
			ap.seek(t, true)
			ap.advance(0.0)

			for item_var in pair_data:
				var item: Dictionary = item_var
				var limb_idx: int = item["limb_idx"]
				var ctrl_idx: int = item["ctrl_idx"]
				var tip_local: Vector3 = item["tip_local"]
				var tip_pos: Vector3 = skel.get_bone_global_pose(limb_idx) * tip_local
				var ctrl_pos: Vector3 = skel.get_bone_global_pose(ctrl_idx).origin
				var dist: float = tip_pos.distance_to(ctrl_pos)
				if dist > max_ik_dist:
					max_ik_dist = dist
					worst_pair = "%s->%s" % [str(item["limb_name"]), str(item["ctrl_name"])]
					worst_u = u

			if u_idx == 0:
				for b in bone_count:
					first_positions.append(skel.get_bone_pose_position(b))
					first_rotations.append(skel.get_bone_pose_rotation(b).normalized())
			else:
				for b in bone_count:
					var dp := skel.get_bone_pose_position(b).distance_to(first_positions[b])
					var dq := first_rotations[b].angle_to(skel.get_bone_pose_rotation(b).normalized())
					max_pos_delta = maxf(max_pos_delta, dp)
					max_rot_delta = maxf(max_rot_delta, dq)

		check(
			max_ik_dist < IK_TOLERANCE,
			"clip '%s' IK paw attachment < %.3fm (max %.5fm on %s at u=%.2f)" % [String(clip_name), IK_TOLERANCE, max_ik_dist, worst_pair, worst_u]
		)
		check(
			max_pos_delta > 0.002 or max_rot_delta > 0.015,
			"clip '%s' exhibits non-zero skeletal motion (pos_delta=%.5f, rot_delta=%.4f)" % [String(clip_name), max_pos_delta, max_rot_delta]
		)

	cat.release_model()
	cat.queue_free()
	await tree.process_frame


func _test_full_lifecycle_and_memory_release(tree: SceneTree) -> void:
	# 1. Boot splash_screen -> theatre_menu
	var splash := (load(SPLASH_SCENE_PATH) as PackedScene).instantiate()
	tree.root.add_child(splash)
	tree.current_scene = splash
	splash._finish_immediately()
	await tree.scene_changed

	var menu := tree.current_scene
	check(menu != null and menu.scene_file_path.ends_with("theatre_menu.tscn"), "splash transitions to theatre_menu.tscn")
	if menu == null:
		return

	check(TablePreloader.finished and is_instance_valid(TablePreloader._table), "TablePreloader warms up main table")
	if is_instance_valid(TablePreloader._table):
		var warmed_cat: BlackCatActor = TablePreloader._table.theatre_set.cat_actor
		check(warmed_cat != null, "warmed table has TheatreSet.cat_actor")
		if warmed_cat != null:
			check(not warmed_cat.is_model_loaded(), "warmed table cat has 0 MB unloaded model")

	var menu_cat: BlackCatActor = menu.stage.cat_actor
	check(menu_cat != null, "theatre_menu stage has cat_actor")
	if menu_cat == null:
		return
	check(menu_cat.is_model_loaded(), "menu cat_actor is loaded on theatre_menu")
	check_eq(menu_cat.state, BlackCatActor.State.SITTING_IDLE, "menu cat_actor starts in SITTING_IDLE")

	await tree.physics_frame
	await tree.physics_frame

	# 2. Activate TheatreSet.START -> backstage exit transfer -> gameplay intro -> release
	TheatreSession.checkpoint.clear()
	menu._activate(TheatreSet.START)
	check_eq(menu_cat.state, BlackCatActor.State.EXITING_BACKSTAGE, "START transitions menu cat to EXITING_BACKSTAGE")

	await tree.scene_changed
	var main := tree.current_scene
	check(main != null and main.scene_file_path.ends_with("main.tscn"), "START transitions to main.tscn")
	if main == null:
		return

	check(is_instance_valid(TablePreloader._menu), "TablePreloader caches menu after START")
	if is_instance_valid(TablePreloader._menu):
		var cached_cat: BlackCatActor = TablePreloader._menu.stage.cat_actor
		check(cached_cat != null and not cached_cat.is_model_loaded(), "cached menu cat_actor is unloaded after transfer")

	var main_cat: BlackCatActor = main.theatre_set.cat_actor
	check(main_cat != null, "main TheatreSet has cat_actor")
	if main_cat != null:
		check(
			main_cat.state == BlackCatActor.State.EXITING_BACKSTAGE and main_cat.is_model_loaded(),
			"main cat_actor continues EXITING_BACKSTAGE across scene handoff"
		)

	var exit_done := await _wait_until(tree, func() -> bool:
		return (
			not main.is_intro_active()
			and main_cat != null
			and main_cat.state == BlackCatActor.State.BACKSTAGE_RELEASED
		)
	, 3.5)
	check(exit_done, "cat finishes backstage exit and intro completes within 3.5s")
	if main_cat != null:
		check(not main_cat.is_model_loaded(), "main cat_actor releases model after backstage exit")
		check_eq(main_cat.state, BlackCatActor.State.BACKSTAGE_RELEASED, "main cat_actor reaches BACKSTAGE_RELEASED")
	if is_instance_valid(TablePreloader._menu):
		check(not TablePreloader._menu.stage.cat_actor.is_model_loaded(), "cached menu cat remains unloaded during gameplay")

	# 3. Trigger ESC return to menu -> reload & walk from backstage -> settle to SITTING_IDLE
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	main._unhandled_key_input(esc)
	await tree.scene_changed

	menu = tree.current_scene
	check(menu != null and menu.scene_file_path.ends_with("theatre_menu.tscn"), "ESC returns to theatre_menu.tscn")
	if menu == null:
		return
	menu_cat = menu.stage.cat_actor
	check(menu_cat != null and menu_cat.is_model_loaded(), "ESC return reloads menu cat model")
	check_eq(menu_cat.state, BlackCatActor.State.ENTERING_FROM_BACKSTAGE, "ESC return enters ENTERING_FROM_BACKSTAGE")

	var returned_done := await _wait_until(tree, func() -> bool:
		return menu_cat.state == BlackCatActor.State.SITTING_IDLE
	, 3.0)
	check(returned_done, "cat settles back into SITTING_IDLE after ESC return")
	check(menu_cat.is_model_loaded(), "settled menu cat keeps model loaded")

	# Wait for TablePreloader.prepare() after return so we test mid-summon & mid-intro cleanly.
	var preloaded := await _wait_until(tree, func() -> bool:
		return TablePreloader.finished
	, 2.5)
	check(preloaded, "TablePreloader finishes preparing table after return")
	if is_instance_valid(TablePreloader._table):
		check(not TablePreloader._table.theatre_set.cat_actor.is_model_loaded(), "re-warmed table cat remains unloaded")

	# 4a. Rapid interruption: ESC mid-intro releases main cat cleanly and starts summon on menu
	TheatreSession.checkpoint.clear()
	menu._activate(TheatreSet.START)
	await tree.scene_changed
	main = tree.current_scene
	check(main != null and main.scene_file_path.ends_with("main.tscn"), "second START transitions to main.tscn")
	if main == null:
		return
	main_cat = main.theatre_set.cat_actor
	var released_events := [0]
	if main_cat != null:
		main_cat.model_released.connect(func() -> void: released_events[0] += 1)

	await tree.create_timer(0.15).timeout
	check(main.is_intro_active(), "intro still active 0.15s in before rapid ESC")
	main._unhandled_key_input(esc)
	await tree.scene_changed
	check(released_events[0] >= 1, "rapid ESC mid-intro triggers model_released on main cat")

	menu = tree.current_scene
	check(menu != null and menu.scene_file_path.ends_with("theatre_menu.tscn"), "rapid ESC returns to theatre_menu.tscn")
	if menu != null:
		menu_cat = menu.stage.cat_actor
		check(menu_cat.is_model_loaded(), "cat model loaded during rapid ESC return")
		check_eq(menu_cat.state, BlackCatActor.State.ENTERING_FROM_BACKSTAGE, "cat begins ENTERING_FROM_BACKSTAGE on rapid return")

		# 4b. Rapid interruption: START mid-summon cleanly reverses to EXITING_BACKSTAGE and releases after intro
		await tree.create_timer(0.22).timeout
		check_eq(menu_cat.state, BlackCatActor.State.ENTERING_FROM_BACKSTAGE, "cat is still mid-summon before rapid START")
		TheatreSession.checkpoint.clear()
		menu._activate(TheatreSet.START)
		check_eq(menu_cat.state, BlackCatActor.State.EXITING_BACKSTAGE, "rapid START mid-summon flips cat to EXITING_BACKSTAGE")

		await tree.scene_changed
		var rapid_main := tree.current_scene
		check(rapid_main != null and rapid_main.scene_file_path.ends_with("main.tscn"), "rapid START enters main.tscn")
		if rapid_main != null:
			if is_instance_valid(TablePreloader._menu):
				check(not TablePreloader._menu.stage.cat_actor.is_model_loaded(), "cached menu cat unloaded after rapid START transfer")
			var rapid_main_cat: BlackCatActor = rapid_main.theatre_set.cat_actor
			var rapid_done := await _wait_until(tree, func() -> bool:
				return (
					not rapid_main.is_intro_active()
					and rapid_main_cat != null
					and rapid_main_cat.state == BlackCatActor.State.BACKSTAGE_RELEASED
				)
			, 3.5)
			check(rapid_done, "rapid START cat completes backstage exit cleanly")
			if rapid_main_cat != null:
				check(not rapid_main_cat.is_model_loaded(), "rapid START cat model released after intro")

	# 5. Direct main.tscn launch: cat_actor must stay unloaded (0 MB)
	TheatreSession.tracking = false
	TheatreSession.resume_requested = false
	TheatreSession.consume_enter_transition()
	TheatreSession.consume_return_transition()
	tree.change_scene_to_file(MAIN_SCENE_PATH)
	await tree.scene_changed
	await tree.process_frame

	var direct_main := tree.current_scene
	check(direct_main != null and direct_main.scene_file_path.ends_with("main.tscn"), "direct main.tscn launch succeeds")
	if direct_main != null:
		var direct_cat: BlackCatActor = direct_main.theatre_set.cat_actor
		check(direct_cat != null, "direct main.tscn has TheatreSet.cat_actor")
		if direct_cat != null:
			check(not direct_cat.is_model_loaded(), "direct main.tscn launch leaves cat model unloaded")


func _wait_until(tree: SceneTree, predicate: Callable, timeout_sec: float) -> bool:
	var elapsed := 0.0
	var step := 0.05
	while elapsed < timeout_sec:
		if predicate.call():
			return true
		await tree.create_timer(step).timeout
		elapsed += step
	return bool(predicate.call())


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL " + label)


func check_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual == expected:
		passed += 1
		return
	failed += 1
	push_error("FAIL %s: expected %s, got %s" % [label, str(expected), str(actual)])
