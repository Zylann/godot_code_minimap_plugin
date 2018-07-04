tool
extends ColorRect


var _text_edit = null
var _dragging = false


func _ready():
	color = Color(0, 0, 0, 0.15)
	var sb = get_scrollbar()
	sb.connect("value_changed", self, "_on_scrollbar_value_changed")


func set_text_edit(text_edit):
	_text_edit = text_edit
	_text_edit.connect("cursor_changed", self, "_on_text_edit_cursor_changed")


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			
			if event.button_index == BUTTON_LEFT:
				_scroll(event.position.y)
			
			if not _dragging:
				_dragging = true
		else:
			_dragging = false
	
	elif event is InputEventMouseMotion:
		if _dragging:
			_scroll(event.position.y)


func _scroll(mouse_y):
	var rh = _get_region_height()
	var line = _pixel_to_line(mouse_y - rh / 2)
	var scrollbar = get_scrollbar()
	scrollbar.value = line


func _pixel_to_line(y):
	return float(y) / 3.0


func _on_scrollbar_value_changed(v):
	# v is the line number at the top of TextEdit
	update()


func _on_text_edit_cursor_changed():
	update()


func get_scrollbar():
	return get_parent()


func _get_region_height():
	# TODO I need the amount of lines the textedit can show...
	var ratio = _text_edit.rect_size.x / _text_edit.rect_size.y
	return rect_size.x / ratio


func _draw():
	if _text_edit == null:
		print("No textedit!")
		return
	
	var rh = _get_region_height()
	draw_rect(Rect2(0, get_scrollbar().value * 3.0, rect_size.x, rh), Color(1,1,1,0.1))
	
	if _text_edit != null:
		draw_map(self, _text_edit)


static func draw_map(control, text_edit):
	var char_w = 1
	var char_h = 2
	var spacing = 1
	var padding = 1
	
	var width = control.rect_size.x
	var height = control.rect_size.y
	
	var visible_line_count = int(height) / (char_h + spacing)

	var line_height = char_h + spacing
	control.draw_rect(Rect2(0, text_edit.cursor_get_line() * line_height, width, line_height), Color(0.7,0.7,0.7,1.0))
	
	var y = 0
	for i in text_edit.get_line_count():
		
		if text_edit.is_folded(i):
			continue
		
		var line = text_edit.get_line(i)
		line = line.to_utf8()
		var x = 0
		
		for j in range(len(line)):
			
			if x >= width:
				break
			
			var c = line[j]
			
			if c == 32:
				x += char_w
				continue
				
			if c == 9:
				x += 4 * char_w
				continue
			
			control.draw_rect(Rect2(x, y, char_w, char_h), Color(1,1,1,0.5))
			x += 1
						
		y += line_height

