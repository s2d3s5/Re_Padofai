extends Node


# 对应原JS的fmol函数：取模运算
static func fmol(a: float, b: float) -> float:
	return a - b * floor(a / b)

# 对应原JS的l函数：线性插值
static func l(a: float, b: float, t: float) -> float:
	return a + t * (b - a)

# 对应原JS的q函数：分段插值函数
static func q(x: float) -> float:
	if x >= 0 and x <= 5:
		return 1.0
	elif x > 5 and x <= 30:
		return l(1.0, 0.83, sqrt((x - 5) / 25.0))
	elif x > 30 and x <= 45:
		return l(0.83, 0.77, (x - 30) / 15.0)
	elif x > 45 and x <= 90:
		return l(0.77, 0.15, pow((x - 45) / 45.0, 0.7))
	elif x > 90 and x <= 120:
		return l(0.15, 0.0, sqrt((x - 90) / 45.0))
	else:
		return 0.0

# 对应原JS的d2r函数：角度转弧度
static func d2r(deg: float) -> float:
	return deg * PI / 180.0

# 对应原JS自定义的sin函数（参数为角度）
static func sin_deg(deg: float) -> float:
	return sin(d2r(deg))

# 对应原JS自定义的cos函数（参数为角度）
static func cos_deg(deg: float) -> float:
	return cos(d2r(deg))

# 对应原JS的f函数
static func f(x: float, w: float) -> float:
	if x <= 5:
		return 0.0
	else:
		#return 0.0
		return -1.0 * (l(0.0, w, q(x)) - w) / sin_deg(x / 2.0)

# 对应原JS的Sector函数：扇形顶点生成
static func Sector(Cx: float, Cy: float, rad: float, ang: float, dir: float, a: float, acc: float, pts: Array) -> Array:
	var angle: float = a
	var d: float = dir
	var p: Array[Vector2] = pts.duplicate()  # 避免修改原数组（JS中是引用传递，这里保持逻辑一致）
	
	# 直接获取最后一个 Vector2 顶点
	var last_pt = p[p.size() - 1]
	# 直接用 .x / .y 获取坐标（Godot Vector2 原生属性）
	var last_x = last_pt.x
	var last_y = last_pt.y
	var dist = sqrt(pow(Cx + rad * cos_deg(angle) - last_x, 2) + pow(Cy + rad * sin_deg(angle) - last_y, 2))
	
	if rad < round(dist):
		angle = a + dir * ang
		d = -1.0 * dir
	
	# 循环生成顶点
	for i in range(floor(ang / acc) - 1):
		var px = Cx + rad * cos_deg(angle)
		var py = Cy + rad * sin_deg(angle)
		p.append(Vector2(px,py))
		angle += d * acc
	
	# 最后一个顶点追加逻辑
	if d == dir:
		var px = Cx + rad * cos_deg(a + dir * ang)
		var py = Cy + rad * sin_deg(a + dir * ang)
		p.append(Vector2(px,py))
	else:
		var px = Cx + rad * cos_deg(a)
		var py = Cy + rad * sin_deg(a)
		p.append(Vector2(px,py))
	
	return p
static func clean_polygon_points(pts:Array) -> Array:
	if pts.size() < 3:
		return pts
	var start = pts[0]
	# 找到中途第二次出现起点的位置，直接截断
	for i in range(1, pts.size()):
		if abs(pts[i].x - start.x) < 0.01 && abs(pts[i].y - start.y) < 0.01:
			return pts.slice(0, i+1)
	return pts
