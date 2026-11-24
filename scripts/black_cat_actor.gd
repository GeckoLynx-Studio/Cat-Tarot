class_name BlackCatActor
extends Node3D

enum State {
	UNLOADED,
	SITTING_IDLE,
	EXITING_BACKSTAGE,
	BACKSTAGE_RELEASED,
	ENTERING_FROM_BACKSTAGE,
}

enum _ChoreoPhase {
	NONE,
	EXIT_STAND,
	EXIT_WALK,
	ENTER_WALK,
	ENTER_TURN_SIT,
}

signal backstage_reached
signal holder_reached
signal model_released

const CAT_MODEL_PATH := "res://assets/models/cat/domestic_cat_rigged.gltf"
const FUR_SHADER := preload("res://shaders/black_cat_fur.gdshader")
const CatAnimationBuilder := preload("res://scripts/cat_animation_builder.gd")

const MODEL_SCALE := Vector3.ONE * 2.55
const HOLDER_POS := Vector3(0.02, -0.028, -0.02)
const HOLDER_YAW_DEG := -24.0
const TURN_RATE := 16.0
const EXIT_STAND_DURATION := 0.36
const EXIT_WALK_DURATION := 0.88
const ENTER_WALK_DURATION := 0.82
const ENTER_TURN_DURATION := 0.18
const ENTER_SIT_DURATION := 0.45

const EXIT_WAYPOINTS: Array[Vector3] = [
	Vector3(0.02, -0.028, -0.02),
	Vector3(-0.10, -0.012, -0.20),
	Vector3(-0.56, -0.008, -0.42),
	Vector3(-0.94, -0.008, -0.68),
	Vector3(-0.96, -0.008, -0.92),
	Vector3(-0.90, -0.008, -1.24),
	Vector3(0.34, -0.008, -1.30),
	Vector3(0.48, -0.008, -1.46),
]

@export var start_loaded: bool = true

var state: State = State.UNLOADED

var _rng := RandomNumberGenerator.new()
var _rig_pivot: Node3D
var _model_root: Node3D
var _skeleton: Skeleton3D
var _anim_player: AnimationPlayer
var _anim_library: AnimationLibrary
var _materials: Array[Material] = []

var _choreo_phase: _ChoreoPhase = _ChoreoPhase.NONE
var _choreo_elapsed: float = 0.0
var _choreo_duration: float = 0.0
var _turn_duration: float = ENTER_TURN_DURATION
var _turn_start_yaw: float = 0.0
var _path_points: PackedVector3Array = PackedVector3Array()
var _path_distances: PackedFloat32Array = PackedFloat32Array()
var _path_total_len: float = 0.0

var _idle_active_variation: StringName = &""
var _variation_remaining: float = 0.0
var _next_variation_timer: float = 0.0
var _last_variation_idx: int = -1

var _pending_resume_anim: StringName = &""
var _pending_resume_pos: float = 0.0
var _pending_resume_speed: float = 1.0


func _init() -> void:
	_rng.randomize()


func _ready() -> void:
	if is_model_loaded():
		return
	if start_loaded:
		if ensure_model_loaded():
			snap_to_holder_sitting()
	else:
		set_process(false)


func _enter_tree() -> void:
	if _pending_resume_anim != &"" and is_model_loaded():
		_anim_player.speed_scale = _pending_resume_speed
		_anim_player.play(_pending_resume_anim, 0.0)
		_anim_player.seek(_pending_resume_pos, true)
		_pending_resume_anim = &""


func _exit_tree() -> void:
	# Keep loaded rig intact if transfer_model_to() is moving it off-tree,
	# otherwise nothing extra needed; Godot frees children when node is freed.
	pass


func is_model_loaded() -> bool:
	return (
		_rig_pivot != null
		and is_instance_valid(_rig_pivot)
		and _model_root != null
		and is_instance_valid(_model_root)
		and _skeleton != null
		and is_instance_valid(_skeleton)
		and _anim_player != null
		and is_instance_valid(_anim_player)
	)


