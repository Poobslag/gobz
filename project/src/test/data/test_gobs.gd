extends GutTest

func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)


func test_split_10() -> void:
	var source_gob: Gob = gob("🔥 4")
	var new_gob: Gob
	
	# split 7 goblins from 10
	source_gob.back_count = Big.new(9)
	new_gob = Gobs.split_gob(source_gob, Big.new(7))
	assert_eq(source_gob.get_count().to_int(), 3)
	assert_eq(new_gob.get_count().to_int(), 7)
	
	# split 0 goblins from 10 (too few; clamped to 1)
	source_gob.back_count = Big.new(9)
	new_gob = Gobs.split_gob(source_gob, Big.new(0))
	assert_eq(source_gob.get_count().to_int(), 9)
	assert_eq(new_gob.get_count().to_int(), 1)
	
	# split 10 goblins from 10 (too many; clamped to 9)
	source_gob.back_count = Big.new(9)
	new_gob = Gobs.split_gob(source_gob, Big.new(10))
	assert_eq(source_gob.get_count().to_int(), 1)
	assert_eq(new_gob.get_count().to_int(), 9)


func test_split_1() -> void:
	var source_gob: Gob = gob("🔥 4")
	var new_gob: Gob
	
	# split 7 goblins from 1
	new_gob = Gobs.split_gob(source_gob, Big.new(7))
	assert_eq(source_gob.get_count().to_int(), 1)
	assert_null(new_gob)


func test_split_wounded() -> void:
	# 4 out of 13 goblins are wounded
	var source_gob: Gob = gob("🔥 4")
	source_gob.front_hp = 18
	source_gob.back_count = Big.new(12)
	source_gob.back_wounded = Big.new(4)
	assert_eq(source_gob.get_wounded_count().to_int(), 4)
	
	var new_gob: Gob = Gobs.split_gob(source_gob, Big.new(9))
	assert_eq(source_gob.front_hp, 18)
	assert_eq(source_gob.get_count().to_int(), 4)
	assert_eq(source_gob.get_wounded_count().to_int(), 1)
	assert_eq(new_gob.front_hp, 20)
	assert_eq(new_gob.get_count().to_int(), 9)
	assert_eq(new_gob.get_wounded_count().to_int(), 3)


func test_split_all_wounded() -> void:
	# 12 out of 12 goblins are wounded
	var source_gob: Gob = gob("🔥 4")
	source_gob.front_hp = 1
	source_gob.back_count = Big.new(11)
	source_gob.back_wounded = Big.new(11)
	assert_eq(source_gob.get_wounded_count().to_int(), 12)
	
	var new_gob: Gob = Gobs.split_gob(source_gob, Big.new(9))
	assert_eq(source_gob.front_hp, 1)
	assert_eq(source_gob.get_count().to_int(), 3)
	assert_eq(source_gob.get_wounded_count().to_int(), 3)
	assert_eq(new_gob.front_hp, 10)
	assert_eq(new_gob.get_count().to_int(), 9)
	assert_eq(new_gob.get_wounded_count().to_int(), 9)


func test_merge() -> void:
	# 9 goblins (6 hurt) being merged into 4 goblins (1 hurt)
	var gob_a: Gob = gob("🔥 4")
	gob_a.back_count = Big.new(3)
	gob_a.back_wounded = Big.new(1)
	gob_a.wound_severity = 0.4
	gob_a.xp = 4
	
	var gob_b: Gob = gob("🔥 3")
	gob_b.back_count = Big.new(8)
	gob_b.back_wounded = Big.new(5)
	gob_b.wound_severity = 0.1
	gob_b.front_hp = 1
	gob_b.xp = 3
	
	var survivor_gob: Gob
	
	survivor_gob = Gobs.merge_gob(gob_a.duplicate(), gob_b.duplicate())
	assert_eq(survivor_gob.get_count().to_int(), 13)
	assert_eq(survivor_gob.get_wounded_count().to_int(), 7)
	assert_eq(survivor_gob.wound_severity, 0.4)
	assert_eq(survivor_gob.front_hp, 20)
	
	survivor_gob = Gobs.merge_gob(gob_b.duplicate(), gob_a.duplicate())
	assert_eq(survivor_gob.get_count().to_int(), 13)
	assert_eq(survivor_gob.get_wounded_count().to_int(), 7)
	assert_eq(survivor_gob.wound_severity, 0.4)
	assert_eq(survivor_gob.front_hp, 20)
