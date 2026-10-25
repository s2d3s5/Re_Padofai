extends Button

var is_full=false
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
func _pressed() -> void:
	if is_full:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		is_full=false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		is_full=true