func ensure_model_loaded() -> bool:
	if is_model_loaded():
		return true

	var packed: PackedScene = TablePreloader.get_cat_packed_scene()
	if packed == null:
		push_error("BlackCatActor: failed to load model from %s" % CAT_MODEL_PATH)
		return false

	var model := packed.instantiate() as Node3D
	packed = null
	if model == null:
		push_error("BlackCatActor: instantiated cat model is not a Node3D")
		return false

	var skel := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel == null:
		model.free()
		push_error("BlackCatActor: Skeleton3D missing in %s" % CAT_MODEL_PATH)
		return false

	_rig_pivot = Node3D.new()
	_rig_pivot.name = "RigPivot"
	_rig_pivot.scale = MODEL_SCALE
	add_child(_rig_pivot)

	_model_root = model
	_rig_pivot.add_child(_model_root)
	_skeleton = skel

	_setup_materials()

	_anim_player = AnimationPlayer.new()
	_anim_player.name = "CatAnimationPlayer"
	_rig_pivot.add_child(_anim_player)
	_anim_player.root_node = _anim_player.get_path_to(_skeleton.get_parent())

	_anim_library = TablePreloader.get_cat_animation_library(_skeleton)
	_anim_player.add_animation_library(&"", _anim_library)
	return true


func release_model() -> void:
	_choreo_phase = _ChoreoPhase.NONE
	_choreo_elapsed = 0.0
	_choreo_duration = 0.0
	_idle_active_variation = &""
	_variation_remaining = 0.0
	_next_variation_timer = 0.0
	_pending_resume_anim = &""
	_path_points = PackedVector3Array()
	_path_distances = PackedFloat32Array()
	_path_total_len = 0.0
	set_process(false)

	var had_model := is_model_loaded() or (_rig_pivot != null and is_instance_valid(_rig_pivot))
	if _anim_player != null and is_instance_valid(_anim_player):
		_anim_player.stop()
		if _anim_player.has_animation_library(&""):
			_anim_player.remove_animation_library(&"")

	var old_pivot := _rig_pivot
	var old_model := _model_root
	var old_ap := _anim_player

	_rig_pivot = null
	_model_root = null
	_skeleton = null
	_anim_player = null
	_anim_library = null
	_materials.clear()

	if old_pivot != null and is_instance_valid(old_pivot):
		if old_pivot.get_parent() == self:
			remove_child(old_pivot)
		old_pivot.free()
	else:
		if old_ap != null and is_instance_valid(old_ap):
			old_ap.free()
		if old_model != null and is_instance_valid(old_model):
			old_model.free()

	state = State.BACKSTAGE_RELEASED
	if had_model:
		model_released.emit()


func snap_to_holder_sitting() -> void:
	if not ensure_model_loaded():
		return
	_choreo_phase = _ChoreoPhase.NONE
	_choreo_elapsed = 0.0
	_choreo_duration = 0.0
	_rig_pivot.position = HOLDER_POS
	_rig_pivot.rotation = Vector3(0.0, deg_to_rad(HOLDER_YAW_DEG), 0.0)
	_rig_pivot.scale = MODEL_SCALE
	_anim_player.speed_scale = 1.0
	_anim_player.play(&"sit_idle", 0.0)
	if is_inside_tree():
		_anim_player.seek(0.0, true)
	state = State.SITTING_IDLE
	_idle_active_variation = &""
	_variation_remaining = 0.0
	_schedule_next_idle_variation()
	set_process(true)


func retire_to_backstage(animate: bool = true) -> void:
	if not animate:
		_choreo_phase = _ChoreoPhase.NONE
		if is_model_loaded():
			release_model()
		else:
			state = State.BACKSTAGE_RELEASED
			set_process(false)
		backstage_reached.emit()
		return

	if not is_model_loaded():
		_choreo_phase = _ChoreoPhase.NONE
		state = State.BACKSTAGE_RELEASED
		set_process(false)
		backstage_reached.emit()
		return

	if state == State.EXITING_BACKSTAGE:
		return

	_idle_active_variation = &""
	_variation_remaining = 0.0

	if state == State.ENTERING_FROM_BACKSTAGE:
		# Reverse cleanly from current position out toward backstage wing.
		_set_path(_build_exit_path_from(_rig_pivot.position))
		state = State.EXITING_BACKSTAGE
		_choreo_phase = _ChoreoPhase.EXIT_WALK
		_choreo_elapsed = 0.0
		_choreo_duration = clampf(_path_total_len / 2.4, 0.25, EXIT_WALK_DURATION)
		_anim_player.speed_scale = 1.70
		_anim_player.play(&"walk", 0.12)
		set_process(true)
		return

	_set_path(PackedVector3Array(EXIT_WAYPOINTS))
	_rig_pivot.position = HOLDER_POS
	_rig_pivot.rotation = Vector3(0.0, deg_to_rad(HOLDER_YAW_DEG), 0.0)
	state = State.EXITING_BACKSTAGE
	_choreo_phase = _ChoreoPhase.EXIT_STAND
	_choreo_elapsed = 0.0
	_choreo_duration = EXIT_STAND_DURATION
	_anim_player.speed_scale = 1.0
	_anim_player.play(&"sit_to_stand", 0.08)
	set_process(true)


