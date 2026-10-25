extends Label
@onready var playmanger=$"../../play"
@onready var strongmanger=$"../../存储"

var refresh_timer:float = 0.0
const REFRESH_INTERVAL:float = 0.05
var bpm_track:PackedFloat32Array = PackedFloat32Array()

func cache_bpm_track():
	if strongmanger.adofai_data.has("tracks") and strongmanger.adofai_data.tracks.size() > 1:
		bpm_track = strongmanger.adofai_data.tracks[1]
	else:
		bpm_track = PackedFloat32Array()

func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer < REFRESH_INTERVAL:
		return
	refresh_timer = 0.0

	var ballpos = playmanger.get("ballpos")
	var times_arr = playmanger.get("times")
	var total = times_arr.size() - 1
	var percent = round((ballpos / float(total))*10000.0)/100.0

	var bpm = 0.0
	# 数组下标判断，防止越界
	if ballpos >= 0 and ballpos < bpm_track.size():
		bpm = bpm_track[ballpos]

	text = "Fps|%d/%.2fms\n" % [int(round(1/delta)),delta*1000]
	text += "tile|%d/%d/%s%%\n" % [ballpos, total, str(percent)]
	text += "bpm|%s\n" % str(bpm)
