extends Node
## Prepares the actual table instance for handoff to the main viewport.

signal preparation_finished

const TABLE_PATH := "res://scenes/main.tscn"
const CAT_MODEL_PATH := "res://assets/models/cat/domestic_cat_rigged.gltf"
const WARMUP_SIZE := Vector2i(320, 180)
const CatAnimationBuilder := preload("res://scripts/cat_animation_builder.gd")

var finished: bool = false
var _table: Node3D
var _menu: Node3D
var _viewport: SubViewport
var _load_requested: bool = false
var _preparing: bool = false
var _shaders_warmed: bool = false
var _table_packed: PackedScene
var _theatre_models: Dictionary = {}
var _letter_textures: Dictionary = {}
var _card_textures: Dictionary = {}
var _card_load_requested: Dictionary = {}
var _cat_packed_scene: PackedScene
var _cat_load_requested: bool = false
var _cat_anim_library: AnimationLibrary


func begin_load() -> void:
	if _table_packed != null or _load_requested:
		return
	_load_requested = true
	ResourceLoader.load_threaded_request(TABLE_PATH, "PackedScene")


func begin_cat_load() -> void:
	if _cat_packed_scene != null or _cat_load_requested:
		return
	_cat_load_requested = true
	ResourceLoader.load_threaded_request(CAT_MODEL_PATH, "PackedScene")


func get_cat_packed_scene() -> PackedScene:
	if _cat_packed_scene != null:
		return _cat_packed_scene
	if _cat_load_requested:
		var status := ResourceLoader.load_threaded_get_status(CAT_MODEL_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_cat_packed_scene = ResourceLoader.load_threaded_get(CAT_MODEL_PATH) as PackedScene
	if _cat_packed_scene == null:
		_cat_packed_scene = ResourceLoader.load(
			CAT_MODEL_PATH,
			"PackedScene",
			ResourceLoader.CACHE_MODE_REUSE
		) as PackedScene
	return _cat_packed_scene


func get_cat_animation_library(skeleton: Skeleton3D) -> AnimationLibrary:
	if _cat_anim_library == null and skeleton != null:
		_cat_anim_library = CatAnimationBuilder.build_animation_library(skeleton)
	return _cat_anim_library


func get_theatre_model(path: String) -> PackedScene:
	if _theatre_models.has(path):
		return _theatre_models[path] as PackedScene
	var packed := load(path) as PackedScene
	if packed != null:
		_theatre_models[path] = packed
	return packed


func get_letter_texture(words: String, size: Vector2, color: Color, font: Font) -> ViewportTexture:
	var key := "%s|%.3f|%.3f|%s" % [words, size.x, size.y, color.to_html()]
	if _letter_textures.has(key):
		return _letter_textures[key] as ViewportTexture
	var vp := SubViewport.new()
	vp.size = Vector2i(960, maxi(72, roundi(960.0 * size.y / size.x)))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.gui_disable_input = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var label := Label.new()
	label.size = Vector2(vp.size)
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	var fit := minf(vp.size.y * 0.82, vp.size.x * 100.0 / font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x * 0.96)
	label.add_theme_font_size_override("font_size", maxi(12, int(fit)))
	label.add_theme_color_override("font_color", color)
	vp.add_child(label)
	var tex := vp.get_texture()
	_letter_textures[key] = tex
	return tex


func preload_card_texture(card_id: int) -> void:
	if _card_textures.has(card_id) or _card_load_requested.has(card_id):
		return
	var path := CardDatabase.texture_path(card_id)
	if not ResourceLoader.exists(path):
		return
	_card_load_requested[card_id] = path
	ResourceLoader.load_threaded_request(path, "Texture2D")


func get_card_texture(card_id: int) -> Texture2D:
	if _card_textures.has(card_id):
		return _card_textures[card_id] as Texture2D
	var path := CardDatabase.texture_path(card_id)
	var texture: Texture2D = null
	if _card_load_requested.has(card_id):
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			texture = ResourceLoader.load_threaded_get(path) as Texture2D
		_card_load_requested.erase(card_id)
	if texture == null and ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded is Texture2D:
			texture = loaded
	if texture != null:
		_card_textures[card_id] = texture
	return texture


func prepare() -> void:
	if finished or _preparing:
		return
	begin_load()
	_preparing = true
	_prepare.call_deferred()


func take_table() -> Node3D:
	if not finished:
		return null
	finished = false
	var table := _table
	_table = null
	if not is_instance_valid(table):
		return null
	_viewport.remove_child(table)
	_viewport.queue_free()
	_viewport = null
	table.set("preparing_offscreen", false)
	table.request_ready()
	return table


func keep_menu(menu: Node3D) -> void:
	# SceneTree frees the current scene on a swap. Keep this one detached for Esc.
	if is_instance_valid(_menu):
		_menu.free()
	get_tree().current_scene = null
	menu.get_parent().remove_child(menu)
	_menu = menu


func take_menu() -> Node3D:
	var menu := _menu
	_menu = null
	if is_instance_valid(menu):
		menu.request_ready()
	return menu


func _exit_tree() -> void:
	if is_instance_valid(_menu):
		_menu.free()
	_table_packed = null
	_theatre_models.clear()
	_letter_textures.clear()
	_card_textures.clear()
	_card_load_requested.clear()
	_cat_packed_scene = null
	_cat_anim_library = null


func _prepare() -> void:
	var tree := get_tree()
	var packed := _table_packed
	if packed == null:
		var status := ResourceLoader.load_threaded_get_status(TABLE_PATH)
		while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await tree.process_frame
			status = ResourceLoader.load_threaded_get_status(TABLE_PATH)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			packed = ResourceLoader.load_threaded_get(TABLE_PATH) as PackedScene
		else:
			packed = load(TABLE_PATH) as PackedScene
		_table_packed = packed
	if packed != null:
		_table = packed.instantiate() as Node3D
	if _table != null:
		_viewport = SubViewport.new()
		_viewport.size = WARMUP_SIZE
		_viewport.world_3d = World3D.new()
		_viewport.msaa_3d = get_viewport().msaa_3d
		_viewport.gui_disable_input = true
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child(_viewport)
		_table.set("preparing_offscreen", true)
		_viewport.add_child(_table)
		if not _shaders_warmed and DisplayServer.get_name() != "headless":
			_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
			await RenderingServer.frame_post_draw
			_shaders_warmed = true
	finished = true
	_preparing = false
	preparation_finished.emit()
