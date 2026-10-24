extends Label
@onready var playmanger=$"../../play"
@onready var tilemanger=$"../../play/tiles"
func _process(delta: float) -> void:
	text=""
	text=str(text,"Fps|",int(round((1/delta))),"\n")
	text=str(text,"tile|",playmanger.get("ballpos"),"/",playmanger.get("times").size()-1,"/",int(playmanger.get("ballpos")/float(playmanger.get("times").size()-1)*10000.0)/100.0,"%\n")
	if tilemanger.tracks.size()>0:
		var track=tilemanger.tracks.get(playmanger.get("ballpos"))
		text=str(text,"bpm|",track.get("bpm"),"\n")
	else:
		text=str(text,"bpm|",0.0,"\n")
