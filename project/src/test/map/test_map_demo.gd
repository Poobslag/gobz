extends GutTest

func test_circumcenter() -> void:
	assert_eq(circumcenter_str(Vector2(0, 0), Vector2(5, 0), Vector2(0, 5)), "(2.50, 2.50)")
	
	assert_eq(circumcenter_str(Vector2(0, 0), Vector2(0, 5), Vector2(0, 5)), "(-nan, -nan)")
	assert_eq(circumcenter_str(Vector2(0, 5), Vector2(0, 5), Vector2(0, 5)), "(-nan, -nan)")


func test_centroid() -> void:
	assert_eq(centroid_str([Vector2(0, 0), Vector2(5, 0), Vector2(0, 5)]), "(1.67, 1.67)")
	assert_eq(centroid_str([Vector2(0, 0), Vector2(8, 0), Vector2(8, 5), Vector2(0, 5)]), "(4.00, 2.50)")
	
	assert_eq(centroid_str([Vector2(0, 0), Vector2(5, 0)]), "(0.00, 0.00)")
	assert_eq(centroid_str([Vector2(5, 0)]), "(5.00, 0.00)")
	assert_eq(centroid_str([]), "(-nan, -nan)")


func circumcenter_str(a: Vector2, b: Vector2, c: Vector2) -> String:
	var circumcenter: Vector2 = MapDemo.circumcenter(a, b, c)
	return "(%.2f, %.2f)" % [circumcenter.x, circumcenter.y]


func centroid_str(points: Array[Vector2]) -> String:
	var centroid: Vector2 = MapDemo.centroid(points)
	return "(%.2f, %.2f)" % [centroid.x, centroid.y]
