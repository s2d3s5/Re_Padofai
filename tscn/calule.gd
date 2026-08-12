extends Button


func _on_adofai计算区_input_over(time:float) -> void:
	$"../Label".text=str("导入完成！用时：",roundi(time*100)/100.0,"秒")
	print("上次导入用时：",time)
	$Timer.start()

func _on_timer_timeout() -> void:
	$"../Label".text=""