func summon_from_backstage(animate: bool = true) -> void:
	if not ensure_model_loaded():
		return

	if not animate:
		snap_to_holder_sitting()
		holder_reached.emit()
		return

	if state == State.SITTING_IDLE:
		holder_reached.emit()
		return

	if state == State.ENTERING_FROM_BACKSTAGE:
		return

	_idle_active_variation = &""
	_variation_remaining = 0.0

	if state == State.EXITING_BACKSTAGE:
		var was_standing := _choreo_phase == _ChoreoPhase.EXIT_STAND
		if was_standing and _choreo_elapsed < 0.18:
			# Still on the holder standing up: sit smoothly back down without walking.
			state = State.ENTERING_FROM_BACKSTAGE
			_choreo_phase = _ChoreoPhase.ENTER_TURN_SIT
			_choreo_elapsed = 0.0
			_choreo_duration = 0.28
			_turn_duration = 0.14
			_turn_start_yaw = _rig_pivot.rotation.y
			_anim_player.speed_scale = 1.0
			_anim_player.play(&"stand_to_sit", 0.12)
			set_process(true)
			return
		_set_path(_build_enter_path_from(_rig_pivot.position))
		state = State.ENTERING_FROM_BACKSTAGE
		_choreo_phase = _ChoreoPhase.ENTER_WALK
		_choreo_elapsed = 0.0
		_choreo_duration = clampf(_path_total_len / 2.5, 0.25, ENTER_WALK_DURATION)
		_anim_player.speed_scale = 1.70
		_anim_player.play(&"walk", 0.12)
		set_process(true)
		return

	var enter_pts := PackedVector3Array()
	for i in range(EXIT_WAYPOINTS.size() - 1, -1, -1):
		enter_pts.append(EXIT_WAYPOINTS[i])
	_set_path(enter_pts)

	_rig_pivot.position = _path_points[0]
	var initial_dir := (_path_points[1] - _path_points[0])
	initial_dir.y = 0.0
	if initial_dir.length_squared() > 1e-6:
		_rig_pivot.rotation = Vector3(0.0, atan2(initial_dir.x, initial_dir.z), 0.0)
	_rig_pivot.scale = MODEL_SCALE

	state = State.ENTERING_FROM_BACKSTAGE
	_choreo_phase = _ChoreoPhase.ENTER_WALK
	_choreo_elapsed = 0.0
	_choreo_duration = ENTER_WALK_DURATION
	_anim_player.speed_scale = 1.70
	_anim_player.play(&"walk", 0.0)
	if is_inside_tree():
		_anim_player.seek(0.0, true)
	set_process(true)


