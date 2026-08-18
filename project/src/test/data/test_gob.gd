extends GutTest

var gob: Gob

func before_each() -> void:
	gob = new_gob("🔥 3")


func test_get_wounded_count_group() -> void:
	gob = new_gob("🔥 3")
	gob.back_count = Big.new(9)
	
	gob.back_wounded = Big.new(9)
	assert_eq(gob.get_wounded_count().to_int(), 9)
	
	gob.back_wounded = Big.new(0)
	assert_eq(gob.get_wounded_count().to_int(), 0)
	
	gob.back_wounded = Big.new(4)
	assert_eq(gob.get_wounded_count().to_int(), 4)
	
	gob.front_hp = 9
	assert_eq(gob.get_wounded_count().to_int(), 4)
	
	gob.front_hp = 8
	assert_eq(gob.get_wounded_count().to_int(), 5)
	
	gob.front_hp = 7
	assert_eq(gob.get_wounded_count().to_int(), 5)


func test_get_wounded_count_solo() -> void:
	gob = new_gob("🔥 3")
	assert_eq(gob.get_wounded_count().to_int(), 0)
	
	gob.front_hp = 9
	assert_eq(gob.get_wounded_count().to_int(), 0)
	
	gob.front_hp = 8
	assert_eq(gob.get_wounded_count().to_int(), 1)
	
	gob.front_hp = 7
	assert_eq(gob.get_wounded_count().to_int(), 1)


func test_get_healthy_count_group() -> void:
	gob = new_gob("🔥 3")
	gob.back_count = Big.new(9)
	
	gob.back_wounded = Big.new(9)
	assert_eq(gob.get_healthy_count().to_int(), 1)
	
	gob.back_wounded = Big.new(0)
	assert_eq(gob.get_healthy_count().to_int(), 10)
	
	gob.back_wounded = Big.new(4)
	assert_eq(gob.get_healthy_count().to_int(), 6)
	
	gob.front_hp = 9
	assert_eq(gob.get_healthy_count().to_int(), 6)
	
	gob.front_hp = 8
	assert_eq(gob.get_healthy_count().to_int(), 5)
	
	gob.front_hp = 7
	assert_eq(gob.get_healthy_count().to_int(), 5)


func test_get_healthy_count_solo() -> void:
	gob = new_gob("🔥 3")
	assert_eq(gob.get_healthy_count().to_int(), 1)
	
	gob.front_hp = 9
	assert_eq(gob.get_healthy_count().to_int(), 1)
	
	gob.front_hp = 8
	assert_eq(gob.get_healthy_count().to_int(), 0)
	
	gob.front_hp = 7
	assert_eq(gob.get_healthy_count().to_int(), 0)


func test_get_count() -> void:
	gob = new_gob("🔥 3")
	assert_eq(gob.get_count().to_int(), 1)
	
	gob.back_count = Big.new(10)
	assert_eq(gob.get_count().to_int(), 11)


func test_get_count_zero() -> void:
	gob = new_gob("🔥 3")
	gob.front_hp = 0
	assert_eq(gob.get_count().to_int(), 0)


func test_is_dead() -> void:
	gob = new_gob("🔥 3")
	assert_eq(gob.is_dead(), false)
	
	gob.front_hp = 0
	assert_eq(gob.is_dead(), true)


func test_kill_front_solo() -> void:
	gob = new_gob("🔥 3")
	gob.kill_front()
	assert_eq(gob.back_count.to_int(), 0)
	assert_eq(gob.front_hp, 0)


func test_kill_front_back_healthy() -> void:
	gob = new_gob("🔥 3")
	gob.back_count = Big.ONE
	gob.kill_front()
	assert_eq(gob.back_count.to_int(), 0)
	assert_eq(gob.front_hp, 16)


func test_kill_front_back_wounded() -> void:
	gob = new_gob("🔥 3")
	gob.back_count = Big.ONE
	gob.back_wounded = Big.ONE
	gob.kill_front()
	assert_eq(gob.back_count.to_int(), 0)
	assert_eq(gob.front_hp, 8)


func new_gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)
