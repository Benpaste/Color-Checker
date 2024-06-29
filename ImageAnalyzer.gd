extends Node2D

export(Array, Texture) var tex_array
var current_tex : Texture
var index := 0

var tex_data := []
var hist_cache := []

onready var graphs_boundary: Control = $"%GraphsBoundary"

onready var font = Label.new().get_font("")
export var start := Vector2.ZERO

export var slices := 10
export var length := 100.0
export var height := 50.0
export var spacing := 10

func _ready() -> void:
	
	tex_data.resize(tex_array.size())
	tex_data.fill(null)
	current_tex = tex_array[index]
	
	get_data()
	update_cache()
	draw_all()


func get_colors(t: Texture) -> PoolColorArray:
	
	var img := t.get_data()
	
	img.lock()
	
	var w := img.get_width()
	var h := img.get_height()
	
	var out := PoolColorArray()
	
	for x in w:
		for y in h:
			out.append(img.get_pixel(x, y))
	
	return out


func draw_graph(arr: Array) -> void:
	
	var record := 0
	for i in arr:
		if i > record: record = i
	
	for i in len(arr):
		var slice_width := length/slices
		
		var pos : Vector2 = start + Vector2.RIGHT*slice_width*i
		var h : float =  (height-spacing) * arr[i] / record
		var size := Vector2(slice_width, -h)
		var rect := Rect2(pos, size)
		
		draw_rect(rect, Color.black)


func _draw() -> void:
	
	var start_ = start
	var dict : Dictionary = hist_cache[index]
	for i in len(dict):
		
		var mar = 5
		
		var x_axis = start + mar*Vector2(-1,1)
		draw_line(x_axis, x_axis + Vector2.UP*(mar+height-spacing), Color.black)
		
		var y_axis = start + mar*Vector2(-1,1)
		draw_line(y_axis, y_axis+Vector2.RIGHT*(mar+length), Color.black)
		
		var hist = dict.values()[i]
		draw_graph(hist)
		
		var t = tex_data[index].values()[i]
		var mean := 0.0
		for j in t: mean += j
		mean /= t.size()
		
		var median = t[t.size()/2]
		
		var mode = (hist.find(hist.max()) + 0.5)* (1.0/slices)
		
		var label = start + Vector2.DOWN*20
		var text := "%s - mean: %s - median: %s - mode: %s" % [dict.keys()[i], mean, median, mode]
		draw_string(font, label, text)
		
		start += Vector2.DOWN * height
		
	start = start_


func get_arrays(t: Texture) -> Dictionary:
	
	var colors := get_colors(t)
	
	var output := {
		"saturation": [],
		"value": [],
		"luminance": [],
	}
	
	for c in colors:
		c = c as Color
		if c.a == 0: continue
		output["saturation"].append(c.s)
		output["value"].append(c.v)
		output["luminance"].append(c.get_luminance())
	
	for arr in output.values():
		arr.sort()
	
	return output


func get_hist(arr: Array, granularity: int) -> Array:
	
	var out := []
	out.resize(granularity)
	out.fill(0)
	
	
	for i in arr:
		var i_ = ceil(i / (1.0/granularity)) - 1
		out[i_] += 1
	
	
	return out
	
	
	#0.1, 0.2, 0.3, 0.4, 0.7
	
	#0.1, 0.2	(0-1 -> 0)
	#0.3, 0.4	(1-2 -> 1)
	#			(2-3 -> 2)
	#0.7		(3-4 -> 3)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		draw_all()
	
	var input := Input.get_axis("ui_left","ui_right")
	input = hold_input(input)
	
	if input != 0:
		index += input
		index = posmod(index, tex_array.size())
		current_tex = tex_array[index]
		draw_all()


func draw_all() -> void:
	get_node("%TextureRect").texture = current_tex
	length = graphs_boundary.rect_size.x - graphs_boundary.rect_global_position.x
	height = (graphs_boundary.rect_size.y + spacing) / 3
	start = graphs_boundary.rect_global_position + Vector2.DOWN*(height - spacing)
	update()


func get_data() -> void:
	
	for i in len(tex_array):
		var t : Texture = tex_array[i]
		tex_data[i] = get_arrays(t)


func update_cache() -> void:
	hist_cache.clear()
	
	for i in tex_data:
		hist_cache.append({})
		for key in i:
			hist_cache[-1][key] = get_hist(i[key], slices)


var timer := -1
var old_dir := 0
func hold_input(dir: int) -> int:
	
	if dir == old_dir:
		timer += 1
	else:
		old_dir = dir
		timer = -1
	
	if timer < 60:
		if timer % 15 == 0: return dir
	else:
		if timer % 5 == 0: return dir
	return 0
