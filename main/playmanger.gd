extends Node
var ballpos=0
var doing="none"
var muice_node
var times:Array=[0.0]
var cutting_time=0.0
var offest
var f_bpm


func _ready() -> void:
	ballpos=0
	muice_node=$muice
signal place_tile()
signal start_to_play()

func _on_play_pressed() -> void:
	re_time()
	ballpos=0
	doing="play"
	var adofai_data=$"../存储".adofai_data
	if adofai_data!={}:
		times=adofai_data.times
		muice_node.stream=adofai_data.audio
		offest=adofai_data.setting.offset/1000.0
		f_bpm=adofai_data.setting.bpm
		emit_signal("place_tile")
		emit_signal("start_to_play")
		$muice.play()

func re_time()->void:
	cutting_time=Time.get_unix_time_from_system()

func get_time()->float:
	if muice_node.playing:
		return muice_node.get_playback_position()
	else:
		return Time.get_unix_time_from_system()-cutting_time


func _on_start_to_play() -> void:
	if doing=="play":
		while ballpos<times.size()-1 and doing=="play":
			while ballpos<times.size()-1 and get_time()>=times[ballpos+1]+offest-60/f_bpm:
				ballpos+=1
				$hit.play()
			await get_tree().process_frame
