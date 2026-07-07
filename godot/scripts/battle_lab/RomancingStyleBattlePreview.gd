extends Control

const VIRTUAL_SIZE := Vector2(320, 224)

@export_file("*.json") var sample_path := "res://samples/romancing-style-turn-result.json"
@export_file("*.json") var presentation_path := "res://data/battle_lab/actor-presentations.json"
@export_file("*.json") var action_presentation_path := "res://data/battle_lab/action-presentations.json"
@export var action_delay := 0.5
@export var damage_delay := 0.75

var scale_factor := 1.0
var origin := Vector2.ZERO
var presentation_data: Dictionary = {}
var action_presentation_data: Dictionary = {}
var actor_views: Dictionary = {}
var actor_data: Dictionary = {}
var idle_tweens: Array[Tween] = []
var idle_timers: Array[Timer] = []
var active_action_id := ""
var party_order: Array[String] = []
var enemy_order: Array[String] = []
var enemy_sprite: TextureRect
var banner_panel: PanelContainer
var banner_label: Label
var menu_panel: PanelContainer
var menu_label: Label
var status_layer: Control
var effects_layer: Control
var replay_button: Button
var is_playing := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build_ui()
	replay()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()
		queue_redraw()

func _draw() -> void:
	_draw_frame()
	_draw_sky()
	_draw_stone_floor()

func replay() -> void:
	if is_playing:
		return
	_play_sample()

func _build_ui() -> void:
	status_layer = Control.new()
	add_child(status_layer)

	effects_layer = Control.new()
	add_child(effects_layer)

	banner_panel = _make_panel(Color(0.83, 0.97, 0.98, 1.0), Color(0.08, 0.1, 0.16, 1.0), 0)
	banner_panel.visible = false
	add_child(banner_panel)

	var banner_margin := MarginContainer.new()
	banner_margin.add_theme_constant_override("margin_left", 12)
	banner_margin.add_theme_constant_override("margin_top", 6)
	banner_margin.add_theme_constant_override("margin_right", 12)
	banner_margin.add_theme_constant_override("margin_bottom", 6)
	banner_panel.add_child(banner_margin)

	banner_label = Label.new()
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 20)
	banner_label.add_theme_color_override("font_color", Color(0.02, 0.03, 0.06, 1.0))
	banner_label.add_theme_constant_override("outline_size", 2)
	banner_label.add_theme_color_override("font_outline_color", Color.WHITE)
	banner_margin.add_child(banner_label)

	menu_panel = _make_panel(Color(0.83, 0.97, 0.98, 0.96), Color(0.08, 0.1, 0.16, 1.0), 0)
	add_child(menu_panel)
	var menu_margin := MarginContainer.new()
	menu_margin.add_theme_constant_override("margin_left", 14)
	menu_margin.add_theme_constant_override("margin_top", 8)
	menu_margin.add_theme_constant_override("margin_right", 14)
	menu_margin.add_theme_constant_override("margin_bottom", 8)
	menu_panel.add_child(menu_margin)
	menu_label = Label.new()
	menu_label.add_theme_font_size_override("font_size", 14)
	menu_label.add_theme_color_override("font_color", Color(0.02, 0.03, 0.06, 1.0))
	menu_label.add_theme_constant_override("outline_size", 1)
	menu_label.add_theme_color_override("font_outline_color", Color.WHITE)
	menu_margin.add_child(menu_label)
	menu_panel.visible = false

	replay_button = Button.new()
	replay_button.text = "Replay"
	replay_button.pressed.connect(replay)
	add_child(replay_button)

	_update_layout()

func _play_sample() -> void:
	is_playing = true
	replay_button.disabled = true
	_clear_battle()

	var payload := _load_json(sample_path)
	presentation_data = _load_json(presentation_path)
	action_presentation_data = _load_json(action_presentation_path)
	if payload.is_empty():
		_show_banner("Failed to load sample")
		is_playing = false
		replay_button.disabled = false
		return

	for actor in payload.get("finalState", {}).get("actors", []):
		_register_actor(actor)

	for event in payload.get("events", []):
		if event.get("type") == "damage" or event.get("type") == "heal":
			var target_id := str(event.get("targetId", ""))
			var data: Dictionary = actor_data.get(target_id, {})
			if not data.is_empty():
				data["hp"] = int(event.get("hpBefore", 0))
				actor_data[target_id] = data

	_spawn_actors()
	_update_layout()
	_start_idle_for_all_actors()
	_update_status_overlay()
	_update_command_menu()
	_show_banner("")
	banner_panel.visible = false
	await _show_command_preview()

	await _play_events(payload.get("events", []))

	replay_button.disabled = false
	is_playing = false

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed

func _presentation_for_actor(actor_id: String, party_index: int, is_enemy: bool) -> Dictionary:
	var actors: Dictionary = presentation_data.get("actors", {})
	if actors.has(actor_id):
		return actors[actor_id]
	if is_enemy:
		return presentation_data.get("enemyDefault", {})
	var party_defaults: Array = presentation_data.get("partyDefaults", [])
	if party_defaults.is_empty():
		return {}
	return party_defaults[min(max(party_index, 0), party_defaults.size() - 1)]

func _texture_for_presentation(presentation: Dictionary, party_index: int) -> Texture2D:
	var sprite_path := str(presentation.get("spritePath", ""))
	if not sprite_path.is_empty():
		var texture := _load_texture(sprite_path)
		if texture:
			return texture

	var sprite_id := str(presentation.get("sprite", ""))
	if sprite_id == "dragon":
		return _make_dragon_texture()
	return _make_party_texture(_party_palette(party_index))

func _load_texture(path: String) -> Texture2D:
	var image := Image.new()
	if image.load(path) != OK:
		push_warning("Failed to load battle sprite: " + path)
		return null
	return ImageTexture.create_from_image(image)

func _load_textures(paths) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	if typeof(paths) != TYPE_ARRAY:
		return textures
	for path in paths:
		var texture := _load_texture(str(path))
		if texture:
			textures.append(texture)
	return textures

func _register_actor(actor: Dictionary) -> void:
	var actor_id := str(actor.get("id", ""))
	var stats: Dictionary = actor.get("stats", {})
	actor_data[actor_id] = {
		"id": actor_id,
		"name": str(actor.get("name", actor_id)),
		"teamId": str(actor.get("teamId", "")),
		"hp": int(stats.get("hp", 0)),
		"maxHp": int(stats.get("maxHp", 0)),
	}
	if str(actor.get("teamId", "")) == "enemy":
		enemy_order.append(actor_id)
	else:
		party_order.append(actor_id)

func _vector_from_array(value, fallback := Vector2.ZERO) -> Vector2:
	if typeof(value) != TYPE_ARRAY or value.size() < 2:
		return fallback
	return Vector2(float(value[0]), float(value[1]))

func _spawn_actors() -> void:
	if not enemy_order.is_empty():
		var enemy_id := enemy_order[0]
		var enemy_presentation := _presentation_for_actor(enemy_id, -1, true)
		enemy_sprite = _make_sprite(_texture_for_presentation(enemy_presentation, 0), enemy_presentation)
		enemy_sprite.name = enemy_id
		add_child(enemy_sprite)
		actor_views[enemy_id] = enemy_sprite

	for i in party_order.size():
		var actor_id := party_order[i]
		var presentation := _presentation_for_actor(actor_id, i, false)
		var sprite := _make_sprite(_texture_for_presentation(presentation, i), presentation)
		sprite.name = actor_id
		add_child(sprite)
		actor_views[actor_id] = sprite

func _make_sprite(texture: Texture2D, presentation: Dictionary) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.set_meta("base_virtual_pos", _vector_from_array(presentation.get("position", [0, 0])))
	sprite.set_meta("virtual_pos", _vector_from_array(presentation.get("position", [0, 0])))
	sprite.set_meta("virtual_size", _vector_from_array(presentation.get("size", [16, 16])))
	sprite.set_meta("foot_anchor", _vector_from_array(presentation.get("foot", [8, 16])))
	sprite.set_meta("hit_anchor", _vector_from_array(presentation.get("hit", [8, 8])))
	sprite.set_meta("cast_anchor", _vector_from_array(presentation.get("cast", [8, 8])))
	sprite.set_meta("status_offset", _vector_from_array(presentation.get("statusOffset", [20, 2])))
	sprite.set_meta("damage_offset", _vector_from_array(presentation.get("damageOffset", [-8, -10])))
	sprite.set_meta("idle_amplitude", float(presentation.get("idleAmplitude", 0.0)))
	sprite.set_meta("idle_frame_textures", _load_textures(presentation.get("idleFramePaths", [])))
	sprite.set_meta("cast_frame_textures", _load_textures(presentation.get("castFramePaths", [])))
	sprite.set_meta("hurt_frame_textures", _load_textures(presentation.get("hurtFramePaths", [])))
	sprite.set_meta("idle_frame_seconds", float(presentation.get("idleFrameSeconds", 0.45)))
	sprite.set_meta("idle_frame_index", 0)
	return sprite

