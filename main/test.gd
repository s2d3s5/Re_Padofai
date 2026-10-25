extends Node

var count_tile=preload("res://code/staitic/tile.gd")
var mesh=MeshInstance2D.new()
var time:=0.0
func _ready() -> void:
	add_child(mesh)
	mesh.texture=preload("res://tex/tile_texture.png")
func _process(delta: float) -> void:
	time+=delta*30
	var point=count_tile.CaculatePoints(0,time,45,90)
	mesh.mesh=count_tile.poly_to_mesh(point)

# 输入：PackedVector2Array 多边形顶点（就是get_tile_point返回的值）
