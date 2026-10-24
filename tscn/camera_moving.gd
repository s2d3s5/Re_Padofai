extends Camera2D
var relative_to="player"
var is_play=false
var cutting_time=0
var cuttingpos=Vector2(0,0)
@onready var play_manger=$".."
var tracks

func _on_play_start_to_play() -> void:
	if !is_play:
		is_play=true
		tracks=$"../../存储".adofai_data.tracks
		while play_manger.doing=="play":
			var ball_pos=play_manger.ballpos
			var target_pos=tracks[ball_pos].pos
			inverse_add_follow(target_pos)
			if Input.is_action_just_pressed("zoom_in"):
				zoom*=1.2
			elif Input.is_action_just_pressed("zoom_out"):
				zoom/=1.2
				
			await get_tree().process_frame
		is_play=false
func inverse_add_follow(player_pos:Vector2) -> void:
	var ball_pos = play_manger.ballpos
	var current_time = play_manger.get_time()
	var duration = 120.0 / tracks[ball_pos].bpm
	var t = current_time - cutting_time
	var x = map_range_clamp(t, 0.0, duration, cuttingpos.x, player_pos.x)
	var y = map_range_clamp(t, 0.0, duration, cuttingpos.y, player_pos.y)
	position = Vector2(x, y)

# 线性映射
func map_range(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	var t_normal = (value - in_min) / (in_max - in_min)
	return t_normal * (out_max - out_min) + out_min

# 映射 + 范围锁定（万能，out_min/out_max顺序随便传）
func map_range_clamp(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	var res = map_range(value, in_min, in_max, out_min, out_max)
	var low = min(out_min, out_max)
	var high = max(out_min, out_max)
	return clamp(res, low, high)

func _on_play_ball_hitting(ball_pos) -> void:
	cutting_time=play_manger.times[ball_pos]+play_manger.offest
	cuttingpos=position


func _on_play_pressed() -> void:
	#每次按开始怎么都回不来😡
	zoom=Vector2.ONE
	set_deferred("position",Vector2.ZERO)


			
			