func _play_events(events: Array) -> void:
	for event in events:
		var event_type := str(event.get("type", ""))
		match event_type:
			"action_start":
				await _show_action_start(event)
			"message":
				await _show_message(event)
			"damage":
				await _show_damage(event)
			"heal":
				await _show_heal(event)
			"death":
				await _show_death(event)
			"battle_end":
				_show_banner("WINNER  " + str(event.get("winnerTeamId", "")))
				await _wait(action_delay)
			_:
				await _wait(0.12)

func _show_action_start(event: Dictionary) -> void:
	var actor_id := str(event.get("actorId", ""))
	var action_id := str(event.get("actionId", ""))
	active_action_id = action_id
	menu_panel.visible = false
	_show_banner(_action_name(action_id))
	var actor = actor_views.get(actor_id)
	if actor:
		_play_temporary_frames(actor, "cast_frame_textures", 0.14)
		_show_cast_effect(actor)
		await _step_actor(actor)
	else:
		await _wait(action_delay)

func _show_message(event: Dictionary) -> void:
	var text_key := str(event.get("textKey", ""))
	_show_banner(_message_name(text_key))
	await _wait(action_delay)

func _show_damage(event: Dictionary) -> void:
	var target_id := str(event.get("targetId", ""))
	var amount := int(event.get("amount", 0))
	var target = actor_views.get(target_id)
	if target:
		_play_temporary_frames(target, "hurt_frame_textures", 0.18)
		_flash_target(target)
		_shake_target(target)
		_show_hit_effect(target, _active_effect(str(event.get("damageType", ""))))
		_show_floating_number(amount, _actor_anchor(target, "hit_anchor") + _meta_vector(target, "damage_offset"), false)

	var data: Dictionary = actor_data.get(target_id, {})
	if not data.is_empty():
		data["hp"] = int(event.get("hpAfter", 0))
		actor_data[target_id] = data
		_update_status_overlay()

	await _wait(damage_delay)

func _show_heal(event: Dictionary) -> void:
	var target_id := str(event.get("targetId", ""))
	var amount := int(event.get("amount", 0))
	var target = actor_views.get(target_id)
	if target:
		_show_heal_effect(target)
		_show_floating_number(amount, _actor_anchor(target, "hit_anchor") + _meta_vector(target, "damage_offset"), true)

	var data: Dictionary = actor_data.get(target_id, {})
	if not data.is_empty():
		data["hp"] = int(event.get("hpAfter", 0))
		actor_data[target_id] = data
		_update_status_overlay()

	await _wait(damage_delay)

func _show_death(event: Dictionary) -> void:
	var target = actor_views.get(str(event.get("targetId", "")))
	if target:
		var tween := create_tween()
		tween.tween_property(target, "modulate", Color(0.25, 0.25, 0.25, 0.75), 0.18)
		tween.tween_property(target, "modulate:a", 0.0, 0.35)
		await tween.finished

func _step_actor(actor: CanvasItem) -> void:
	var base: Vector2 = actor.position
	var offset := Vector2(-12, 0)
	if str(actor.name) in enemy_order:
		offset = Vector2(10, 0)
	var tween := create_tween()
	tween.tween_property(actor, "position", base + offset * scale_factor, 0.12)
	tween.tween_property(actor, "position", base, 0.18)
	await tween.finished

func _flash_target(target: CanvasItem) -> void:
	var tween := create_tween()
	tween.tween_property(target, "modulate", Color(1.0, 1.0, 1.0, 0.35), 0.06)
	tween.tween_property(target, "modulate", Color(1.0, 0.45, 0.38, 1.0), 0.08)
	tween.tween_property(target, "modulate", Color.WHITE, 0.12)

