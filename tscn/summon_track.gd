extends Node
var count_tile=load("res://code/staitic/tile.gd")
var f_tex:Texture=load("res://tex/fast.svg")
var s_tex:Texture=load("res://tex/slow.svg")
var r_tex:Texture=load("res://tex/ro.svg")
var tile_point_temp:Dictionary={}

signal summon_over
# 多边形池映射，消除所有 Array.find()
var poly_to_idx:Dictionary = {}       # Polygon2D -> 池下标
var track_bind_pool:Dictionary = {}   # 赛道id -> 池下标
var pool_in_use:Dictionary = {}       # 替代 using_polygon数组，key=池下标

static func offset_vector2_array(a:PackedVector2Array, offset:Vector2=Vector2.ZERO)->PackedVector2Array:
	if offset == Vector2.ZERO:
		return a
	var b = a.duplicate()
	var leng = b.size()
	for i in range(leng):
		b[i] += offset
	return b

func cmp_desc(a, b):
	return a > b

var world_chunk:Dictionary={}
var angle:Array=[]
var chunk_size:float=90*4.0
var need_drow:Array = []
var last_need_drow:Array = []
var must_add:Array=[]    # 本帧需要新增的赛道id
var must_remove:Array=[] # 本帧需要删除的赛道id
var tracks:Array=[Track.new()]

var isstart:bool=false

# 返回 (max_x距离, max_y距离)
func get_camera_max_half_extent(cam: Camera2D) -> Vector2:
	var vp_size = cam.get_viewport_rect().size
	var half_w = (vp_size.x / cam.zoom.x) / 2.0
	var half_h = (vp_size.y / cam.zoom.y) / 2.0
	return Vector2(half_w, half_h)

@onready var camera=$"../Camera2D"

func count_chunk()->void:
	# 先保存上一帧可视列表
	last_need_drow = need_drow.duplicate()
	var max_show=get_camera_max_half_extent(camera)
	var max_show_lower=(max_show/chunk_size).floor()
	var cam_pos_lower=(camera.position/chunk_size).floor()
	var max_y=cam_pos_lower.y+max_show_lower.y
	var min_y=cam_pos_lower.y-max_show_lower.y
	var max_x=cam_pos_lower.x+max_show_lower.x
	var min_x=cam_pos_lower.x-max_show_lower.x
	var x=min_x-1
	var y=min_y-1
	need_drow.clear()
	while y<=max_y+1:
		while x<=max_x+1:
			var index_pos=Vector2i(x,y)
			if world_chunk.has(index_pos):
				need_drow.append_array(world_chunk[index_pos])
			x+=1
		y+=1
		x=min_x-1
		
	need_drow.sort_custom(cmp_desc)

func get_tile_point(ang1:float,ang2:float)->PackedVector2Array:
	var key = Vector2(ang1, ang2)
	if tile_point_temp.has(key):
		return tile_point_temp[key]
	var point=count_tile.CaculatePoints(ang1,ang2,45/2.0,90/2.0)
	tile_point_temp[key]=point
	return point

var polygon_pool:Array[Polygon2D]=[]
@export var pool_size=20
@export var pool_max_size=400

func creat_pool()->void:
	if polygon_pool.size()<pool_size:
		for i in range(pool_size):
			var p=Polygon2D.new()
			# 渲染优化
			p.antialiased = false
			p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			polygon_pool.append(p)
			poly_to_idx[p] = i
			var l=Line2D.new()
			l.closed=true
			l.width=2.5
			l.default_color=Color(0.0, 0.0, 0.0, 1.0)
			l.joint_mode=Line2D.LINE_JOINT_ROUND
			l.begin_cap_mode=Line2D.LINE_CAP_ROUND
			l.end_cap_mode=Line2D.LINE_CAP_ROUND
			l.round_precision=6
			l.name="line"
			var s=Sprite2D.new()
			s.name="te"
			p.add_child(s)
			p.add_child(l)

func rest_polygon(i:int)->void:
	var p = polygon_pool[i]
	p.polygon.clear()
	p.uv.clear()
	p.position=Vector2.ZERO
	p.get_node("line").points.clear()
	p.get_node("te").texture=null