func transfer_model_to(target: BlackCatActor) -> bool:
	if target == null or target == self or not is_model_loaded():
		return false

	if target.is_model_loaded():
		target.release_model()

	var saved_anim := StringName(_anim_player.current_animation)
	var saved_pos := _anim_player.current_animation_position
	var saved_speed := _anim_player.speed_scale
	var was_playing := _anim_player.is_playing()

	var pivot := _rig_pivot
	pivot.reparent(target, false)

	target._rig_pivot = pivot
	target._model_root = _model_root
	target._skeleton = _skeleton
	target._anim_player = _anim_player
	target._anim_library = _anim_library
	target._materials = _materials.duplicate()

	target.state = state
	target._choreo_phase = _choreo_phase
	target._choreo_elapsed = _choreo_elapsed
	target._choreo_duration = _choreo_duration
	target._turn_duration = _turn_duration
	target._turn_start_yaw = _turn_start_yaw
	target._path_points = _path_points.duplicate()
	target._path_distances = _path_distances.duplicate()
	target._path_total_len = _path_total_len
	target._idle_active_variation = _idle_active_variation
	target._variation_remaining = _variation_remaining
	target._next_variation_timer = _next_variation_timer
	target._last_variation_idx = _last_variation_idx

	if was_playing and saved_anim != &"":
		if target.is_inside_tree():
			if not target._anim_player.is_playing():
				target._anim_player.speed_scale = saved_speed
				target._anim_player.play(saved_anim, 0.0)
				target._anim_player.seek(saved_pos, true)
		else:
			target._pending_resume_anim = saved_anim
			target._pending_resume_pos = saved_pos
			target._pending_resume_speed = saved_speed

	var should_tick := (
		target.state == State.SITTING_IDLE
		or target.state == State.EXITING_BACKSTAGE
		or target.state == State.ENTERING_FROM_BACKSTAGE
	)
	target.set_process(should_tick)

	_rig_pivot = null
	_model_root = null
	_skeleton = null
	_anim_player = null
	_anim_library = null
	_materials.clear()
	_choreo_phase = _ChoreoPhase.NONE
	_choreo_elapsed = 0.0
	_choreo_duration = 0.0
	_idle_active_variation = &""
	_variation_remaining = 0.0
	_next_variation_timer = 0.0
	_pending_resume_anim = &""
	_path_points = PackedVector3Array()
	_path_distances = PackedFloat32Array()
	_path_total_len = 0.0
	state = State.UNLOADED
	set_process(false)
	return true


func get_available_idle_animations() -> PackedStringArray:
	var out := PackedStringArray()
	for anim_name in CatAnimationBuilder.IDLE_CLIPS:
		out.append(String(anim_name))
	return out


func play_idle_animation(anim_name: StringName, blend: float = 0.30) -> bool:
	if not is_model_loaded():
		return false
	if not _anim_player.has_animation(anim_name):
		return false
	if not CatAnimationBuilder.IDLE_CLIPS.has(anim_name):
		return false

	_anim_player.speed_scale = 1.0
	_anim_player.play(anim_name, blend)
	if anim_name == &"sit_idle":
		_idle_active_variation = &""
		_variation_remaining = 0.0
		_schedule_next_idle_variation()
	else:
		var anim := _anim_player.get_animation(anim_name)
		_idle_active_variation = anim_name
		_variation_remaining = anim.length if anim != null else 3.5
	return true


func get_animation_player() -> AnimationPlayer:
	return _anim_player if is_instance_valid(_anim_player) else null


func get_skeleton() -> Skeleton3D:
	return _skeleton if is_instance_valid(_skeleton) else null


func _process(delta: float) -> void:
	if not is_model_loaded():
		set_process(false)
		return

	match state:
		State.SITTING_IDLE:
			_tick_idle(delta)
		State.EXITING_BACKSTAGE:
			_tick_exit(delta)
		State.ENTERING_FROM_BACKSTAGE:
			_tick_enter(delta)
		_:
			set_process(false)


func _tick_idle(delta: float) -> void:
	if _idle_active_variation != &"":
		_variation_remaining -= delta
		if _variation_remaining <= 0.25:
			_idle_active_variation = &""
			_variation_remaining = 0.0
			_anim_player.speed_scale = 1.0
			_anim_player.play(&"sit_idle", 0.35)
			_schedule_next_idle_variation()
		return

	_next_variation_timer -= delta
	if _next_variation_timer <= 0.0:
		var choices: Array[StringName] = []
		for i in range(1, CatAnimationBuilder.IDLE_CLIPS.size()):
			choices.append(CatAnimationBuilder.IDLE_CLIPS[i])
		var pick := _rng.randi_range(0, choices.size() - 1)
		if pick == _last_variation_idx and choices.size() > 1:
			pick = (pick + 1 + _rng.randi_range(0, choices.size() - 2)) % choices.size()
		_last_variation_idx = pick
		play_idle_animation(choices[pick], 0.32)