func _shake_target(target: CanvasItem) -> void:
	var base: Vector2 = target.position
	var tween := create_tween()
	tween.tween_property(target, "position", base + Vector2(-3, 0) * scale_factor, 0.04)
	tween.tween_property(target, "position", base + Vector2(3, 0) * scale_factor, 0.04)
	tween.tween_property(target, "position", base, 0.06)

func _show_cast_effect(actor: TextureRect) -> void:
	var center := _to_screen(_actor_anchor(actor, "cast_anchor"))
	for i in 4:
		var spark := ColorRect.new()
		spark.color = Color(0.75, 0.95, 1.0, 0.95)
		spark.size = Vector2(2, 2) * scale_factor
		spark.position = center + Vector2(i % 2 - 0.5, i / 2 - 0.5) * 6.0 * scale_factor
		effects_layer.add_child(spark)
		var tween := create_tween()
		tween.tween_property(spark, "position", spark.position + Vector2(-8 - i * 2, -5 + i * 3) * scale_factor, 0.24)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.24)
		tween.tween_callback(spark.queue_free)

func _show_hit_effect(target: TextureRect, damage_type: String) -> void:
	var center := _to_screen(_actor_anchor(target, "hit_anchor"))
	if damage_type == "magic" or damage_type == "fire":
		for i in 5:
			var ember := ColorRect.new()
			ember.color = Color(1.0, 0.42 + i * 0.08, 0.08, 0.95)
			ember.size = Vector2(3, 3) * scale_factor
			ember.position = center + Vector2(-8 + i * 4, 0) * scale_factor
			effects_layer.add_child(ember)
			var tween := create_tween()
			tween.tween_property(ember, "position", ember.position + Vector2(-4 + i * 2, -18) * scale_factor, 0.28)
			tween.parallel().tween_property(ember, "modulate:a", 0.0, 0.28)
			tween.tween_callback(ember.queue_free)
	else:
		var slash := ColorRect.new()
		slash.color = Color.WHITE
		slash.size = Vector2(28, 3) * scale_factor
		slash.rotation_degrees = -25
		slash.position = center + Vector2(-14, -2) * scale_factor
		effects_layer.add_child(slash)
		var tween := create_tween()
		tween.tween_property(slash, "modulate:a", 0.0, 0.18)
		tween.tween_callback(slash.queue_free)

func _show_heal_effect(target: TextureRect) -> void:
	var center := _to_screen(_actor_anchor(target, "hit_anchor"))
	for i in 4:
		var mote := ColorRect.new()
		mote.color = Color(0.55, 1.0, 0.72, 0.95)
		mote.size = Vector2(2, 4) * scale_factor
		mote.position = center + Vector2(-6 + i * 4, 6) * scale_factor
		effects_layer.add_child(mote)
		var tween := create_tween()
		tween.tween_property(mote, "position", mote.position + Vector2(0, -18 - i * 2) * scale_factor, 0.36)
		tween.parallel().tween_property(mote, "modulate:a", 0.0, 0.36)
		tween.tween_callback(mote.queue_free)

func _show_floating_number(amount: int, virtual_pos: Vector2, is_heal: bool) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", int(18 * scale_factor))
	label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.72, 1.0) if is_heal else Color.WHITE)
	label.add_theme_constant_override("outline_size", max(2, int(2 * scale_factor)))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.position = _to_screen(virtual_pos + Vector2(-8, -8))
	effects_layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -22) * scale_factor, 0.48)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.48)
	tween.tween_callback(label.queue_free)

func _show_banner(text: String) -> void:
	banner_label.text = text
	banner_panel.visible = not text.is_empty()

func _active_effect(fallback: String) -> String:
	var actions: Dictionary = action_presentation_data.get("actions", {})
	var action: Dictionary = actions.get(active_action_id, {})
	return str(action.get("effect", fallback))

func _show_command_preview() -> void:
	if menu_label.text.is_empty():
		return
	menu_panel.visible = true
	await _wait(float(action_presentation_data.get("commandPreviewSeconds", 0.65)))

