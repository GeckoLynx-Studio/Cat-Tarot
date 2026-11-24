class_name CatAnimationBuilder
extends RefCounted

const CLIP_NAMES: Array[StringName] = [
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

const SAMPLE_FPS := 30.0


static func build_animation_library(skeleton: Skeleton3D) -> AnimationLibrary:
	var solver := _RigSolver.new(skeleton)
	var lib := AnimationLibrary.new()
	lib.add_animation(&"sit_idle", _bake_clip(solver, 3.60, true, _pose_sit_idle))
	lib.add_animation(&"sit_look_around", _bake_clip(solver, 4.20, false, _pose_sit_look_around))
	lib.add_animation(&"sit_groom_paw", _bake_clip(solver, 4.40, false, _pose_sit_groom_paw))
	lib.add_animation(&"sit_catnap_nod", _bake_clip(solver, 4.80, false, _pose_sit_catnap_nod))
	lib.add_animation(&"sit_chest_stretch", _bake_clip(solver, 3.80, false, _pose_sit_chest_stretch))
	lib.add_animation(&"sit_to_stand", _bake_clip(solver, 0.40, false, _pose_sit_to_stand))
	lib.add_animation(&"walk", _bake_clip(solver, 0.64, true, _pose_walk))
	lib.add_animation(&"stand_to_sit", _bake_clip(solver, 0.46, false, _pose_stand_to_sit))
	return lib


static func _bake_clip(solver: _RigSolver, duration: float, looping: bool, pose_fn: Callable) -> Animation:
	var anim := Animation.new()
	anim.length = duration
	anim.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE

	var skel_prefix := String(solver.skeleton_name) + ":"
	var pos_tracks: Dictionary = {}
	var rot_tracks: Dictionary = {}
	for b in solver.tracked_bones:
		var track_path := skel_prefix + solver.bone_names[b]
		if solver.position_keyed_bones.has(b):
			var pt := anim.add_track(Animation.TYPE_POSITION_3D)
			anim.track_set_path(pt, track_path)
			anim.track_set_interpolation_type(pt, Animation.INTERPOLATION_LINEAR)
			pos_tracks[b] = pt
		var rt := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(rt, track_path)
		anim.track_set_interpolation_type(rt, Animation.INTERPOLATION_LINEAR)
		rot_tracks[b] = rt

	var steps := maxi(4, ceili(duration * SAMPLE_FPS))
	var prev_quats: Dictionary = {}
	for s in range(steps + 1):
		var u := float(s) / float(steps)
		var t := u * duration
		# Ensure exact loop seam by feeding u=0.0 at final sample of looping clips.
		var eval_u := 0.0 if (looping and s == steps) else u
		pose_fn.call(solver, eval_u)
		for b in solver.tracked_bones:
			if pos_tracks.has(b):
				anim.position_track_insert_key(pos_tracks[b], t, solver.pose_local[b].origin)
			var q := solver.pose_local[b].basis.get_rotation_quaternion().normalized()
			if prev_quats.has(b) and (prev_quats[b] as Quaternion).dot(q) < 0.0:
				q = -q
			prev_quats[b] = q
			anim.rotation_track_insert_key(rot_tracks[b], t, q)

	return anim


static func _pose_sit_idle(solver: _RigSolver, u: float) -> void:
	var phase := u * TAU
	var breath := sin(phase)
	var sway := sin(phase * 0.5)
	var tail_wave := sin(phase)
	var tail_wave_lag := sin(phase - 0.85)
	var p := _sit_defaults()
	p["ctrl_offset"] += Vector3(0.0, 0.0012 * breath, 0.0)
	p["chest_euler"] += Vector3(-1.3 * breath, 1.4 * sway, 0.0)
	p["neck_euler"] += Vector3(-0.8 * breath, 2.2 * sway, 0.0)
	p["head_euler"] += Vector3(1.1 * breath, 3.2 * sway, 1.4 * sin(phase - 0.4))
	var tail: Array[Vector3] = p["tail"]
	tail[1] += Vector3(0.8 * tail_wave, 2.5 * tail_wave, 0.0)
	tail[2] += Vector3(1.5 * tail_wave_lag, 5.0 * tail_wave, 0.0)
	tail[3] += Vector3(2.2 * tail_wave_lag, 7.5 * tail_wave_lag, 0.0)
	tail[4] += Vector3(2.8 * sin(phase - 1.4), 9.0 * sin(phase - 1.3), 0.0)
	_apply_pose(solver, p)


static func _pose_sit_look_around(solver: _RigSolver, u: float) -> void:
	var env := _envelope(u, 0.14, 0.16)
	var look_left := _bell(u, 0.12, 0.48)
	var look_right := _bell(u, 0.46, 0.88)
	var yaw := 33.0 * look_left - 29.0 * look_right
	var head_roll := 5.5 * look_left - 4.5 * look_right
	var head_pitch := -5.0 * env + 3.0 * sin(u * TAU * 1.5) * env

	var p := _sit_defaults()
	p["chest_euler"] += Vector3(-2.5 * env, yaw * 0.22, 0.0)
	p["neck_euler"] += Vector3(-4.0 * env, yaw * 0.45, head_roll * 0.35)
	p["head_euler"] += Vector3(head_pitch, yaw, head_roll)
	var tail: Array[Vector3] = p["tail"]
	tail[2] += Vector3(2.0 * env, -yaw * 0.18, 0.0)
	tail[3] += Vector3(3.0 * env, -yaw * 0.28, 0.0)
	tail[4] += Vector3(4.0 * env, -yaw * 0.35, 0.0)
	_apply_pose(solver, p)


static func _pose_sit_groom_paw(solver: _RigSolver, u: float) -> void:
	var lift_env := _plateau(u, 0.08, 0.24, 0.74, 0.92)
	var lick_env := _plateau(u, 0.24, 0.32, 0.68, 0.76)
	var lick_cycle := 0.5 - 0.5 * cos((u - 0.26) / 0.46 * TAU * 3.0) if (u >= 0.26 and u <= 0.72) else 0.0

	var p := _sit_defaults()
	# Shift upper body slightly toward planted left paw while raising right paw.
	p["ctrl_offset"] += Vector3(0.010 * lift_env, 0.002 * lift_env, -0.003 * lift_env)
	p["chest_euler"] += Vector3(-3.0 * lift_env, -5.0 * lift_env, 4.0 * lift_env)
	p["neck_euler"] += Vector3(14.0 * lift_env + 4.0 * lick_cycle * lick_env, -6.0 * lift_env, -2.0 * lift_env)
	p["head_euler"] += Vector3(24.0 * lift_env + 10.0 * lick_cycle * lick_env, -8.0 * lift_env, -5.0 * lift_env)

	# Arc right wrist forward and up to sit cleanly just beneath the muzzle.
	var rest_w: Vector3 = p["front_r"]
	var groom_w := Vector3(-0.009, 0.165, 0.156 + 0.005 * lick_cycle * lick_env)
	var lift_arc := sin(lift_env * PI) * 0.018
	p["front_r"] = rest_w.lerp(groom_w, lift_env) + Vector3(-0.010 * lift_arc, 0.0, 0.020 * lift_arc)
	p["front_r_euler"] = Vector3(64.0 * lift_env + 10.0 * lick_cycle * lick_env, 26.0 * lift_env, -34.0 * lift_env)
	p["front_r_toe"] = 20.0 * lift_env
	p["front_r_pole_yaw"] = -16.0 * lift_env

	var tail: Array[Vector3] = p["tail"]
	tail[3] += Vector3(1.5 * lift_env, 4.0 * sin(u * TAU) * lift_env, 0.0)
	tail[4] += Vector3(2.0 * lift_env, 7.0 * sin(u * TAU) * lift_env, 0.0)
	_apply_pose(solver, p)


static func _pose_sit_catnap_nod(solver: _RigSolver, u: float) -> void:
	var drowsy := _plateau(u, 0.08, 0.34, 0.72, 0.94)
	var nod_dip := _bell(u, 0.36, 0.64)
	var startle := _bell(u, 0.64, 0.78)
	var p := _sit_defaults()
	p["ctrl_offset"] += Vector3(0.0, -0.004 * drowsy, -0.002 * drowsy)
	p["pelvis_euler"] += Vector3(2.5 * drowsy, 0.0, 0.0)
	p["chest_euler"] += Vector3(4.5 * drowsy + 2.0 * nod_dip - 2.5 * startle, 0.0, 0.0)
	p["neck_euler"] += Vector3(14.0 * drowsy + 7.0 * nod_dip - 6.0 * startle, 2.0 * drowsy, 0.0)
	p["head_euler"] += Vector3(19.0 * drowsy + 11.0 * nod_dip - 8.0 * startle, 4.0 * drowsy, 4.5 * drowsy)
	var tail: Array[Vector3] = p["tail"]
	tail[2] += Vector3(-1.5 * drowsy, 2.0 * drowsy, 0.0)
	tail[3] += Vector3(-2.0 * drowsy, 4.0 * drowsy, 0.0)
	tail[4] += Vector3(-2.5 * drowsy, 5.0 * drowsy, 0.0)
	_apply_pose(solver, p)


static func _pose_sit_chest_stretch(solver: _RigSolver, u: float) -> void:
	var bow := _plateau(u, 0.08, 0.30, 0.64, 0.92)
	var pulse := sin((u - 0.30) / 0.34 * PI) if (u > 0.30 and u < 0.64) else 0.0

	var p := _sit_defaults()
	p["ctrl_offset"] += Vector3(0.0, 0.018 * bow, -0.026 * bow)
	p["pelvis_euler"] += Vector3(14.0 * bow, 0.0, 0.0)
	p["chest_euler"] += Vector3(26.0 * bow + 3.0 * pulse, 0.0, 0.0)
	p["neck_euler"] += Vector3(24.0 * bow, 0.0, 0.0)
	p["head_euler"] += Vector3(-6.0 * bow, 0.0, 0.0)

	# Front paws slide forward inside balcony clearance while bowing chest low.
	p["front_r"] += Vector3(-0.004 * bow, 0.0, 0.032 * bow + 0.005 * pulse)
	p["front_l"] += Vector3(0.004 * bow, 0.0, 0.032 * bow + 0.005 * pulse)
	p["front_r_toe"] = -8.0 * bow
	p["front_l_toe"] = -8.0 * bow

	var tail: Array[Vector3] = p["tail"]
	tail[0] += Vector3(12.0 * bow, -8.0 * bow, 0.0)
	tail[1] += Vector3(10.0 * bow, -8.0 * bow, 0.0)
	tail[2] += Vector3(8.0 * bow, -8.0 * bow, 0.0)
	tail[3] += Vector3(6.0 * bow, -6.0 * bow, 0.0)
	tail[4] += Vector3(4.0 * bow, -4.0 * bow, 0.0)
	_apply_pose(solver, p)


static func _pose_sit_to_stand(solver: _RigSolver, u: float) -> void:
	var s := _smoothstep(u)
	var p_sit := _sit_defaults()
	var p_stand := _stand_defaults()
	var p := _lerp_pose_params(p_sit, p_stand, s)
	# Subtle crouch anticipation and smooth lift on front paws as cat rises into stride.
	var step_lift := sin(clampf((u - 0.35) / 0.55, 0.0, 1.0) * PI) * 0.012
	p["front_r"] += Vector3(0.0, step_lift, 0.0)
	_apply_pose(solver, p)


static func _pose_stand_to_sit(solver: _RigSolver, u: float) -> void:
	var s := _smoothstep(u)
	var p_stand := _stand_defaults()
	var p_sit := _sit_defaults()
	var p := _lerp_pose_params(p_stand, p_sit, s)
	var step_lift := sin(clampf((u - 0.15) / 0.55, 0.0, 1.0) * PI) * 0.012
	p["front_l"] += Vector3(0.0, step_lift, 0.0)
	_apply_pose(solver, p)


static func _pose_walk(solver: _RigSolver, u: float) -> void:
	var p := _stand_defaults()
	var phase := u * TAU
	# Double-frequency vertical bob and single-frequency lateral hip/chest counter-sway.
	var bob := -0.0038 * cos(phase * 2.0)
	var sway := 0.0035 * sin(phase)
	p["ctrl_offset"] += Vector3(sway, bob, 0.0)
	p["pelvis_euler"] += Vector3(1.5 * sin(phase * 2.0), -3.2 * sin(phase), 2.5 * cos(phase))
	p["chest_euler"] += Vector3(-1.2 * sin(phase * 2.0), 3.4 * sin(phase), -2.0 * cos(phase))
	p["neck_euler"] += Vector3(1.5 * cos(phase * 2.0), -1.5 * sin(phase), 0.0)
	p["head_euler"] += Vector3(1.2 * sin(phase * 2.0), 0.5 * sin(phase), 0.0)

	# 4-beat quadruped walk gait: HL(0.0), FL(0.25), HR(0.50), FR(0.75).
	var fr := _walk_foot(fposmod(u + 0.75, 1.0), Vector3(-0.029, 0.0196, 0.148), 0.048, 0.028, false)
	var fl := _walk_foot(fposmod(u + 0.25, 1.0), Vector3(0.030, 0.0196, 0.148), 0.048, 0.028, false)
	var hr := _walk_foot(fposmod(u + 0.50, 1.0), Vector3(-0.030, 0.0154, -0.064), 0.044, 0.026, true)
	var hl := _walk_foot(fposmod(u + 0.00, 1.0), Vector3(0.030, 0.0154, -0.064), 0.044, 0.026, true)

	p["front_r"] = fr["pos"]
	p["front_r_euler"] = fr["euler"]
	p["front_r_toe"] = fr["toe"]
	p["front_l"] = fl["pos"]
	p["front_l_euler"] = fl["euler"]
	p["front_l_toe"] = fl["toe"]

	p["hind_r"] = hr["pos"]
	p["hind_dir3_r"] = hr["dir3"]
	p["hind_r_euler"] = hr["euler"]
	p["hind_r_toe"] = hr["toe"]
	p["hind_l"] = hl["pos"]
	p["hind_dir3_l"] = hl["dir3"]
	p["hind_l_euler"] = hl["euler"]
	p["hind_l_toe"] = hl["toe"]

	var tail: Array[Vector3] = p["tail"]
	tail[0] += Vector3(2.0 * sin(phase * 2.0), 6.0 * sin(phase), 0.0)
	tail[1] += Vector3(2.5 * sin(phase * 2.0 - 0.5), 8.0 * sin(phase - 0.6), 0.0)
	tail[2] += Vector3(3.0 * sin(phase * 2.0 - 1.0), 10.0 * sin(phase - 1.2), 0.0)
	tail[3] += Vector3(3.5 * sin(phase * 2.0 - 1.5), 11.0 * sin(phase - 1.8), 0.0)
	tail[4] += Vector3(4.0 * sin(phase * 2.0 - 2.0), 12.0 * sin(phase - 2.4), 0.0)
	_apply_pose(solver, p)


static func _walk_foot(phi: float, base_pos: Vector3, half_stride: float, lift_h: float, is_hind: bool) -> Dictionary:
	const STANCE_DUTY := 0.64
	var z_off: float
	var y_off: float = 0.0
	var foot_pitch: float = 0.0
	var toe_pitch: float = 0.0
	if phi < STANCE_DUTY:
		var s := phi / STANCE_DUTY
		z_off = lerpf(half_stride, -half_stride, s)
		foot_pitch = lerpf(-4.0, 8.0, s)
	else:
		var s := (phi - STANCE_DUTY) / (1.0 - STANCE_DUTY)
		var ss := _smoothstep(s)
		z_off = lerpf(-half_stride, half_stride, ss)
		y_off = sin(s * PI) * lift_h
		foot_pitch = lerpf(16.0, -14.0, s) * sin(s * PI)
		toe_pitch = 16.0 * sin(s * PI)

	var out := {
		"pos": base_pos + Vector3(0.0, y_off, z_off),
		"euler": Vector3(foot_pitch, 0.0, 0.0),
		"toe": toe_pitch,
	}
	if is_hind:
		# Tilt metatarsus forward at touch-down (+z_off) and backward on push-off (-z_off).
		var z_dir := clampf(z_off / half_stride, -1.0, 1.0) * 0.36
		out["dir3"] = Vector3(0.0, -1.0, z_dir).normalized()
	return out


static func _sit_defaults() -> Dictionary:
	var tail: Array[Vector3] = [
		Vector3(12.0, 34.0, 0.0),
		Vector3(6.0, 42.0, 0.0),
		Vector3(2.0, 42.0, 0.0),
		Vector3(2.0, 34.0, 0.0),
		Vector3(3.0, 24.0, 0.0),
	]
	return {
		"ctrl_offset": Vector3(0.0, -0.136, -0.026),
		"pelvis_euler": Vector3(-33.0, 0.0, 0.0),
		"chest_euler": Vector3(-37.0, 0.0, 0.0),
		"neck_euler": Vector3(-53.0, 0.0, 0.0),
		"head_euler": Vector3(4.0, 0.0, 0.0),
		"front_r": Vector3(-0.025, 0.0196, 0.100),
		"front_r_euler": Vector3.ZERO,
		"front_r_toe": 0.0,
		"front_r_pole_yaw": -4.0,
		"front_l": Vector3(0.026, 0.0196, 0.100),
		"front_l_euler": Vector3.ZERO,
		"front_l_toe": 0.0,
		"front_l_pole_yaw": 4.0,
		"hind_r": Vector3(-0.036, 0.0154, -0.022),
		"hind_dir3_r": Vector3(-0.04, -0.22, 0.975).normalized(),
		"hind_r_euler": Vector3.ZERO,
		"hind_r_toe": 0.0,
		"hind_r_pole_yaw": -10.0,
		"hind_l": Vector3(0.036, 0.0154, -0.022),
		"hind_dir3_l": Vector3(0.04, -0.22, 0.975).normalized(),
		"hind_l_euler": Vector3.ZERO,
		"hind_l_toe": 0.0,
		"hind_l_pole_yaw": 10.0,
		"tail": tail,
	}


static func _stand_defaults() -> Dictionary:
	var tail: Array[Vector3] = [
		Vector3(16.0, 0.0, 0.0),
		Vector3(12.0, 0.0, 0.0),
		Vector3(6.0, 0.0, 0.0),
		Vector3(-6.0, 0.0, 0.0),
		Vector3(-10.0, 0.0, 0.0),
	]
	return {
		"ctrl_offset": Vector3(0.0, -0.012, 0.0),
		"pelvis_euler": Vector3.ZERO,
		"chest_euler": Vector3.ZERO,
		"neck_euler": Vector3(-12.0, 0.0, 0.0),
		"head_euler": Vector3(4.0, 0.0, 0.0),
		"front_r": Vector3(-0.029, 0.0196, 0.150),
		"front_r_euler": Vector3.ZERO,
		"front_r_toe": 0.0,
		"front_r_pole_yaw": 0.0,
		"front_l": Vector3(0.030, 0.0196, 0.150),
		"front_l_euler": Vector3.ZERO,
		"front_l_toe": 0.0,
		"front_l_pole_yaw": 0.0,
		"hind_r": Vector3(-0.030, 0.0154, -0.064),
		"hind_dir3_r": Vector3(0.0, -0.992, 0.12).normalized(),
		"hind_r_euler": Vector3.ZERO,
		"hind_r_toe": 0.0,
		"hind_r_pole_yaw": 0.0,
		"hind_l": Vector3(0.030, 0.0154, -0.064),
		"hind_dir3_l": Vector3(0.0, -0.992, 0.12).normalized(),
		"hind_l_euler": Vector3.ZERO,
		"hind_l_toe": 0.0,
		"hind_l_pole_yaw": 0.0,
		"tail": tail,
	}


static func _lerp_pose_params(a: Dictionary, b: Dictionary, s: float) -> Dictionary:
	var tail_a: Array[Vector3] = a["tail"]
	var tail_b: Array[Vector3] = b["tail"]
	var tail_out: Array[Vector3] = []
	for i in 5:
		tail_out.append(tail_a[i].lerp(tail_b[i], s))
	return {
		"ctrl_offset": (a["ctrl_offset"] as Vector3).lerp(b["ctrl_offset"], s),
		"pelvis_euler": (a["pelvis_euler"] as Vector3).lerp(b["pelvis_euler"], s),
		"chest_euler": (a["chest_euler"] as Vector3).lerp(b["chest_euler"], s),
		"neck_euler": (a["neck_euler"] as Vector3).lerp(b["neck_euler"], s),
		"head_euler": (a["head_euler"] as Vector3).lerp(b["head_euler"], s),
		"front_r": (a["front_r"] as Vector3).lerp(b["front_r"], s),
		"front_r_euler": (a["front_r_euler"] as Vector3).lerp(b["front_r_euler"], s),
		"front_r_toe": lerpf(a["front_r_toe"], b["front_r_toe"], s),
		"front_r_pole_yaw": lerpf(a["front_r_pole_yaw"], b["front_r_pole_yaw"], s),
		"front_l": (a["front_l"] as Vector3).lerp(b["front_l"], s),
		"front_l_euler": (a["front_l_euler"] as Vector3).lerp(b["front_l_euler"], s),
		"front_l_toe": lerpf(a["front_l_toe"], b["front_l_toe"], s),
		"front_l_pole_yaw": lerpf(a["front_l_pole_yaw"], b["front_l_pole_yaw"], s),
		"hind_r": (a["hind_r"] as Vector3).lerp(b["hind_r"], s),
		"hind_dir3_r": (a["hind_dir3_r"] as Vector3).lerp(b["hind_dir3_r"], s).normalized(),
		"hind_r_euler": (a["hind_r_euler"] as Vector3).lerp(b["hind_r_euler"], s),
		"hind_r_toe": lerpf(a["hind_r_toe"], b["hind_r_toe"], s),
		"hind_r_pole_yaw": lerpf(a["hind_r_pole_yaw"], b["hind_r_pole_yaw"], s),
		"hind_l": (a["hind_l"] as Vector3).lerp(b["hind_l"], s),
		"hind_dir3_l": (a["hind_dir3_l"] as Vector3).lerp(b["hind_dir3_l"], s).normalized(),
		"hind_l_euler": (a["hind_l_euler"] as Vector3).lerp(b["hind_l_euler"], s),
		"hind_l_toe": lerpf(a["hind_l_toe"], b["hind_l_toe"], s),
		"hind_l_pole_yaw": lerpf(a["hind_l_pole_yaw"], b["hind_l_pole_yaw"], s),
		"tail": tail_out,
	}


static func _apply_pose(solver: _RigSolver, p: Dictionary) -> void:
	solver.reset_to_rest()
	solver.pose_spine_and_head(
		p["ctrl_offset"],
		p["pelvis_euler"],
		p["chest_euler"],
		p["neck_euler"],
		p["head_euler"]
	)
	solver.pose_tail(p["tail"])
	solver.pose_front_leg(true, p["front_r"], p["front_r_pole_yaw"], p["front_r_euler"], p["front_r_toe"])
	solver.pose_front_leg(false, p["front_l"], p["front_l_pole_yaw"], p["front_l_euler"], p["front_l_toe"])
	solver.pose_hind_leg(true, p["hind_r"], p["hind_dir3_r"], p["hind_r_pole_yaw"], p["hind_r_euler"], p["hind_r_toe"])
	solver.pose_hind_leg(false, p["hind_l"], p["hind_dir3_l"], p["hind_l_pole_yaw"], p["hind_l_euler"], p["hind_l_toe"])


static func _smoothstep(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


static func _envelope(u: float, fade_in: float, fade_out: float) -> float:
	if u <= 0.0 or u >= 1.0:
		return 0.0
	if u < fade_in:
		return _smoothstep(u / fade_in)
	if u > 1.0 - fade_out:
		return _smoothstep((1.0 - u) / fade_out)
	return 1.0


static func _plateau(u: float, t0: float, t1: float, t2: float, t3: float) -> float:
	if u <= t0 or u >= t3:
		return 0.0
	if u < t1:
		return _smoothstep((u - t0) / maxf(t1 - t0, 1e-5))
	if u <= t2:
		return 1.0
	return _smoothstep((t3 - u) / maxf(t3 - t2, 1e-5))


static func _bell(u: float, t0: float, t1: float) -> float:
	if u <= t0 or u >= t1:
		return 0.0
	var s := (u - t0) / maxf(t1 - t0, 1e-5)
	return 0.5 - 0.5 * cos(s * TAU)


class _RigSolver extends RefCounted:
	var skeleton_name: StringName
	var bone_names: PackedStringArray = PackedStringArray()
	var rest_local: Array[Transform3D] = []
	var rest_global: Array[Transform3D] = []
	var pose_local: Array[Transform3D] = []
	var pose_global: Array[Transform3D] = []
	var tracked_bones: PackedInt32Array = PackedInt32Array()
	var position_keyed_bones: Dictionary = {}

	var _idx_ctrl: int
	var _idx_pelvis: int
	var _idx_chest: int
	var _idx_neck: int
	var _idx_head: int
	var _idx_tail: Array[int] = []

	var _front_bones_r: Array[int]
	var _front_bones_l: Array[int]
	var _hind_bones_r: Array[int]
	var _hind_bones_l: Array[int]

	func _init(skeleton: Skeleton3D) -> void:
		skeleton_name = skeleton.name
		var count := skeleton.get_bone_count()
		for i in count:
			var bname := skeleton.get_bone_name(i)
			bone_names.append(bname)
			rest_local.append(skeleton.get_bone_rest(i))
			rest_global.append(skeleton.get_bone_global_rest(i))
			pose_local.append(rest_local[i])
			pose_global.append(rest_global[i])
			# Key all deforming + control bones (0..27); skip non-deforming pole markers (28..31).
			if not bname.contains("pole"):
				tracked_bones.append(i)

		_idx_ctrl = skeleton.find_bone("CONTROLLER")
		_idx_pelvis = skeleton.find_bone("pelvis")
		_idx_chest = skeleton.find_bone("Bone.001")
		_idx_neck = skeleton.find_bone("Bone.002")
		_idx_head = skeleton.find_bone("Bone.004")
		for k in range(1, 6):
			_idx_tail.append(skeleton.find_bone("tail" + str(k)))

		_front_bones_r = [
			skeleton.find_bone("paw1_R"),
			skeleton.find_bone("paw2_R"),
			skeleton.find_bone("paw_control_R"),
			skeleton.find_bone("paw3_R"),
		]
		_front_bones_l = [
			skeleton.find_bone("paw1_L"),
			skeleton.find_bone("paw2_L"),
			skeleton.find_bone("paw_control_L"),
			skeleton.find_bone("paw3_L"),
		]
		_hind_bones_r = [
			skeleton.find_bone("leg1_R"),
			skeleton.find_bone("leg2_R"),
			skeleton.find_bone("leg3_R"),
			skeleton.find_bone("leg3_control_R"),
			skeleton.find_bone("feet_R"),
		]
		_hind_bones_l = [
			skeleton.find_bone("leg1_L"),
			skeleton.find_bone("leg2_L"),
			skeleton.find_bone("leg3_L"),
			skeleton.find_bone("leg3_control_L"),
			skeleton.find_bone("feet_L"),
		]

		for b in [
			_idx_ctrl,
			_idx_pelvis,
			_front_bones_r[0],
			_front_bones_l[0],
			_front_bones_r[2],
			_front_bones_l[2],
			_hind_bones_r[3],
			_hind_bones_l[3],
		]:
			position_keyed_bones[b] = true

	func reset_to_rest() -> void:
		for i in rest_local.size():
			pose_local[i] = rest_local[i]
			pose_global[i] = rest_global[i]

	func pose_spine_and_head(
		ctrl_offset: Vector3,
		pelvis_euler_deg: Vector3,
		chest_world_deg: Vector3,
		neck_world_deg: Vector3,
		head_world_deg: Vector3
	) -> void:
		pose_local[_idx_ctrl] = Transform3D(
			rest_local[_idx_ctrl].basis,
			rest_local[_idx_ctrl].origin + ctrl_offset
		)
		pose_global[_idx_ctrl] = pose_local[_idx_ctrl]

		var r_pelvis := _euler_deg_basis(pelvis_euler_deg)
		var g_pelvis_pos := pose_global[_idx_ctrl].origin + (rest_global[_idx_pelvis].origin - rest_global[_idx_ctrl].origin)
		pose_local[_idx_pelvis].origin = pose_global[_idx_ctrl].inverse() * g_pelvis_pos
		pose_local[_idx_pelvis].basis = pose_global[_idx_ctrl].basis.inverse() * (r_pelvis * rest_global[_idx_pelvis].basis)
		pose_global[_idx_pelvis] = pose_global[_idx_ctrl] * pose_local[_idx_pelvis]

		_set_world_skel_rotation(_idx_chest, _idx_pelvis, _euler_deg_basis(chest_world_deg))
		_set_world_skel_rotation(_idx_neck, _idx_chest, _euler_deg_basis(neck_world_deg))
		_set_world_skel_rotation(_idx_head, _idx_neck, _euler_deg_basis(head_world_deg))

	func pose_tail(curls_deg: Array[Vector3]) -> void:
		var parent := _idx_pelvis
		for k in _idx_tail.size():
			var b := _idx_tail[k]
			var r_rel := _euler_deg_basis(curls_deg[k])
			# Bone-roll fix: L_pose = L_rest * (G_rest.inverse() * R_skel * G_rest)
			var roll_fix := rest_global[b].basis.inverse() * r_rel * rest_global[b].basis
			pose_local[b].origin = rest_local[b].origin
			pose_local[b].basis = rest_local[b].basis * roll_fix
			pose_global[b] = pose_global[parent] * pose_local[b]
			parent = b

	func pose_front_leg(
		side_right: bool,
		wrist_desired: Vector3,
		pole_yaw_deg: float,
		paw_euler_deg: Vector3,
		toe_pitch_deg: float
	) -> void:
		var chain := _front_bones_r if side_right else _front_bones_l
		var b1: int = chain[0]
		var b2: int = chain[1]
		var ctrl: int = chain[2]
		var toe: int = chain[3]

		# Shoulder-parent fix: attach paw1_R/L rigidly to Bone.001 (chest) then convert to pelvis local.
		var shoulder_in_chest := rest_global[_idx_chest].inverse() * rest_global[b1].origin
		var s_pos := pose_global[_idx_chest] * shoulder_in_chest
		var l1 := rest_local[b2].origin.length()
		var l2 := (rest_global[ctrl].origin - rest_global[b2].origin).length()

		var pole := Basis(Vector3.UP, deg_to_rad(pole_yaw_deg)) * Vector3(0.0, 0.0, -1.0)
		var side_ref := Basis(Vector3.UP, deg_to_rad(pole_yaw_deg)) * Vector3.RIGHT
		var ik := _solve_2bone(s_pos, wrist_desired, l1, l2, pole, side_ref)
		var e_pos: Vector3 = ik[0]
		var w_actual: Vector3 = ik[1]
		var side_axis: Vector3 = ik[2]

		var rest_dir1 := (rest_global[b2].origin - rest_global[b1].origin).normalized()
		var rest_dir2 := (rest_global[ctrl].origin - rest_global[b2].origin).normalized()
		var r1 := _align_frame(rest_dir1, Vector3.RIGHT, (e_pos - s_pos).normalized(), side_axis)
		var r2 := _align_frame(rest_dir2, Vector3.RIGHT, (w_actual - e_pos).normalized(), side_axis)

		pose_local[b1].origin = pose_global[_idx_pelvis].inverse() * s_pos
		pose_local[b1].basis = pose_global[_idx_pelvis].basis.inverse() * (r1 * rest_global[b1].basis)
		pose_global[b1] = pose_global[_idx_pelvis] * pose_local[b1]

		pose_local[b2].origin = rest_local[b2].origin
		pose_local[b2].basis = pose_global[b1].basis.inverse() * (r2 * rest_global[b2].basis)
		pose_global[b2] = pose_global[b1] * pose_local[b2]

		_pose_foot_control(ctrl, toe, w_actual, paw_euler_deg, toe_pitch_deg)

	func pose_hind_leg(
		side_right: bool,
		ankle_desired: Vector3,
		dir3_in: Vector3,
		pole_yaw_deg: float,
		foot_euler_deg: Vector3,
		toe_pitch_deg: float
	) -> void:
		var chain := _hind_bones_r if side_right else _hind_bones_l
		var b1: int = chain[0]
		var b2: int = chain[1]
		var b3: int = chain[2]
		var ctrl: int = chain[3]
		var toe: int = chain[4]

		var hip_in_pelvis := rest_global[_idx_pelvis].inverse() * rest_global[b1].origin
		var h_pos := pose_global[_idx_pelvis] * hip_in_pelvis
		var l1 := rest_local[b2].origin.length()
		var l2 := rest_local[b3].origin.length()
		var l3 := (rest_global[ctrl].origin - rest_global[b3].origin).length()

		var dir3 := dir3_in.normalized()
		var a_des := ankle_desired - dir3 * l3
		var max_ha := l1 + l2 - 0.002
		var ha_vec := a_des - h_pos
		if ha_vec.length() > max_ha and ha_vec.length_squared() > 1e-8:
			a_des = h_pos + ha_vec.normalized() * max_ha

		var pole := Basis(Vector3.UP, deg_to_rad(pole_yaw_deg)) * Vector3(0.0, 0.25, 1.0).normalized()
		var side_ref := Basis(Vector3.UP, deg_to_rad(pole_yaw_deg)) * Vector3.RIGHT
		var ik := _solve_2bone(h_pos, a_des, l1, l2, pole, side_ref)
		var k_pos: Vector3 = ik[0]
		var a_actual: Vector3 = ik[1]
		var side_axis: Vector3 = ik[2]
		var p_actual := a_actual + dir3 * l3

		var rest_dir1 := (rest_global[b2].origin - rest_global[b1].origin).normalized()
		var rest_dir2 := (rest_global[b3].origin - rest_global[b2].origin).normalized()
		var rest_dir3 := (rest_global[ctrl].origin - rest_global[b3].origin).normalized()
		var r1 := _align_frame(rest_dir1, Vector3.RIGHT, (k_pos - h_pos).normalized(), side_axis)
		var r2 := _align_frame(rest_dir2, Vector3.RIGHT, (a_actual - k_pos).normalized(), side_axis)
		var r3 := _align_frame(rest_dir3, Vector3.RIGHT, dir3, side_axis)

		pose_local[b1].origin = pose_global[_idx_pelvis].inverse() * h_pos
		pose_local[b1].basis = pose_global[_idx_pelvis].basis.inverse() * (r1 * rest_global[b1].basis)
		pose_global[b1] = pose_global[_idx_pelvis] * pose_local[b1]

		pose_local[b2].origin = rest_local[b2].origin
		pose_local[b2].basis = pose_global[b1].basis.inverse() * (r2 * rest_global[b2].basis)
		pose_global[b2] = pose_global[b1] * pose_local[b2]

		pose_local[b3].origin = rest_local[b3].origin
		pose_local[b3].basis = pose_global[b2].basis.inverse() * (r3 * rest_global[b3].basis)
		pose_global[b3] = pose_global[b2] * pose_local[b3]

		_pose_foot_control(ctrl, toe, p_actual, foot_euler_deg, toe_pitch_deg)

	func _pose_foot_control(
		ctrl: int,
		toe: int,
		world_pos: Vector3,
		foot_euler_deg: Vector3,
		toe_pitch_deg: float
	) -> void:
		var r_foot := _euler_deg_basis(foot_euler_deg)
		pose_local[ctrl].origin = world_pos
		pose_local[ctrl].basis = rest_local[ctrl].basis * (rest_global[ctrl].basis.inverse() * r_foot * rest_global[ctrl].basis)
		pose_global[ctrl] = pose_local[ctrl]

		var r_toe := Basis(Vector3.RIGHT, deg_to_rad(toe_pitch_deg))
		pose_local[toe].origin = rest_local[toe].origin
		pose_local[toe].basis = rest_local[toe].basis * (rest_global[toe].basis.inverse() * r_toe * rest_global[toe].basis)
		pose_global[toe] = pose_global[ctrl] * pose_local[toe]

	func _set_world_skel_rotation(b: int, parent: int, r_world_skel: Basis) -> void:
		pose_local[b].origin = rest_local[b].origin
		pose_local[b].basis = pose_global[parent].basis.inverse() * (r_world_skel * rest_global[b].basis)
		pose_global[b] = pose_global[parent] * pose_local[b]

	static func _euler_deg_basis(deg: Vector3) -> Basis:
		return Basis.from_euler(
			Vector3(deg_to_rad(deg.x), deg_to_rad(deg.y), deg_to_rad(deg.z)),
			EULER_ORDER_YXZ
		)

	static func _solve_2bone(
		s: Vector3,
		t_des: Vector3,
		l1: float,
		l2: float,
		pole_dir: Vector3,
		side_ref: Vector3
	) -> Array:
		var dv := t_des - s
		var d := dv.length()
		var u := dv.normalized() if d > 1e-6 else Vector3.DOWN
		var dc := clampf(d, absf(l1 - l2) + 0.002, l1 + l2 - 0.0015)
		var t_actual := s + u * dc
		var cos_a := clampf((l1 * l1 + dc * dc - l2 * l2) / (2.0 * l1 * dc), -1.0, 1.0)
		var sin_a := sqrt(maxf(0.0, 1.0 - cos_a * cos_a))
		var bend := pole_dir - u * pole_dir.dot(u)
		if bend.length_squared() < 1e-6:
			bend = Vector3.BACK - u * Vector3.BACK.dot(u)
		bend = bend.normalized()
		var mid := s + u * (l1 * cos_a) + bend * (l1 * sin_a)
		var side := u.cross(bend)
		if side.length_squared() < 1e-6:
			side = side_ref
		side = side.normalized()
		if side.dot(side_ref) < 0.0:
			side = -side
		return [mid, t_actual, side]

	static func _align_frame(rest_dir: Vector3, rest_side: Vector3, target_dir: Vector3, target_side: Vector3) -> Basis:
		var r_s := (rest_side - rest_dir * rest_side.dot(rest_dir)).normalized()
		var f_rest := Basis(r_s, rest_dir, r_s.cross(rest_dir)).orthonormalized()
		var t_s := (target_side - target_dir * target_side.dot(target_dir)).normalized()
		var f_pose := Basis(t_s, target_dir, t_s.cross(target_dir)).orthonormalized()
		return f_pose * f_rest.inverse()
