extends PanelContainer

var actor_id: String = ""
var max_hp: int = 0

@onready var name_label: Label = $ActorMargin/ActorBody/NameLabel
@onready var hp_bar: ProgressBar = $ActorMargin/ActorBody/HpRow/HpBar
@onready var hp_value: Label = $ActorMargin/ActorBody/HpRow/HpValue
@onready var status_label: Label = $ActorMargin/ActorBody/StatusLabel

func configure(actor: Dictionary) -> void:
	actor_id = str(actor.get("id", ""))
	var stats: Dictionary = actor.get("stats", {})
	max_hp = int(stats.get("maxHp", 0))
	name_label.text = str(actor.get("name", actor_id))
	hp_bar.max_value = max_hp
	set_hp(int(stats.get("hp", 0)))
	set_statuses(actor.get("statusIds", []))

func set_hp(value: int) -> void:
	hp_bar.value = clampi(value, 0, max_hp)
	hp_value.text = "%d/%d" % [int(hp_bar.value), max_hp]

func set_statuses(status_ids: Array) -> void:
	if status_ids.is_empty():
		status_label.text = ""
	else:
		status_label.text = "Status: " + ", ".join(status_ids)

func set_defeated() -> void:
	modulate = Color(0.45, 0.45, 0.45, 1.0)
	status_label.text = "Defeated"

func flash_hit(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 0.45, 0.45, 1.0), duration * 0.35)
	tween.tween_property(self, "modulate", Color.WHITE, duration * 0.65)
