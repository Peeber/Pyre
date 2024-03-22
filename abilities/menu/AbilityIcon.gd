extends NinePatchRect
class_name AbilityIcon

@onready var mark = $ColorRect
@onready var tex = $TextureRect
@export var ability : Ability

var on_color = Color.hex(0xd4d4d4)
var off_color = Color.hex(0xd4d4d400)

var base_size = 240

func set_sprite(new_texture : CompressedTexture2D):
	if not tex:
		tex = $TextureRect
	tex.texture = new_texture

func onSelect():
	mark.color = on_color
	print("made mark visible")


func offSelect():
	mark.color = off_color
	print("goodbye mark")