func _update_command_menu() -> void:
	var actor_id := str(action_presentation_data.get("commandPreviewActorId", ""))
	var actor: Dictionary = actor_data.get(actor_id, {})
	var header := str(actor.get("name", actor_id))
	var rows: Array[String] = [header]
	for command in action_presentation_data.get("commands", []):
		if typeof(command) != TYPE_DICTIONARY:
			continue
		var pointer := ">" if bool(command.get("selected", false)) else " "
		var label := str(command.get("label", command.get("actionId", "")))
		var cost := int(command.get("cost", 0))
		rows.append("%s %-8s %3d" % [pointer, label, cost])
	menu_label.text = "\n".join(rows)

func _action_name(action_id: String) -> String:
	var actions: Dictionary = action_presentation_data.get("actions", {})
	var action: Dictionary = actions.get(action_id, {})
	return str(action.get("label", action_id))

func _message_name(text_key: String) -> String:
	var messages: Dictionary = action_presentation_data.get("messages", {})
	return str(messages.get(text_key, text_key))

func _update_status_overlay() -> void:
	for child in status_layer.get_children():
		child.queue_free()

	for i in party_order.size():
		var actor_id := party_order[i]
		var data: Dictionary = actor_data.get(actor_id, {})
		if data.is_empty():
			continue
		var label := Label.new()
		label.text = "%s\n%03d/%03d" % [data.get("name", actor_id), int(data.get("hp", 0)), int(data.get("maxHp", 0))]
		label.add_theme_font_size_override("font_size", int(10 * scale_factor))
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_constant_override("outline_size", max(2, int(2 * scale_factor)))
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		var actor: TextureRect = actor_views.get(actor_id)
		if actor:
			label.position = _to_screen(_meta_vector(actor, "base_virtual_pos") + _meta_vector(actor, "status_offset"))
		status_layer.add_child(label)

func _clear_battle() -> void:
	for idle_tween in idle_tweens:
		if idle_tween:
			idle_tween.kill()
	idle_tweens.clear()
	for idle_timer in idle_timers:
		if idle_timer:
			idle_timer.queue_free()
	idle_timers.clear()
	actor_views.clear()
	actor_data.clear()
	party_order.clear()
	enemy_order.clear()

	for child in get_children():
		if child == status_layer or child == effects_layer or child == banner_panel or child == menu_panel or child == replay_button:
			continue
		child.queue_free()
	for child in status_layer.get_children():
		child.queue_free()
	for child in effects_layer.get_children():
		child.queue_free()

func _update_layout() -> void:
	if status_layer == null or effects_layer == null or banner_panel == null or menu_panel == null or replay_button == null:
		return
	var available := size
	if available.x <= 0 or available.y <= 0:
		return
	scale_factor = floor(min(available.x / VIRTUAL_SIZE.x, available.y / VIRTUAL_SIZE.y))
	scale_factor = max(scale_factor, 1.0)
	origin = (available - VIRTUAL_SIZE * scale_factor) * 0.5

	status_layer.position = Vector2.ZERO
	status_layer.size = size
	effects_layer.position = Vector2.ZERO
	effects_layer.size = size

	banner_panel.position = _to_screen(Vector2(184, 22))
	banner_panel.size = Vector2(104, 28) * scale_factor
	menu_panel.position = _to_screen(Vector2(32, 48))
	menu_panel.size = Vector2(132, 80) * scale_factor
	replay_button.position = Vector2(12, 12)
	replay_button.size = Vector2(76, 28)

	for actor_id in actor_views.keys():
		var actor: TextureRect = actor_views[actor_id]
		var virtual_pos: Vector2 = actor.get_meta("virtual_pos")
		var virtual_size: Vector2 = actor.get_meta("virtual_size")
		actor.position = _to_screen(virtual_pos)
		actor.size = virtual_size * scale_factor

	_update_status_overlay()

func _to_screen(virtual_pos: Vector2) -> Vector2:
	return origin + virtual_pos * scale_factor

func _meta_vector(actor: TextureRect, key: String) -> Vector2:
	if not actor.has_meta(key):
		return Vector2.ZERO
	return actor.get_meta(key)

func _actor_anchor(actor: TextureRect, key: String) -> Vector2:
	return _meta_vector(actor, "virtual_pos") + _meta_vector(actor, key)