# 核心：对应原JS的CaculatePoints函数（顶点计算主逻辑）
static func CaculatePoints(ang1: float, ang2: float, wid: float, len1: float,offest:Vector2=Vector2.ZERO) -> PackedVector2Array:
	var a1: float = -1.0 * ang1
	var a2: float = -1.0 * ang2
	
	# 计算最小夹角
	var alpha: float = min(fmol(a1 - a2, 360.0), fmol(a2 - a1, 360.0))
	var a: Array = []
	
	# 角度排序逻辑
	if fmol(a1 - a2, 360.0) > fmol(a2 - a1, 360.0):
		a.append(fmol(a1, 360.0))
		a.append(fmol(a2, 360.0))
	else:
		a.append(fmol(a2, 360.0))
		a.append(fmol(a1, 360.0))
	
	# 中心点计算
	var m: float = a[0] + alpha / 2.0
	var x0: float = -1.0 * f(alpha, wid) * cos_deg(m)
	var y0: float = -1.0 * f(alpha, wid) * sin_deg(m)
	var r0: float = abs(f(alpha, wid) * sin_deg(alpha / 2.0) - wid)
	
	# 初始化顶点数组
	var pts: Array[Vector2] = []
	
	# 追加第一个顶点
	var p1_x = -1.0 * r0 * sin_deg(a[1]) + x0
	var p1_y = r0 * cos_deg(a[1]) + y0
	pts.append(Vector2(p1_x,p1_y)+offest)
	
	# 追加第二个顶点
	var p2_x = -1.0 * wid * sin_deg(a[1]) + len1 * cos_deg(a[1])
	var p2_y = wid * cos_deg(a[1]) + len1 * sin_deg(a[1])
	pts.append(Vector2(p2_x,p2_y)+offest)
	
	# 分支判断：生成不同顶点序列
	if 2.0 * atan(wid / len1) < d2r(alpha):
		# 分支1
		var p3_x = wid * sin_deg(a[1]) + len1 * cos_deg(a[1])
		var p3_y = -1.0 * wid * cos_deg(a[1]) + len1 * sin_deg(a[1])
		pts.append(Vector2(p3_x,p3_y)+offest)
		
		var p4_x = wid / sin_deg(alpha / 2.0) * cos_deg(m)
		var p4_y = wid / sin_deg(alpha / 2.0) * sin_deg(m)
		pts.append(Vector2(p4_x,p4_y))
		
		var p5_x = -1.0 * wid * sin_deg(a[0]) + len1 * cos_deg(a[0])
		var p5_y = wid * cos_deg(a[0]) + len1 * sin_deg(a[0])
		pts.append(Vector2(p5_x,p5_y)+offest)
	else:
		# 分支2
		var p3_x = (len1 * cos_deg(a[0]) - wid * sin_deg(a[1])) / cos_deg(alpha)
		var p3_y = (len1 * sin_deg(a[0]) + wid * cos_deg(a[1])) / cos_deg(alpha)
		pts.append(Vector2(p3_x,p3_y)+offest)
		
		var p4_x = -1.0 * wid * sin_deg(a[0]) + len1 * cos_deg(a[0])
		var p4_y = wid * cos_deg(a[0]) + len1 * sin_deg(a[0])
		pts.append(Vector2(p4_x,p4_y)+offest)
		
		var p5_x = len1 * cos_deg(m) / cos_deg(alpha / 2.0)
		var p5_y = len1 * sin_deg(m) / cos_deg(alpha / 2.0)
		pts.append(Vector2(p5_x,p5_y)+offest)
		
		var p6_x = wid * sin_deg(a[1]) + len1 * cos_deg(a[1])
		var p6_y = -1.0 * wid * cos_deg(a[1]) + len1 * sin_deg(a[1])
		pts.append(Vector2(p6_x,p6_y)+offest)
		
		var p7_x = (len1 * cos_deg(a[1]) + wid * sin_deg(a[0])) / cos_deg(alpha)
		var p7_y = (len1 * sin_deg(a[1]) - wid * cos_deg(a[0])) / cos_deg(alpha)
		pts.append(Vector2(p7_x,p7_y)+offest)
	
	# 追加后续顶点
	var p8_x = wid * sin_deg(a[0]) + len1 * cos_deg(a[0])
	var p8_y = -1.0 * wid * cos_deg(a[0]) + len1 * sin_deg(a[0])
	pts.append(Vector2(p8_x,p8_y)+offest)
	
	var p9_x = r0 * sin_deg(a[0]) + x0
	var p9_y = -1.0 * r0 * cos_deg(a[0]) + y0
	pts.append(Vector2(p9_x,p9_y)+offest)
	
	# 调用Sector补充扇形顶点
	if fmol(a1, 360.0) > fmol(a2, 360.0):
		var dir = 1.0 if (fmol(a1, 360.0) - fmol(a2, 360.0)) > 180.0 else -1.0
		var sector_a = a2 + 90.0 if (fmol(a1, 360.0) - fmol(a2, 360.0)) > 180.0 else a2 - 90.0
		pts = Sector(x0+offest.x, y0+offest.y, r0, 180.0 - alpha, dir, sector_a, 5.0, pts)
	else:
		var dir = 1.0 if (fmol(a2, 360.0) - fmol(a1, 360.0)) > 180.0 else -1.0
		var sector_a = a1 + 90.0 if (fmol(a2, 360.0) - fmol(a1, 360.0)) > 180.0 else a1 - 90.0
		pts = Sector(x0+offest.x, y0+offest.y, r0, 180.0 - alpha, dir, sector_a, 5.0, pts)
	var clean_pts = []
	var last = null
	for p in pts:
		if p != last:  # 去重
			clean_pts.append(p)
			last = p
	if clean_pts.size()>2 and clean_pts[-1] == clean_pts[0]:
		clean_pts.pop_back()
	clean_pts = clean_polygon_points(clean_pts)
	return PackedVector2Array(clean_pts)
static func poly_to_mesh(poly:PackedVector2Array) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices:PackedInt32Array = Geometry2D.triangulate_polygon(poly)

	var rect:Rect2 = Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		rect = rect.expand(p)
	var size:Vector2 = rect.size

	for p in poly:
		var base_uv:Vector2 = (p - rect.position)/size
		var final_uv:Vector2 = base_uv
		st.set_uv(final_uv)
		st.add_vertex(Vector3(p.x, p.y, 0.0))

	for idx in indices:
		st.add_index(idx)
	var m = st.commit()
	return m
