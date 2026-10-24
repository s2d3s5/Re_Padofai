extends Button


func _pressed() -> void:
	var windo=Window.new()
	var packeds=preload("uid://dcw0deo7siu0j")
	$".".add_child(windo)
	windo.size=Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"),ProjectSettings.get_setting("display/window/size/viewport_height"))
	windo.position=Vector2i(200,200)
	
	windo.add_child(packeds.instantiate())