func _tick_exit(delta: float) -> void:
	_choreo_elapsed += delta
	match _choreo_phase:
		_ChoreoPhase.EXIT_STAND:
			if _choreo_elapsed > _choreo_duration * 0.45 and _path_points.size() >= 2:
				var first_dir := _path_points[1] - _path_points[0]
				first_dir.y = 0.0
				if first_dir.length_squared() > 1e-6:
					var target_yaw := atan2(first_dir.x, first_dir.z)
					_rig_pivot.rotation.y = lerp_angle(
						_rig_pivot.rotation.y,
						target_yaw,
						1.0 - exp(-delta * 9.0)
					)
			if _choreo_elapsed >= _choreo_duration:
				_choreo_phase = _ChoreoPhase.EXIT_WALK
				_choreo_elapsed = _choreo_elapsed - _choreo_duration
				_choreo_duration = EXIT_WALK_DURATION
				_anim_player.speed_scale = 1.70
				_anim_player.play(&"walk", 0.10)
		_ChoreoPhase.EXIT_WALK:
			var u := clampf(_choreo_elapsed / maxf(_choreo_duration, 1e-4), 0.0, 1.0)
			_advance_along_path(u, delta)
			if u >= 1.0:
				release_model()
				backstage_reached.emit()


func _tick_enter(delta: float) -> void:
	_choreo_elapsed += delta
	match _choreo_phase:
		_ChoreoPhase.ENTER_WALK:
			var u := clampf(_choreo_elapsed / maxf(_choreo_duration, 1e-4), 0.0, 1.0)
			_advance_along_path(u, delta)
			if u >= 1.0:
				_rig_pivot.position = HOLDER_POS
				_choreo_phase = _ChoreoPhase.ENTER_TURN_SIT
				_choreo_elapsed = 0.0
				_choreo_duration = ENTER_SIT_DURATION
				_turn_duration = ENTER_TURN_DURATION
				_turn_start_yaw = _rig_pivot.rotation.y
				_anim_player.speed_scale = 1.0
				_anim_player.play(&"stand_to_sit", 0.10)
		_ChoreoPhase.ENTER_TURN_SIT:
			var turn_u := clampf(_choreo_elapsed / maxf(_turn_duration, 1e-4), 0.0, 1.0)
			var smooth_turn := turn_u * turn_u * (3.0 - 2.0 * turn_u)
			_rig_pivot.rotation.y = lerp_angle(_turn_start_yaw, deg_to_rad(HOLDER_YAW_DEG), smooth_turn)
			if _choreo_elapsed >= _choreo_duration:
				_rig_pivot.position = HOLDER_POS
				_rig_pivot.rotation = Vector3(0.0, deg_to_rad(HOLDER_YAW_DEG), 0.0)
				_choreo_phase = _ChoreoPhase.NONE
				state = State.SITTING_IDLE
				_anim_player.speed_scale = 1.0
				_anim_player.play(&"sit_idle", 0.25)
				_schedule_next_idle_variation()
				holder_reached.emit()


func _advance_along_path(u: float, delta: float) -> void:
	if _path_points.size() < 2:
		return
	var sample := _sample_path(u * _path_total_len)
	_rig_pivot.position = sample["pos"]
	var dir: Vector3 = sample["dir"]
	dir.y = 0.0
	if dir.length_squared() > 1e-6:
		var target_yaw := atan2(dir.x, dir.z)
		_rig_pivot.rotation.y = lerp_angle(
			_rig_pivot.rotation.y,
			target_yaw,
			1.0 - exp(-delta * TURN_RATE)
		)


func _set_path(points: PackedVector3Array) -> void:
	_path_points = points
	_path_distances = PackedFloat32Array([0.0])
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
		_path_distances.append(total)
	_path_total_len = maxf(total, 1e-5)


func _sample_path(dist: float) -> Dictionary:
	var target_d := clampf(dist, 0.0, _path_total_len)
	for i in range(1, _path_points.size()):
		var d0 := _path_distances[i - 1]
		var d1 := _path_distances[i]
		if target_d <= d1 or i == _path_points.size() - 1:
			var seg_len := maxf(d1 - d0, 1e-5)
			var t := clampf((target_d - d0) / seg_len, 0.0, 1.0)
			var pos := _path_points[i - 1].lerp(_path_points[i], t)
			var dir := (_path_points[i] - _path_points[i - 1]).normalized()
			return {"pos": pos, "dir": dir}
	return {"pos": _path_points[0], "dir": Vector3.FORWARD}


