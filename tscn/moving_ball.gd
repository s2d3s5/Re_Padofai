extends MeshInstance2D
var is_ice=get_meta("is_ice",false)
var times:Array
var angle_data:Array
var tracks:Array
@onready var play_manger=$".."
@export var a=0.0
func _ready() -> void:
	hide()
	if name=="blue":
		is_ice=true
	position=Vector2.ZERO
	set_deferred("process_mode",PROCESS_MODE_DISABLED)
func _process(_delta: float) -> void:
	if play_manger.get("doing")=="play":
		var ball_pos=play_manger.ballpos
		if tracks.size()>0:
			var tile:Track=tracks.get(ball_pos)
			if (ball_pos%2==0)==is_ice:
				var way=float(0.0-(angle_data[ball_pos]))-((((play_manger.get_time()-times[clampi(ball_pos+1,0,times.size()-1)]-play_manger.offest)*-180)*tile.bpm/60))*tile.way
				way=deg_to_rad(way)
				position=Vector2(cos(way)*90,sin(way)*90)+tile.pos
			else:
				position=tile.pos
	else:
		visible=false
func _on_play_start_to_play() -> void:
	show()
	times=$"../../存储".adofai_data.times
	angle_data=$"../../存储".adofai_data.angledata
	tracks=$"../../存储".adofai_data.tracks
	set_deferred("process_mode",PROCESS_MODE_INHERIT)
