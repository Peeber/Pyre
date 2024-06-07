extends Area2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func action() -> void:
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
	State.latest_actionable_target = get_parent()