func _start_idle(actor: TextureRect) -> void:
	var amplitude := float(actor.get_meta("idle_amplitude"))
	if amplitude > 0.0:
		var base_pos: Vector2 = actor.position
		var tween := create_tween()
		tween.set_loops()
		tween.tween_property(actor, "position", base_pos + Vector2(0, -amplitude) * scale_factor, 0.8)
		tween.tween_property(actor, "position", base_pos, 0.8)
		idle_tweens.append(tween)

	var frames: Array[Texture2D] = actor.get_meta("idle_frame_textures")
	if frames.size() < 2:
		return
	actor.texture = frames[0]
	var timer := Timer.new()
	timer.wait_time = max(0.08, float(actor.get_meta("idle_frame_seconds")))
	timer.timeout.connect(_advance_idle_frame.bind(actor))
	add_child(timer)
	timer.start()
	idle_timers.append(timer)

func _advance_idle_frame(actor: TextureRect) -> void:
	if not is_instance_valid(actor):
		return
	var frames: Array[Texture2D] = actor.get_meta("idle_frame_textures")
	if frames.is_empty():
		return
	var next_index := (int(actor.get_meta("idle_frame_index")) + 1) % frames.size()
	actor.set_meta("idle_frame_index", next_index)
	actor.texture = frames[next_index]

func _play_temporary_frames(actor: TextureRect, meta_key: String, frame_seconds: float) -> void:
	var frames: Array[Texture2D] = actor.get_meta(meta_key)
	if frames.is_empty():
		return
	var idle_frames: Array[Texture2D] = actor.get_meta("idle_frame_textures")
	var sequence := create_tween()
	for frame in frames:
		sequence.tween_callback(func() -> void:
			if is_instance_valid(actor):
				actor.texture = frame
		)
		sequence.tween_interval(frame_seconds)
	sequence.tween_callback(func() -> void:
		if not is_instance_valid(actor) or idle_frames.is_empty():
			return
		var idle_index := int(actor.get_meta("idle_frame_index")) % idle_frames.size()
		actor.texture = idle_frames[idle_index]
	)

func _start_idle_for_all_actors() -> void:
	for idle_tween in idle_tweens:
		if idle_tween:
			idle_tween.kill()
	idle_tweens.clear()
	for idle_timer in idle_timers:
		if idle_timer:
			idle_timer.queue_free()
	idle_timers.clear()
	for actor_id in actor_views.keys():
		_start_idle(actor_views[actor_id])

func _draw_frame() -> void:
	draw_rect(Rect2(origin - Vector2(3, 3) * scale_factor, VIRTUAL_SIZE * scale_factor + Vector2(6, 6) * scale_factor), Color(0.02, 0.02, 0.05, 1.0))
	draw_rect(Rect2(origin, VIRTUAL_SIZE * scale_factor), Color(0.68, 0.84, 0.96, 1.0))

func _draw_sky() -> void:
	draw_rect(Rect2(_to_screen(Vector2.ZERO), Vector2(VIRTUAL_SIZE.x, 58) * scale_factor), Color(0.58, 0.79, 0.95, 1.0))
	for x in [10, 74, 150, 230, 286]:
		_draw_cloud(Vector2(x, 34))

func _draw_cloud(pos: Vector2) -> void:
	var color := Color(0.82, 0.96, 0.98, 0.95)
	for rect in [
		Rect2(pos, Vector2(26, 3)),
		Rect2(pos + Vector2(8, -3), Vector2(18, 3)),
		Rect2(pos + Vector2(20, 4), Vector2(18, 3)),
	]:
		draw_rect(Rect2(_to_screen(rect.position), rect.size * scale_factor), color)

func _draw_stone_floor() -> void:
	draw_rect(Rect2(_to_screen(Vector2(0, 58)), Vector2(320, 166) * scale_factor), Color(0.47, 0.46, 0.43, 1.0))
	var dark := Color(0.30, 0.30, 0.30, 1.0)
	var light := Color(0.58, 0.57, 0.53, 1.0)
	for y in range(58, 224, 10):
		for x in range(-8, 328, 16):
			var offset := 8 if int((y - 58) / 10) % 2 == 0 else 0
			var px := x + offset
			draw_rect(Rect2(_to_screen(Vector2(px, y)), Vector2(12, 8) * scale_factor), light)
			draw_rect(Rect2(_to_screen(Vector2(px, y)), Vector2(12, 1) * scale_factor), dark)
			draw_rect(Rect2(_to_screen(Vector2(px, y)), Vector2(1, 8) * scale_factor), dark)

