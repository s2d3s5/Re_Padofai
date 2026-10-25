extends Node
var adofai_d:Dictionary={}
signal input_over(time:float)
class AdofaiData extends RefCounted:
	var angledata:PackedFloat32Array=PackedFloat32Array()
	var setting:Dictionary={}
	var actions:Array=[]
	static var angle_map:Dictionary = {
		"R":0.0,"p":15.0,"J":30.0,"E":45.0,"T":60.0,"o":75.0,"U":90.0,"q":105.0,
		"G":120.0,"Q":135.0,"H":150.0,"W":165.0,"L":180.0,"x":195.0,"N":210.0,
		"Z":225.0,"F":240.0,"V":255.0,"D":270.0,"Y":285.0,"B":300.0,"C":315.0,
		"M":330.0,"A":345.0,"5":555.0,"6":666.0,"7":777.0,"8":888.0,"!":999.0
	}
	func for_pathdata(input_str: String) -> float:
		if angle_map.has(input_str):
			return angle_map[input_str]
		print("未知字符：", input_str)
		return 0.0
	func _init(a=[],s={},ac=[]) -> void:
		angledata=a
		setting=s
		actions=ac
	func turn_pathdata_to_angledata(p:String)->void:
		angledata.clear()
		for i in range(p.length()):
			angledata.append(for_pathdata(p[i]))

var track_pos:PackedVector2Array = PackedVector2Array()
var track_way:PackedByteArray = PackedByteArray()
var track_showmode:PackedByteArray = PackedByteArray()
var track_bpm:PackedFloat32Array = PackedFloat32Array()
var track_pause:PackedFloat32Array = PackedFloat32Array()

func _on_calule_pressed() -> void:
	var cuttingtime=Time.get_unix_time_from_system()
	
	track_pos.clear()
	track_way.clear()
	track_showmode.clear()
	track_bpm.clear()
	track_pause.clear()
	delta_angledata.clear()
	times.clear()
	world_chunk.clear()
	
	if stream != null:
		stream = null
	if video_stream != null:
		video_stream = null
	adofai_d.clear()
	stream = null
	
	$"../存储".adofai_data.clear()
	$"../play".doing="none"
	$"../play".ballpos=0
	$"../CanvasLayer/Control/Foldable/main/buttons/Label".text="导入失败"
	
	input_adofai_by_path($"../存储".adofai_path)
	
	if !adofai_d.is_empty():
		var data:AdofaiData=null
		if adofai_d.has("angleData"):
			data=AdofaiData.new(adofai_d.angleData,adofai_d.settings,adofai_d.actions)
		elif adofai_d.has("pathData"):
			data=AdofaiData.new(PackedFloat32Array(),adofai_d.settings,adofai_d.actions)
			data.turn_pathdata_to_angledata(adofai_d.pathData)
		else:
			printerr("无法读取该adofai")
			return
		adofai_d.clear()
		if data.angledata.size()>0:
			creat_track(data)
			count_delta_angle(data)
			count_time(data)
			
			count_chunk(data)
			input_muice(data)
			input_video(data)
			sending_data(data)
		else:
			printerr("关卡是空的，没有任何角度数据，无法读取！")
			return
		emit_signal("input_over",Time.get_unix_time_from_system()-cuttingtime)
		print()

func input_adofai_by_path(path:String)->void:
	var file=FileAccess.open(path,FileAccess.READ)
	if file==null:
		printerr(str("打开文件失败：",FileAccess.get_open_error()))
		return
	print("文件大小：",file.get_length()/1024.0/1024.0,"MiB")
	var json=JSON.new()
	var adofaistr=file.get_as_text()
	var parse_result = json.parse(adofaistr)
	adofaistr=null
	file.close()
	if parse_result != OK:
		printerr("godot文件转化失败",json.get_error_message()," 出现在第",json.get_error_line(),"行")
		json=null
		return
	if json.data is Dictionary:
		adofai_d=json.data
	json=null
