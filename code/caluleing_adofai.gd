extends Node
var adofai_d:Dictionary={}
signal input_over(time:float)
class AdofaiData extends RefCounted:
	var angledata:PackedFloat32Array=[]
	var setting:Dictionary={}
	var actions:Array=[]
	func for_pathdata(input_str: String) -> float:
		match input_str:
			"R":
				return 0.0
			"p":
				return 15.0
			"J":
				return 30.0
			"E":
				return 45.0
			"T":
				return 60.0
			"o":
				return 75.0
			"U":
				return 90.0
			"q":
				return 105.0
			"G":
				return 120.0
			"Q":
				return 135.0
			"H":
				return 150.0
			"W":
				return 165.0
			"L":
				return 180.0
			"x":
				return 195.0
			"N":
				return 210.0
			"Z":
				return 225.0
			"F":
				return 240.0
			"V":
				return 255.0
			"D":
				return 270.0
			"Y":
				return 285.0
			"B":
				return 300.0
			"C":
				return 315.0
			"M":
				return 330.0
			"A":
				return 345.0
			"5":
				return 555.0
			"6":
				return 666.0
			"7":
				return 777.0
			"8":
				return 888.0
			"!":
				return 999.0
			_:
				print("未知字符：", input_str)
				return 0.0
	func _init(a=[],s={},ac=[]) -> void:
		angledata=a.duplicate()
		setting=s.duplicate()
		actions=ac.duplicate()
	func turn_pathdata_to_angledata(p:String)->void:
		angledata.clear()
		for i in range(p.length()):
			angledata.append(for_pathdata(p[i]))
var tracks:Array[Track]=[]

func _on_calule_pressed() -> void:
	var cuttingtime=Time.get_unix_time_from_system()
	tracks.clear()
	delta_angledata = []
	times.clear()
	world_chunk.clear()
	adofai_d = {}
	stream = null
	$"../存储".adofai_data = {}
	$"../play".doing="none"
	$"../play".ballpos=0
	$"../CanvasLayer/Control/Foldable/main/buttons/Label".text="导入失败"
	input_adofai_by_path($"../存储".adofai_path)
	if adofai_d!={}:
		var data:AdofaiData=null
		if adofai_d.has("angleData"):
			data=AdofaiData.new(adofai_d.angleData,adofai_d.settings,adofai_d.actions)
		elif adofai_d.has("pathData"):
			data=AdofaiData.new([],adofai_d.settings,adofai_d.actions)
			data.turn_pathdata_to_angledata(adofai_d.pathData)
		else:
			printerr("无法读取该adofai")
			return
		adofai_d={}
		creat_track(data)
		count_delta_angle(data)
		count_time(data)
		count_chunk(data)
		input_muice(data)
		input_video(data)
		
		sending_data(data)
		emit_signal("input_over",Time.get_unix_time_from_system()-cuttingtime)

func input_adofai_by_path(path:String)->void:
	var file=FileAccess.open(path,FileAccess.READ)

	if file==null:
		printerr(str("打开文件失败：",FileAccess.get_open_error()))
		return
	var adofaistr=file.get_as_text()
	print("文件大小：",file.get_length()/1024.0/1024.0,"MiB")
	file.close()
	adofai_d={}
	var json=JSON.new()
	var parse_result = json.parse(adofaistr)
	
	if parse_result != OK:
		printerr("文件转化失败",json.get_error_message()," 出现在第",json.get_error_line(),"行")
		json=null
		return
	if json.data is Dictionary:
		adofai_d=json.data
	json=null


func creat_track(data:AdofaiData)->void:
	var pos_add=Vector2.ZERO
	var angledata=data.angledata
	var events=data.actions
	var eventi:int=0
	var way:int=1
	var bpm=data.setting.bpm
	tracks.clear()
	for i in range(angledata.size()+1):
		var track=Track.new()
		#var trackevent:Array=[]
		while eventi < events.size() and i >= events[eventi].floor:
			#trackevent.append(events[eventi])
			var event:Dictionary=events[eventi]
			match event.eventType:#不同事件
				"SetSpeed":
					if event.has("speedType"):
						match event.speedType:
							"Bpm":
								if event.beatsPerMinute/bpm>1.1:
									track.showmodle="f"#f是加速方块
								elif event.beatsPerMinute/bpm<0.9:
									track.showmodle="s"#s是加速方块
								bpm=event.beatsPerMinute
						
							"Multiplier":
								if event.bpmMultiplier>1.1:
									track.showmodle="f"#f是加速方块
								elif event.bpmMultiplier<0.9:
									track.showmodle="s"#s是加速方块
								bpm*=event.bpmMultiplier
							_:
								print(str("跳过未知事件：",event))
					else:
						bpm=event.beatsPerMinute
				"Twirl":
					way*=-1
					track.showmodle="r"#r是旋转方块
				"Pause":
					track.pause=event.duration
				"PositionTrack":
					if event.has("positionOffset"):
						pos_add+=Vector2(event.positionOffset[0],-event.positionOffset[1])*90
			eventi+=1
		track.pos=pos_add
		#track.event=trackevent
		track.way=way
		track.bpm=bpm
		tracks.append(track)
		var angle=angledata[clampi(i,0,angledata.size()-1)]
		if angle==999:
			var index=1
			while angledata[index]==999 and i>=0:
				index+=1
			angle=angledata[clampi(i-index,0,angledata.size()-1)]+180
		angle=deg_to_rad(angle)
		pos_add.x+=cos(angle)*90
		pos_add.y+=sin(angle)*-90