func get_a_free_polygon()->Polygon2D:
	var i=0
	while i < polygon_pool.size():
		if not pool_in_use.has(i):
			pool_in_use[i] = true
			return polygon_pool[i]
		i+=1
	# 池子扩容
	if polygon_pool.size() < pool_max_size:
		var p=Polygon2D.new()
		p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var new_idx = polygon_pool.size()
		polygon_pool.append(p)
		poly_to_idx[p] = new_idx
		pool_in_use[new_idx] = true
		var l=Line2D.new()
		l.name="line"
		l.closed=true
		l.width=2.5
		l.default_color=Color(0.0, 0.0, 0.0, 1.0)
		l.joint_mode=Line2D.LINE_JOINT_ROUND
		l.begin_cap_mode=Line2D.LINE_CAP_ROUND
		l.end_cap_mode=Line2D.LINE_CAP_ROUND
		l.round_precision=6
		var s=Sprite2D.new()
		s.name="te"
		p.add_child(s)
		p.add_child(l)
		#print("扩容数量:",polygon_pool.size())
		return p
	else:
		return null

# 回收单个多边形（无Array.find）
func recical_polygon(p:Polygon2D)->void:
	if not poly_to_idx.has(p):
		return
	var index = poly_to_idx[p]
	if p.is_inside_tree():
		remove_child(p)
	rest_polygon(index)
	pool_in_use.erase(index)

# 批量回收全部瓦片（切谱面用）
func recical_all()->void:
	for idx in pool_in_use:
		var p = polygon_pool[idx]
		if p.is_inside_tree():
			remove_child(p)
			
		rest_polygon(idx)
	pool_in_use.clear()
	track_bind_pool.clear()
	must_add.clear()
	must_remove.clear()
	last_need_drow.clear()
	need_drow.clear()
	tile_point_temp.clear()


# 核心：找前后两帧差值，填充 must_add / must_remove
func find_diffrend()->void:
	must_add.clear()
	must_remove.clear()
	# 转HashSet加速存在判断
	var last_set:Dictionary = {}
	for id in last_need_drow:
		last_set[id] = true
	var curr_set:Dictionary = {}
	for id in need_drow:
		curr_set[id] = true
	# 上一帧存在、当前帧不存在 → 需要删除
	for old_id in last_need_drow:
		if not curr_set.has(old_id):
			must_remove.append(old_id)
	# 当前帧存在、上一帧不存在 → 需要新增
	for new_id in need_drow:
		if not last_set.has(new_id):
			must_add.append(new_id)

# 仅新增瓦片（定时器增量渲染）
func summon_add_tile()->void:
	for i in must_add:
		var ang1=180
		var ang2=0
		if i!=0:
			ang1=angle[i-1]+180
		if i!=angle.size()-1:
			ang2=angle[i]
		if ang1==999+180:
			var index=1
			while angle[i+index]==999 and i>=angle.size():
				index+=1
			ang1=angle[i+index]-180
		if ang2==999:
			var index=1
			while angle[i-index]==999 and i>=0:
				index+=1
			ang2=angle[i-index]+180
		var point=get_tile_point(ang1,ang2)
		var tile=get_a_free_polygon()
		if tile==null:
			print("池已耗尽，停止新增瓦片")
			return
		# 绑定赛道id与池下标
		var pool_idx = poly_to_idx[tile]
		track_bind_pool[i] = pool_idx
		tile.polygon=point
		tile.get_node("line").points=point
		match tracks[i].showmodle:
			"r":
				tile.get_node("te").texture=r_tex
			"f":
				tile.get_node("te").texture=f_tex
			"s":
				tile.get_node("te").texture=s_tex
		
		tile.position=tracks[i].pos
		add_child(tile)

# 仅删除离开屏幕的瓦片
func remove_out_tile()->void:
	for del_id in must_remove:
		if track_bind_pool.has(del_id):
			var pool_idx = track_bind_pool[del_id]
			var p = polygon_pool[pool_idx]
			recical_polygon(p)
			track_bind_pool.erase(del_id)

# 初次加载完整渲染（切谱面时一次性生成）
func summon_tile()->void:
	must_add = need_drow.duplicate()
	summon_add_tile()


func _on_play_place_tile() -> void:
	var adofai_data=$"../../存储".adofai_data
	
	recical_all()
	if !(adofai_data=={}):
		angle=adofai_data.angledata
		chunk_size=adofai_data.chunk_size
		world_chunk=adofai_data.world_chunk
		tracks=adofai_data.tracks
		count_chunk()
		summon_tile()
		#print("多边形池容量：", polygon_pool.size())
	else:
		push_warning("尚未导入，请导入")
	emit_signal("summon_over")
	isstart=true

func _process(_delta: float) -> void:
	if isstart:
		count_chunk()
		find_diffrend()
		remove_out_tile()
		summon_add_tile()

func _ready() -> void:
	creat_pool()
