extends PanelContainer

@onready var message_label: Label = $MessageMargin/MessageLabel

func show_text(text: String) -> void:
	message_label.text = text

func clear() -> void:
	message_label.text = ""
