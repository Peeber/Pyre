extends Node

var enemies : Array[Enemy]

func spawn(enemy_name : String, pos : Vector2):
	enemy_name = enemy_name.to_lower()
	var enemy = load("res://enemies/" + enemy_name + ".tscn").instantiate()
	print(enemy.name)
	if not enemy:
		print("no enemy found for name " + enemy_name + ", make sure the scene isnt capitalized")
		return null
	
	var scene_change = get_node("/root/scene_change")
	print(scene_change.name)
	if not scene_change:
		print("couldn't get scene change???")
		return null
	
	
	var map = Globals.find_by_type(scene_change,TileMap)
	print(map.name)
	if not map:
		print("no tilemap found under scene_change")
		return null
	
	map.add_child(enemy)
	print("added enemy as child of tilemap")
	enemy.position = pos
	print("moved enemy to ",pos)
	
	print("successfully spawned " + enemy.name)
	enemies.append(enemy)
	return enemy

func remove(enemy : Enemy):
	var index = enemies.find(enemy)
	if index >= 0:
		enemies.remove_at(index)
		enemy.queue_free()
