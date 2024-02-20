extends Node

signal healthChanged(target,hp,isMax)
signal dialogueBegan()
signal dialogueEnded()
signal sceneChanged(next_world_name: String)
signal teleportedTo(position)
signal addedAbility(name: String)
signal changedAbility(name: String, old: String)