var delta_angledata:PackedFloat64Array
func count_delta_angle(data)->void:
	var angledata:PackedFloat32Array=data.angledata
	delta_angledata.clear()
	angledata.append(INF)
	for de_i in range(angledata.size()-1):
		while true:
			if not (angledata[de_i]==999 or (angledata[de_i]<360 or angledata[de_i]==INF)):
				angledata[de_i]-=360
			else:
				break
		while true:
			if angledata[de_i]<0:
				angledata[de_i]+=360
			else:
				break
		var index=0
		if angledata[clampi(de_i-1,0,angledata.size()-1)]==999 and de_i<=angledata.size()-1:
			index=1
			while angledata[clampi(de_i-index,0,angledata.size()-1)]==999:
				index+=1
				if de_i-index<=0:
					break
		var ii:float=(angledata[de_i-index]-index*180)-angledata[de_i] if (0.0 if de_i-1<0 else angledata[de_i-1])==999 else (0.0 if de_i-1<0 else angledata[de_i-1]) +180.0-angledata[de_i]
		ii=fposmod(ii,360)
		if ii<=0:
			ii+=360
		if tracks[de_i].way==-1 and not ii==360.0:
			ii=360-ii
		if angledata[de_i]==999:
			delta_angledata.append(0.0)
		else:
			delta_angledata.append(ii)

var times:PackedFloat64Array=[]
func count_time(_data)->void:
	times.clear()
	times.append(0.0)
	var time:float=0
	for t_i in range(delta_angledata.size()):
		var bpm=tracks[t_i].bpm#从0开始，即+1
		var delta_angle=delta_angledata[t_i]#从1开始，即什么也不偏
		var pause:float=tracks[t_i].pause#以后大概有用，控一下
		if pause<=0:
			time+=(delta_angle/180)*(60/bpm)
		else:
			time+=60/(bpm/(((180/delta_angle)*pause)+1))*(delta_angle/180)
		times.append(time)

var chunk_size=90*4.0
var world_chunk:Dictionary={}
func count_chunk(_data)->void:
	chunk_size=$"../存储".chunk_size
	if not(chunk_size is float):
		chunk_size=90*4.0
	world_chunk.clear()
	for i in range(tracks.size()):
		var track_pos=tracks[i].pos
		var track_lower=(track_pos/chunk_size).floor()
		track_lower=Vector2i(track_lower)
		if world_chunk.has(track_lower):
			world_chunk[track_lower].append(i)
		else:
			world_chunk[track_lower] = [i]
			
var stream=null
func input_muice(data)->void:
	var setting=data.setting
	var songfile:String=setting.songFilename
	var path:String=$"../存储".adofai_path
	var folder=path.get_base_dir()
	var song_path=folder.path_join(songfile)
	if not FileAccess.file_exists(song_path):
		stream = null
		push_warning(str("音频缺失，无法加载：",songfile))
		return
	match songfile.get_extension().to_lower():
		"wav":
			stream=AudioStreamWAV.load_from_file(song_path)
		"ogg":
			stream=AudioStreamOggVorbis.load_from_file(song_path)
		"mp3":
			stream=AudioStreamMP3.load_from_file(song_path)
		_:
			push_warning(str("不支持的音频格式：",songfile))
			stream=null
			return

var video_stream:NativeVideoStream=NativeVideoStream.new()

func input_video(data)->void:
	var setting=data.setting
	var bgVideo:String=setting.bgVideo
	if bgVideo!="":
		var path:String=$"../存储".adofai_path
		var folder=path.get_base_dir()
		var bgVideo_path=folder.path_join(bgVideo)
		if not FileAccess.file_exists(bgVideo_path):
			video_stream = null
			push_warning(str("视频缺失，无法加载：",bgVideo_path))
			return
		video_stream.file=bgVideo_path
	video_stream=null

func sending_data(data:AdofaiData)->void:
	var save_target = $"../存储".adofai_data
	save_target.clear()
	save_target["tracks"] = tracks
	save_target["delta_angledata"] = delta_angledata
	save_target["times"] = times
	save_target["angledata"] = data.angledata
	save_target["world_chunk"] = world_chunk
	save_target["chunk_size"] = chunk_size
	save_target["audio"] = stream
	save_target["setting"]=data.setting
	save_target["video_stream"]=video_stream
