extends NinePatchRect
class_name AbilityIcon

@onready var mark = $ColorRect
@onready var tex = $TextureRect
@export var ability : Ability

var base_color = 0.8313725490196078
var base_size = 240

func set_sprite(texture : CompressedTexture2D):
	if not tex:
		tex = $TextureRect
	tex.texture = texture

func onSelect():
	mark.color.a = 1
	print("made mark visible")


func offSelect():
	mark.color.a = 0
	print("goodbye mark")
