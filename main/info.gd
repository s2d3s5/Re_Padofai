extends Label
@onready var playmanger=$"../../play"
@onready var strongmanger=$"../../存储"
func _process(delta: float) -> void:
	text=""
	text=str(text,"Fps|",int(round((1/delta))),"\n")
	text=str(text,"tile|",playmanger.get("ballpos"),"/",playmanger.get("times").size()-1,"/",int(playmanger.get("ballpos")/float(playmanger.get("times").size()-1)*10000.0)/100.0,"%\n")
	if strongmanger.adofai_data.has("tracks") and strongmanger.adofai_data.tracks[1].size()>0:
		var bpm=strongmanger.adofai_data.tracks[1].get(playmanger.get("ballpos"))
		text=str(text,"bpm|",bpm,"\n")
	else:
		text=str(text,"bpm|",0.0,"\n")
