extends Control

@export_file("*.json") var sample_path := "res://samples/basic-turn-result.json"
@export var event_delay := 0.35
@export var damage_delay := 0.45
@export var flash_duration := 0.18

@onready var replay_button: Button = $Root/TopBar/ReplayButton
@onready var party_views: VBoxContainer = $Root/Content/Arena/ArenaMargin/ArenaBody/PartyViews
@onready var enemy_views: VBoxContainer = $Root/Content/Arena/ArenaMargin/ArenaBody/EnemyViews
@onready var event_log: RichTextLabel = $Root/Content/Inspector/InspectorMargin/InspectorBody/EventLog
@onready var message_window = $Root/MessageWindow
@onready var actor_template: PanelContainer = $ActorViewTemplate

var actor_views: Dictionary = {}
var is_playing := false

func _ready() -> void:
	replay_button.pressed.connect(replay)
	replay()

func replay() -> void:
	if is_playing:
		return
	_play_sample()

func _play_sample() -> void:
	is_playing = true
	replay_button.disabled = true
	_clear_views()

	var payload := _load_json(sample_path)
	if payload.is_empty():
		message_window.show_text("Failed to load sample: " + sample_path)
		is_playing = false
		replay_button.disabled = false
		return

	for actor in payload.get("finalState", {}).get("actors", []):
		_spawn_actor_view(actor)

	# Reset views to initial state when the sample embeds events with hpBefore.
	for event in payload.get("events", []):
		if event.get("type") == "damage" or event.get("type") == "heal":
			var view = actor_views.get(str(event.get("targetId", "")))
			if view:
				view.set_hp(int(event.get("hpBefore", 0)))

	message_window.clear()
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

func _clear_views() -> void:
	actor_views.clear()
	event_log.clear()
	for child in party_views.get_children():
		child.queue_free()
	for child in enemy_views.get_children():
		child.queue_free()

func _spawn_actor_view(actor: Dictionary) -> void:
	var view := actor_template.duplicate()
	view.visible = true
	var team_id := str(actor.get("teamId", ""))
	if team_id == "enemy":
		enemy_views.add_child(view)
	else:
		party_views.add_child(view)
	view.configure(actor)
	actor_views[str(actor.get("id", ""))] = view

func _play_events(events: Array) -> void:
	for event in events:
		var event_type := str(event.get("type", ""))
		_log_event(event)
		match event_type:
			"turn_start":
				message_window.show_text("Turn %d" % int(event.get("turnNumber", 0)))
				await _wait(event_delay)
			"action_start":
				message_window.show_text("%s acts." % str(event.get("actorId", "")))
				await _wait(event_delay)
			"message":
				message_window.show_text(_format_message(event))
				await _wait(event_delay)
			"damage":
				await _show_damage(event)
			"heal":
				await _show_heal(event)
			"death":
				_show_death(event)
				await _wait(event_delay)
			"battle_end":
				message_window.show_text("Winner: " + str(event.get("winnerTeamId", "")))
				await _wait(event_delay)
			"turn_end":
				await _wait(event_delay)
			_:
				await _wait(event_delay)

func _show_damage(event: Dictionary) -> void:
	var target_id := str(event.get("targetId", ""))
	var view = actor_views.get(target_id)
	if view:
		view.flash_hit(flash_duration)
		view.set_hp(int(event.get("hpAfter", 0)))
	message_window.show_text("%s takes %d damage." % [target_id, int(event.get("amount", 0))])
	await _wait(damage_delay)

func _show_heal(event: Dictionary) -> void:
	var target_id := str(event.get("targetId", ""))
	var view = actor_views.get(target_id)
	if view:
		view.set_hp(int(event.get("hpAfter", 0)))
	message_window.show_text("%s recovers %d HP." % [target_id, int(event.get("amount", 0))])
	await _wait(damage_delay)

func _show_death(event: Dictionary) -> void:
	var view = actor_views.get(str(event.get("targetId", "")))
	if view:
		view.set_defeated()

func _format_message(event: Dictionary) -> String:
	var text_key := str(event.get("textKey", ""))
	var params: Dictionary = event.get("params", {})
	var actor_name := str(params.get("actor", "")) if typeof(params) == TYPE_DICTIONARY else ""
	match text_key:
		"action.attack":
			return actor_name + " attacks."
		"action.fire":
			return actor_name + " casts Fire."
		"action.cure":
			return actor_name + " casts Cure."
		"action.poison_sting":
			return actor_name + " uses Poison Sting."
		_:
			return text_key

func _log_event(event: Dictionary) -> void:
	event_log.append_text("[color=#8fd7ff]%s[/color] %s\n" % [str(event.get("type", "")), JSON.stringify(event)])

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
