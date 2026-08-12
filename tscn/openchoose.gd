extends Button
func _ready() -> void:
	$"../../file_path".text=$"../../../../../../存储".adofai_path
	$FileDialog.current_path=$"../../../../../../存储".adofai_path

func _on_pressed() -> void:
	$FileDialog.current_path=$"../../../../../../存储".adofai_path
	$FileDialog.show()
func _on_file_dialog_file_selected(path: String) -> void:
	$"../../../../../../存储".adofai_path=path
	$"../../file_path".text=path
