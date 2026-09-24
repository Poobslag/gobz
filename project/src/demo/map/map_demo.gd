class_name MapDemo
extends Control
## [b]Keys:[/b][br]
## 	[kbd]D[/kbd]: Show delaunay triangulation for input points
## 	[kbd]F[/kbd]: Apply fixed input points
## 	[kbd]L[/kbd]: Apply lloyd relaxation to voronoi cells
## 	[kbd]P[/kbd]: Print input points, which can be pasted into fixed_input_points()
## 	[kbd]R[/kbd]: Apply random input points
## 	[kbd]V[/kbd]: Show voronoi cells for input points

## Defines a distant perimeter for voronoi cells to ensure every cell is complete
const VORONOI_FRAME_POINTS: Array[Vector2] = [
	Vector2(-100_000, -100_000),
	Vector2(100_000, -100_000),
	Vector2(100_000, 100_000),
	Vector2(-100_000, 100_000),
]

## Trims voronoi cells within a boundary to prevent cells from drifting offscreen
var voronoi_bounding_box: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(Global.window_size.x, 0),
	Vector2(Global.window_size),
	Vector2(0, Global.window_size.y),
]

var input_points: Array[Vector2] = []
var polygon_defs: Array[Variant] = []

func _ready() -> void:
	randomize_input_points()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_D:
			show_delaunay_triangulation()
		KEY_F:
			fixed_input_points()
		KEY_L:
			apply_lloyd_relaxation()
		KEY_P:
			print_input_points()
		KEY_R:
			randomize_input_points()
		KEY_V:
			show_voronoi_cells()


func _draw() -> void:
	for polygon_def: Array[Variant] in polygon_defs:
		draw_polygon(polygon_def[1], PackedColorArray([polygon_def[0]]))


func print_input_points() -> void:
	print("input_points = [")
	for input_point: Vector2 in input_points:
		print("  Vector2(%.1f, %.1f)," % [input_point.x, input_point.y])
	print("]")


func randomize_input_points() -> void:
	input_points.clear()
	input_points.resize(200)
	for i in input_points.size():
		input_points[i] = Vector2(randf(), randf()) * Vector2(Global.window_size)
	input_points.append_array(VORONOI_FRAME_POINTS)


func fixed_input_points() -> void:
	input_points = [
			Vector2(1137.3, 16.1),
			Vector2(1014.3, 448.3),
			Vector2(544.5, 391.9),
			Vector2(716.8, 256.8),
			Vector2(23.5, 169.5),
			Vector2(-100000.0, -100000.0),
			Vector2(100000.0, -100000.0),
			Vector2(100000.0, 100000.0),
			Vector2(-100000.0, 100000.0),
		]


func show_delaunay_triangulation() -> void:
	polygon_defs.clear()
	
	var triangles: PackedInt32Array = Geometry2D.triangulate_delaunay(input_points)
	
	for i in range(0, triangles.size(), 3):
		var poly_point_0: Vector2 = input_points[triangles[i + 0]]
		var poly_point_1: Vector2 = input_points[triangles[i + 1]]
		var poly_point_2: Vector2 = input_points[triangles[i + 2]]
		polygon_defs.append([
			Color(randf(), randf(), randf()),
			[poly_point_0, poly_point_1, poly_point_2]])
	
	queue_redraw()


func show_voronoi_cells() -> void:
	polygon_defs.clear()
	
	var cells: Array[Array] = compute_voronoi_cells()
	
	for cell: Array[Vector2] in cells:
		if cell.size() <= 2:
			continue
		polygon_defs.append([
			Color(randf(), randf(), randf()),
			cell])
	
	queue_redraw()


## Each item in the array is an Array[Vector2] with points surrounding a voronoi cell.
func compute_voronoi_cells() -> Array[Array]:
	var triangles: PackedInt32Array = Geometry2D.triangulate_delaunay(input_points)
	@warning_ignore("integer_division")
	var triangle_count: int = triangles.size() / 3
	
	# one empty cell per point
	var cells: Array[Array] = []
	cells.resize(input_points.size())
	for i in input_points.size():
		cells[i] = [] as Array[Vector2]
	
	# compute circumcenters for all triangles
	for i in triangle_count:
		var center: Vector2 = circumcenter(
				input_points[triangles[i * 3 + 0]],
				input_points[triangles[i * 3 + 1]],
				input_points[triangles[i * 3 + 2]],
			)
		cells[triangles[i * 3 + 0]].append(center)
		cells[triangles[i * 3 + 1]].append(center)
		cells[triangles[i * 3 + 2]].append(center)
	
	# sort circumcenters by angle around each point
	for i: int in input_points.size():
		var cell: Array[Vector2] = cells[i]
		if cell.size() <= 2:
			continue
		
		var point: Vector2 = input_points[i]
		cell.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return atan2(a.y - point.y, a.x - point.x) < atan2(b.y - point.y, b.x - point.x))
	
	# intersect voronoi cells to bounding box
	for i: int in input_points.size():
		var cell: Array[Vector2] = cells[i]
		var result: Array[PackedVector2Array] = Geometry2D.intersect_polygons(cell, voronoi_bounding_box)
		cells[i] = PackedVector2Array() if result.is_empty() else result[0]
	
	return cells


func apply_lloyd_relaxation() -> void:
	var cells: Array[Array] = compute_voronoi_cells()
	for i in cells.size():
		if input_points[i] in VORONOI_FRAME_POINTS:
			continue
		
		var cell: Array[Variant] = cells[i]
		var relaxed_point: Vector2 = centroid(cell)
		if not is_finite(relaxed_point.x) or not is_finite(relaxed_point.y):
			continue
		input_points[i] = relaxed_point
	
	show_voronoi_cells()


static func centroid(points: Array[Variant]) -> Vector2:
	# Adapted from https://stackoverflow.com/questions/75699024/finding-the-centroid-of-a-polygon-in-python
	var result: Vector2 = Vector2.ZERO
	var area: float = 0.0
	for i in points.size():
		var j: int = (i + 1) % points.size()
		var cross: float = points[i].cross(points[j])
		result += (points[i] + points[j]) * cross
		area += cross
	area *= 0.5
	return result / (6 * area) if area != 0 or points.size() == 0 else points[0]


static func circumcenter(a: Vector2, b: Vector2, c: Vector2) -> Vector2:
	# Adapted from https://github.com/Volts-s/Delaunator-GDScript-4/blob/master/demo.gd
	var ad: float = a.x * a.x + a.y * a.y
	var bd: float = b.x * b.x + b.y * b.y
	var cd: float = c.x * c.x + c.y * c.y
	var d: float = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
	return Vector2(
		1 / d * (ad * (b.y - c.y) + bd * (c.y - a.y) + cd * (a.y - b.y)),
		1 / d * (ad * (c.x - b.x) + bd * (a.x - c.x) + cd * (b.x - a.x))
	)
