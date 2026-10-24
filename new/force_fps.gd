extends Timer

func _ready() -> void:
	force_fps_on(30)

func force_fps_on(fps:float=10,enabled:bool=false)->void:
	RenderingServer.render_loop_enabled=enabled
	wait_time=1/fps
	start()

func _on_timeout() -> void:
	if !RenderingServer.render_loop_enabled:
		RenderingServer.force_draw()
