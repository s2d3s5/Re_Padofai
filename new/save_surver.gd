extends Node
class_name SaveSurver
enum doings
{
	Play,None
}
var doing:doings=doings.None

static var adofai_load_path_string:String="C:/chaochao/puzi1111111111111/STAY/The Kid LAROI、Justin Bieber - STAY (Explicit).adofai"

func _ready() -> void:
	if !OS.has_feature("standalone"):
		print("当前目录：",adofai_load_path_string)
	pass

func _on_file_dialog_file_selected(path: String) -> void:
	adofai_load_path_string=path
	print("打开成功：",path)
