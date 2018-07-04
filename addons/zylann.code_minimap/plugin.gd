tool
extends EditorPlugin


const Minimap = preload("minimap.gd")

#var _test_button = null
var _text_edits = {} # TextEdit => Minimap (or `true` if none)
var _scripts = []


func _enter_tree():
#	_test_button = Button.new()
#	_test_button.text = "Test"
#	_test_button.connect("pressed", self, "_on_test_button_pressed")
#	add_control_to_container(CONTAINER_TOOLBAR, _test_button)

	var editor_interface = get_editor_interface()
	var script_editor = editor_interface.get_script_editor()

	#           UGLY HACKS AHEAD
	#   .....  .... ........ ...  .........
	#  ...   .....  ... d Y88888888888P b
	#       .. ....  d8888 Y888888888P 8888b
	#    ,-.        d888888a888888888a888888b
	#  (<@) )_     88P'   `Y888888888P'   `Y88
	#  \ /  ; )   ,,~~~.    Y8888888P       Y88
	#  /``-*==' ,''8    '~~~ 8888888~~''``.  888
	#  `--'}`~~' 888&aaaaaaa88P'8`Y88aaaaaa`.888
	#    __       Y8888888888P  8  Y88888888;8P
 	#  ;-.\__            888bod8bod888     ; 
	#  |'@) ; `,    ,~~~~d8888888888888b   '
	#  ,`/_.' |==~''##a. 888 `.888   888    
	#  `.__\_/ `     *#a.      `.  ....    ;

	_setup_minimaps()


func _exit_tree():
	#remove_control_from_container(CONTAINER_TOOLBAR, _test_button)
	
	for e in _text_edits:
		var minimap = _text_edits[e]
		if typeof(minimap) == TYPE_OBJECT:
			minimap.queue_free()

	
func _on_test_button_pressed():
	_setup_minimaps()


func _process(delta):
	var editor_interface = get_editor_interface()
	var script_editor = editor_interface.get_script_editor()
	
	var scripts = script_editor.get_open_scripts()
	if len(scripts) != len(_scripts):
		# Maybe a script was opened, or closed
		_scripts = scripts
		_setup_minimaps()


# There is no API to know exactly when a new code editor is opened or closed,
# so I have to setup minimaps the brute force way. It is slow, I'm sorry.
func _setup_minimaps():
	var time_before = OS.get_ticks_msec()
	
	var editor_interface = get_editor_interface()
	var script_editor = editor_interface.get_script_editor()
	
	
	# There is no API either to get TextEdits for each script editor...
	
	var text_edits = walk_nodes(script_editor, funcref(self, "is_text_edit"))
	for e in text_edits:
		
		if _text_edits.has(e):
			continue
		
		_text_edits[e] = true
		e.connect("tree_exited", self, "_on_text_edit_exited_tree", [e])
		
		# Aaaand no API again to get the scrollbar of a TextEdit
		var scrollbars = walk_nodes(e, funcref(self, "is_v_scrollbar"))
		if len(scrollbars) >= 1:
			_hack_scrollbar(scrollbars[0], e)
	
	var elapsed = OS.get_ticks_msec() - time_before
	print("Setting up minimaps took ", elapsed, "ms")


func _on_text_edit_exited_tree(e):
	# Forget about it.
	# The minimap is child of the TextEdit, it will take care of itself.
	_text_edits.erase(e)


func _hack_scrollbar(scrollbar, text_edit):
	#var r = scrollbar.rect_min_size
	#r.x = 100
	#scrollbar.rect_min_size = r
	#scrollbar.rect_size = scrollbar.rect_min_size
	
	var mm = Minimap.new()
	mm.set_text_edit(text_edit)
	scrollbar.add_child(mm)
	mm.set_anchors_preset(Control.PRESET_WIDE)
	mm.margin_right = -scrollbar.rect_size.x
	mm.margin_left = -100
	mm.margin_bottom = 0

	_text_edits[text_edit] = mm


func is_text_edit(node):
	return node is TextEdit


func is_v_scrollbar(node):
	return node is VScrollBar


func walk_nodes(parent, filter, ret=[]):
	if filter == null or filter.call_func(parent):
		ret.append(parent)
	for i in parent.get_child_count():
		walk_nodes(parent.get_child(i), filter, ret)
	return ret

