extends Node
class_name AdofaiLoder

func load_string_to_adofai(str:String)->Dictionary:
	var json:JSON=JSON.new()
	var error = json.parse(str)
	var adofai_object = {}
	if error == OK:
		adofai_object = json.data
		if !adofai_object is Dictionary:
			print("不是adofai，是",typeof(adofai_object))
	else:
			print("JSON 解析错误：", json.get_error_message(), "行号:", json.get_error_line())
	return adofai_object

var adofai_object:Dictionary={}

func _on_load_pressed() -> void:
	var a:Thread=Thread.new()
	a.start(load_adofai_as)
func load_adofai_as()->void:
	
	var file:FileAccess=FileAccess.open(SaveSurver.adofai_load_path_string,FileAccess.READ)
	if !file:
		print("读取失败:",FileAccess.get_open_error())
		file.close()
		return
	adofai_object=load_string_to_adofai(file.get_as_text())
	file.close()
	if adofai_object=={}:
		print("读取失败")
		return
	#计算
	angle_data.clear()
	track_bpm.clear()
	track_spin.clear()
	track_positon.clear()
	delta_angledata.clear()
	times.clear()
	var error:Error
	
	error=input_angle()
	if error!=OK:
		print("寻找角度数据失败",error)
		return
	
	error=creat_tile()
	if error!=OK:
		print("发生未定义错误",error)
		return
		
	error=count_delta_angle()
	if error!=OK:
		print("发生未定义错误",error)
		return
		
	error=count_time()
	if error!=OK:
		print("发生未定义错误",error)
		return
	
	print("加载完成")
	
	
const path_to_angle:Dictionary = {
	"R": 0.0,
	"p": 15.0,
	"J": 30.0,
	"E": 45.0,
	"T": 60.0,
	"o": 75.0,
	"U": 90.0,
	"q": 105.0,
	"G": 120.0,
	"Q": 135.0,
	"H": 150.0,
	"W": 165.0,
	"L": 180.0,
	"x": 195.0,
	"N": 210.0,
	"Z": 225.0,
	"F": 240.0,
	"V": 255.0,
	"D": 270.0,
	"Y": 285.0,
	"B": 300.0,
	"C": 315.0,
	"M": 330.0,
	"A": 345.0,
	"5": 555.0,
	"6": 666.0,
	"7": 777.0,
	"8": 888.0,
	"!": 999.0
}
var angle_data:PackedFloat32Array=PackedFloat32Array()
var track_bpm:PackedFloat32Array=PackedFloat32Array()
var track_spin:PackedByteArray=PackedByteArray()
var track_positon:PackedVector2Array=PackedVector2Array()

func input_angle()->Error:
	if adofai_object.has("angleData"):
		angle_data=PackedFloat32Array(adofai_object.angleData)
	else:
		if adofai_object.has("pathData"):
			for char in adofai_object.pathData:
				if path_to_angle.has(char):
					angle_data.append(path_to_angle[char])
				else:
					push_warning(char,"不含在字典")
					return FAILED
		else:
			push_error("这个adofai没有角度数据")
			return FAILED
	return OK
 
func creat_tile()->Error:
	#result = v * 2 - 1 ，1正转得1，0反转得-1
	var action_index=0
	var actions=adofai_object.actions
	var setting=adofai_object.settings
	var sumtile_position=Vector2(0,0)
	track_bpm.append(setting["bpm"])
	track_spin.append(1)#1是正转1，0是倒转-1
	track_positon.append(sumtile_position)
	for tile_index in range(angle_data.size()-1):
		var ang=angle_data[tile_index]
		var nowbpm=track_bpm[tile_index]
		var nowspin=track_spin[tile_index]
		if ang==999:
			ang=angle_data[tile_index-1]+180
			
		
		sumtile_position+=Vector2.from_angle(deg_to_rad(ang))*90
		#读取事件
		var act=actions[action_index]
		while(int(act["floor"])<tile_index and action_index<actions.size()):
			match act["eventType"]:
				"SetSpeed":
					if act.has("speedType"):
						match act["speedType"]:
							"Bpm":
								nowbpm=act["beatsPerMinute"]
							"Multiplier":
								nowbpm*=act["bpmMultiplier"]
							_:
								push_warning("出现了个其他速度类型：",act["speedType"])
					else:
						nowbpm=act["beatsPerMinute"]
				"Twirl":
					nowspin=1-nowspin
			action_index+=1
			if action_index >= actions.size():
				break # 防止读取越界
			act=actions[action_index]
		track_bpm.append(nowbpm)
		track_spin.append(nowspin)
		track_positon.append(sumtile_position)
	return OK

var delta_angledata:PackedFloat32Array
func count_delta_angle()->Error:
	var angledata:PackedFloat32Array=angle_data.duplicate()
	delta_angledata.clear()
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
		if (track_spin[de_i]*2-1)==-1 and not ii==360.0:
			ii=360-ii
		if angledata[de_i]==999:
			delta_angledata.append(0.0)
		else:
			delta_angledata.append(ii)
	return OK

var times:PackedFloat32Array=PackedFloat32Array()
func count_time()->Error:
	for t_i in range(delta_angledata.size()):
		var bpm=track_bpm[t_i]#从0开始，即+1
		var delta_angle=delta_angledata[t_i]#从1开始，即什么也不偏
		var pause:float=0#以后有用，等想好怎么省内存吧
		var time:float=0
		if pause<=0:
			time=(delta_angle/180)*(60/bpm)
		else:
			time=60/(bpm/(((180/delta_angle)*pause)+1))*(delta_angle/180)
		times.append(time)
	return OK