func _make_panel(fill_color: Color, border_color: Color, corner_radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _party_palette(index: int) -> Array:
	var palettes := [
		[Color(0.93, 0.86, 0.55), Color(0.25, 0.75, 0.42), Color(0.48, 0.30, 0.18)],
		[Color(0.72, 0.82, 1.0), Color(0.22, 0.42, 0.85), Color(0.42, 0.26, 0.16)],
		[Color(1.0, 0.78, 0.88), Color(0.86, 0.28, 0.48), Color(0.34, 0.18, 0.42)],
		[Color(0.82, 1.0, 0.82), Color(0.1, 0.62, 0.48), Color(0.94, 0.74, 0.45)],
		[Color(1.0, 0.72, 0.58), Color(0.82, 0.34, 0.22), Color(0.50, 0.24, 0.14)],
	]
	return palettes[index % palettes.size()]

func _make_party_texture(palette: Array) -> Texture2D:
	var img := Image.create(22, 30, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var skin := Color(0.98, 0.78, 0.56, 1.0)
	var hair: Color = palette[2]
	var cloth: Color = palette[1]
	var trim: Color = palette[0]
	var shadow := Color(0.08, 0.08, 0.09, 1.0)
	_rect(img, 7, 3, 8, 4, hair)
	_rect(img, 6, 7, 10, 6, skin)
	_rect(img, 5, 9, 3, 6, hair)
	_rect(img, 14, 9, 3, 6, hair)
	_rect(img, 7, 14, 8, 8, cloth)
	_rect(img, 5, 15, 3, 6, trim)
	_rect(img, 14, 15, 3, 6, trim)
	_rect(img, 8, 22, 3, 5, cloth)
	_rect(img, 13, 22, 3, 5, cloth)
	_rect(img, 6, 27, 5, 2, shadow)
	_rect(img, 12, 27, 5, 2, shadow)
	_outline_alpha(img, shadow)
	return ImageTexture.create_from_image(img)

func _make_dragon_texture() -> Texture2D:
	var img := Image.create(110, 88, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var gold := Color(0.94, 0.58, 0.12, 1.0)
	var gold_light := Color(1.0, 0.82, 0.24, 1.0)
	var gold_dark := Color(0.48, 0.27, 0.11, 1.0)
	var wing := Color(0.60, 0.43, 0.30, 0.95)
	var horn := Color(0.95, 0.95, 0.90, 1.0)
	var mouth := Color(0.55, 0.08, 0.05, 1.0)
	var black := Color(0.05, 0.04, 0.04, 1.0)

	_rect(img, 18, 12, 30, 24, wing)
	_rect(img, 44, 10, 36, 28, wing)
	_rect(img, 24, 35, 54, 24, gold)
	_rect(img, 10, 48, 32, 22, gold)
	_rect(img, 5, 56, 18, 12, gold_light)
	_rect(img, 36, 28, 38, 16, gold_light)
	_rect(img, 64, 44, 34, 24, gold)
	_rect(img, 76, 58, 24, 12, mouth)
	_rect(img, 78, 68, 22, 4, horn)
	_rect(img, 4, 34, 10, 24, gold)
	_rect(img, 0, 28, 8, 20, horn)
	_rect(img, 83, 38, 12, 12, horn)
	_rect(img, 94, 36, 10, 8, horn)
	_rect(img, 72, 28, 14, 16, gold_light)
	_rect(img, 36, 58, 9, 18, gold_dark)
	_rect(img, 54, 58, 9, 18, gold_dark)
	_rect(img, 26, 72, 14, 6, horn)
	_rect(img, 52, 74, 14, 6, horn)
	_rect(img, 85, 59, 4, 4, black)
	_rect(img, 78, 63, 22, 2, horn)
	_outline_alpha(img, black)
	return ImageTexture.create_from_image(img)

func _rect(img: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(max(0, y), min(img.get_height(), y + height)):
		for px in range(max(0, x), min(img.get_width(), x + width)):
			img.set_pixel(px, py, color)

func _outline_alpha(img: Image, color: Color) -> void:
	var points: Array[Vector2i] = []
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					var p: Vector2i = Vector2i(x, y) + offset
					if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
						if img.get_pixel(p.x, p.y).a == 0.0:
							points.append(p)
	for point in points:
		img.set_pixel(point.x, point.y, color)

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