enum Showmodes
{
	NONE,
	F,
	S,
	R
}

func creat_track(data:AdofaiData)->void:
	var pos_add=Vector2.ZERO
	var angledata=data.angledata
	var events=data.actions
	var eventi:int=0
	var way:int=1
	var bpm=data.setting.bpm
	track_pos.clear()
	for i in range(angledata.size()+1):
		var showmode:Showmodes=Showmodes.NONE
		var pause:float=0.0
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
									showmode=Showmodes.F#f是加速方块
								elif event.beatsPerMinute/bpm<0.9:
									showmode=Showmodes.S#s是加速方块
								bpm=event.beatsPerMinute
						
							"Multiplier":
								if event.bpmMultiplier>1.1:
									showmode=Showmodes.F#f是加速方块
								elif event.bpmMultiplier<0.9:
									showmode=Showmodes.S#s是加速方块
								bpm*=event.bpmMultiplier
							_:
								print(str("跳过未知事件：",event))
					else:
						bpm=event.beatsPerMinute
				"Twirl":
					way=1-way#1正转，0反转
					showmode=Showmodes.R#r是旋转方块
				"Pause":
					pause=event.duration
				"PositionTrack":
					if event.has("positionOffset"):
						pos_add+=Vector2(event.positionOffset[0],-event.positionOffset[1])*90
			eventi+=1
		track_pos.append(pos_add)
		track_showmode.append(showmode)
		track_way.append(way)
		track_bpm.append(bpm)
		track_pause.append(pause)
		var angle=angledata[clampi(i,0,angledata.size()-1)]
		if angle==999:
			var index=1
			while angledata[index]==999 and i>=0:
				index+=1
			angle=angledata[clampi(i-index,0,angledata.size()-1)]+180
		angle=deg_to_rad(angle)
		pos_add.x+=cos(angle)*90
		pos_add.y+=sin(angle)*-90

var delta_angledata:PackedFloat32Array
func count_delta_angle(data)->void:
	var angledata:PackedFloat32Array=data.angledata.duplicate()
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
		if track_way[de_i]*2-1==-1 and not ii==360.0:
			ii=360-ii
		if angledata[de_i]==999:
			delta_angledata.append(0.0)
		else:
			delta_angledata.append(ii)

var times:PackedFloat32Array=PackedFloat32Array()
func count_time(_data)->void:
	times.clear()
	times.append(0.0)
	var time:float=0
	for t_i in range(delta_angledata.size()):
		var bpm=track_bpm[t_i]#从0开始，即+1
		var delta_angle=delta_angledata[t_i]#从1开始，即什么也不偏
		var pause:float=track_pause[t_i]#以后大概有用，控一下
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
	for i in range(track_pos.size()):
		var tile_pos=track_pos[i]
		var track_lower=(tile_pos/chunk_size).floor()
		track_lower=Vector2i(track_lower)
		if world_chunk.has(track_lower):
			world_chunk[track_lower].append(i)
		else:
			world_chunk[track_lower] = PackedInt32Array([i])
			
var stream:AudioStream=null
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

var video_stream:NativeVideoStream=null

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
			video_stream=null
			return
		video_stream=NativeVideoStream.new()
		video_stream.file=bgVideo_path
	else:
		video_stream=null

func sending_data(data:AdofaiData)->void:
	var save_target = $"../存储".adofai_data
	save_target.clear()#    0         1         2           3         4
	save_target["tracks"] =[track_pos,track_bpm,track_pause,track_way,track_showmode]
	save_target["delta_angledata"] = delta_angledata
	save_target["times"] = times
	save_target["angledata"] = data.angledata
	save_target["world_chunk"] = world_chunk
	save_target["chunk_size"] = chunk_size
	save_target["audio"] = stream
	save_target["setting"]=data.setting
	save_target["video_stream"]=video_stream
	#save_target["support_events"]