func _build_exit_path_from(cur_pos: Vector3) -> PackedVector3Array:
	var seg := _closest_waypoint_segment(cur_pos)
	var pts := PackedVector3Array([cur_pos])
	for i in range(seg + 1, EXIT_WAYPOINTS.size()):
		if cur_pos.distance_to(EXIT_WAYPOINTS[i]) > 0.02 or i == EXIT_WAYPOINTS.size() - 1:
			pts.append(EXIT_WAYPOINTS[i])
	if pts.size() < 2:
		pts.append(EXIT_WAYPOINTS[EXIT_WAYPOINTS.size() - 1])
	return pts


func _build_enter_path_from(cur_pos: Vector3) -> PackedVector3Array:
	var seg := _closest_waypoint_segment(cur_pos)
	var pts := PackedVector3Array([cur_pos])
	for i in range(seg, -1, -1):
		if cur_pos.distance_to(EXIT_WAYPOINTS[i]) > 0.02 or i == 0:
			pts.append(EXIT_WAYPOINTS[i])
	if pts.size() < 2:
		pts.append(EXIT_WAYPOINTS[0])
	return pts


func _closest_waypoint_segment(pos: Vector3) -> int:
	var best_seg := 0
	var best_dist_sq := INF
	for i in range(EXIT_WAYPOINTS.size() - 1):
		var a := EXIT_WAYPOINTS[i]
		var b := EXIT_WAYPOINTS[i + 1]
		var ab := b - a
		var ab_len_sq := ab.length_squared()
		var t := clampf((pos - a).dot(ab) / maxf(ab_len_sq, 1e-6), 0.0, 1.0)
		var closest := a + ab * t
		var d_sq := pos.distance_squared_to(closest)
		if d_sq < best_dist_sq:
			best_dist_sq = d_sq
			best_seg = i
	return best_seg


func _schedule_next_idle_variation() -> void:
	_next_variation_timer = _rng.randf_range(3.0, 5.8)


func _setup_materials() -> void:
	_materials.clear()
	var fur_mesh := _skeleton.find_child("sculpt_001", false, false) as MeshInstance3D
	if fur_mesh != null:
		fur_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var orig_fur := fur_mesh.get_active_material(0)
		var fur_tex: Texture2D = null
		if orig_fur is BaseMaterial3D:
			fur_tex = (orig_fur as BaseMaterial3D).albedo_texture
		var fur_mat := ShaderMaterial.new()
		fur_mat.shader = FUR_SHADER
		if fur_tex != null:
			fur_mat.set_shader_parameter("fur_texture", fur_tex)
		fur_mesh.set_surface_override_material(0, fur_mat)
		_materials.append(fur_mat)

	var eye_mesh := _skeleton.find_child("Eye1", false, false) as MeshInstance3D
	if eye_mesh != null:
		var orig_iris := eye_mesh.get_active_material(0)
		if orig_iris is StandardMaterial3D:
			var iris_mat := orig_iris.duplicate() as StandardMaterial3D
			var iris_tex := iris_mat.albedo_texture
			iris_mat.albedo_color = Color(1.0, 0.72, 0.18, 1.0)
			iris_mat.roughness = 0.28
			iris_mat.emission_enabled = true
			iris_mat.emission = Color(0.85, 0.52, 0.08, 1.0)
			iris_mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			if iris_tex != null:
				iris_mat.emission_texture = iris_tex
			iris_mat.emission_energy_multiplier = 0.90
			eye_mesh.set_surface_override_material(0, iris_mat)
			_materials.append(iris_mat)

		var orig_cornea := eye_mesh.get_active_material(1)
		if orig_cornea is StandardMaterial3D:
			var cornea_mat := orig_cornea.duplicate() as StandardMaterial3D
			cornea_mat.roughness = 0.03
			cornea_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.16)
			eye_mesh.set_surface_override_material(1, cornea_mat)
			_materials.append(cornea_mat)
