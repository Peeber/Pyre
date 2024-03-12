extends Node

signal healthChanged(target,hp,isMax)
signal dialogueBegan()
signal dialogueEnded()
signal sceneChanged(next_world_name: String)
signal teleportedTo(position)
signal addedAbility(name: String)
signal changedAbility(name: String, old: String)
signal askedForAbility(name: String)
signal emberChanged(value : int)
signal openedAbilityMenu()
signal closedAbilityMenu()
signal focusChanged(value)
signal focusSpeedChanged(focus_tick)
signal abilitiesToggled(is_allowed : bool)
signal arenaModeSet(is_active)
signal abilityEnded()
signal abilityCast(ability : Ability,position)
