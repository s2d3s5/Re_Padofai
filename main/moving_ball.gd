extends MeshInstance2D
var is_ice=get_meta("is_ice",false)
var times:PackedFloat32Array
var angle_data:PackedFloat32Array

var track_pos:PackedVector2Array = PackedVector2Array()
var track_way:PackedByteArray = PackedByteArray()
var track_bpm:PackedFloat32Array = PackedFloat32Array()


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
		if track_pos.size()>0:
			if (ball_pos%2==0)==is_ice:
				var way=float(0.0-(angle_data[ball_pos]))-((((play_manger.get_time()-times[clampi(ball_pos+1,0,times.size()-1)]-play_manger.offest)*-180)*track_bpm[ball_pos]/60))*(track_way[ball_pos]*2-1)
				way=deg_to_rad(way)
				position=Vector2(cos(way)*90,sin(way)*90)+track_pos[ball_pos]
			else:
				position=track_pos[ball_pos]
	else:
		visible=false
func _on_play_start_to_play() -> void:
	show()
	times=$"../../存储".adofai_data.times
	angle_data=$"../../存储".adofai_data.angledata
	track_pos=$"../../存储".adofai_data.tracks[0]
	track_way=$"../../存储".adofai_data.tracks[3]
	track_bpm=$"../../存储".adofai_data.tracks[1]
	set_deferred("process_mode",PROCESS_MODE_INHERIT)
