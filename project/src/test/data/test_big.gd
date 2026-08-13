extends GutTest

func test_init() -> void:
	assert_almost_eq(Big.new(3_257).to_float(), 3_257.0, 0.1)
	assert_almost_eq(Big.new(3_257.0).to_float(), 3_257.0, 0.1)


func test_to_int() -> void:
	assert_eq(Big.new(2.5).to_int(), 2)
	assert_eq(Big.new(2.999).to_int(), 2)
	assert_eq(Big.new(8).to_int(), 8)


func test_to_int_overflow() -> void:
	assert_eq(Big.new(32.57e180).to_int(), Big.MAX_INT)
	assert_eq(Big.new(-32.57e180).to_int(), Big.MIN_INT)


func test_to_aa_millions() -> void:
	assert_eq(Big.new(3).to_aa(), "3")
	assert_eq(Big.new(32).to_aa(), "32")
	assert_eq(Big.new(325).to_aa(), "325")
	assert_eq(Big.new(3_257).to_aa(), "3,257")
	assert_eq(Big.new(32_570).to_aa(), "32.5k")
	assert_eq(Big.new(325_700).to_aa(), "325k")
	assert_eq(Big.new(3_257_000).to_aa(), "3.2m")
	assert_eq(Big.new(32_570_000).to_aa(), "32.5m")
	assert_eq(Big.new(325_700_000).to_aa(), "325m")
	assert_eq(Big.new(3_257_000_000).to_aa(), "3.2b")


func test_to_aa_millions_boundaries() -> void:
	assert_eq(Big.new(9).to_aa(), "9")
	assert_eq(Big.new(10).to_aa(), "10")
	assert_eq(Big.new(99).to_aa(), "99")
	assert_eq(Big.new(100).to_aa(), "100")
	assert_eq(Big.new(999).to_aa(), "999")
	assert_eq(Big.new(1_000).to_aa(), "1,000")
	assert_eq(Big.new(9_999).to_aa(), "9,999")
	assert_eq(Big.new(10_000).to_aa(), "10.0k")
	assert_eq(Big.new(99_999).to_aa(), "99.9k")
	assert_eq(Big.new(100_000).to_aa(), "100k")
	assert_eq(Big.new(999_999).to_aa(), "999k")
	assert_eq(Big.new(1_000_000).to_aa(), "1.0m")
	assert_eq(Big.new(9_999_999).to_aa(), "9.9m")
	assert_eq(Big.new(10_000_000).to_aa(), "10.0m")
	assert_eq(Big.new(99_999_999).to_aa(), "99.9m")
	assert_eq(Big.new(100_000_000).to_aa(), "100m")
	assert_eq(Big.new(999_999_999).to_aa(), "999m")
	assert_eq(Big.new(1_000_000_000).to_aa(), "1.0b")
	assert_eq(Big.new(9_999_999_999).to_aa(), "9.9b")


func test_negative_boundaries() -> void:
	assert_eq(Big.new(-9).to_aa(), "-9")
	assert_eq(Big.new(-10).to_aa(), "-10")
	assert_eq(Big.new(-99).to_aa(), "-99")
	assert_eq(Big.new(-100).to_aa(), "-100")
	assert_eq(Big.new(-999).to_aa(), "-999")
	assert_eq(Big.new(-1_000).to_aa(), "-1,000")
	assert_eq(Big.new(-9_999).to_aa(), "-9,999")
	assert_eq(Big.new(-10_000).to_aa(), "-10.0k")
	assert_eq(Big.new(-99_999).to_aa(), "-99.9k")
	assert_eq(Big.new(-100_000).to_aa(), "-100k")
	assert_eq(Big.new(-999_999).to_aa(), "-999k")
	assert_eq(Big.new(-1_000_000).to_aa(), "-1.0m")
	assert_eq(Big.new(-9_999_999).to_aa(), "-9.9m")
	assert_eq(Big.new(-10_000_000).to_aa(), "-10.0m")
	assert_eq(Big.new(-99_999_999).to_aa(), "-99.9m")
	assert_eq(Big.new(-100_000_000).to_aa(), "-100m")
	assert_eq(Big.new(-999_999_999).to_aa(), "-999m")
	assert_eq(Big.new(-1_000_000_000).to_aa(), "-1.0b")
	assert_eq(Big.new(-9_999_999_999).to_aa(), "-9.9b")


func test_to_aa_billions_and_up_boundaries() -> void:
	assert_eq(Big.new(9.999_999_999e21).to_aa(), "9.9ac")
	assert_eq(Big.new(1.000_000_000e22).to_aa(), "10.0ac")
	assert_eq(Big.new(9.999_999_999e22).to_aa(), "99.9ac")
	assert_eq(Big.new(1.000_000_000e23).to_aa(), "100ac")
	assert_eq(Big.new(9.999_999_999e23).to_aa(), "999ac")
	assert_eq(Big.new(1.000_000_000e24).to_aa(), "1.0ad")


func test_to_aa_negative() -> void:
	assert_eq(Big.new(-3).to_aa(), "-3")
	assert_eq(Big.new(-32).to_aa(), "-32")
	assert_eq(Big.new(-325).to_aa(), "-325")
	assert_eq(Big.new(-3_257).to_aa(), "-3,257")
	assert_eq(Big.new(-32_570).to_aa(), "-32.5k")
	assert_eq(Big.new(-325_700).to_aa(), "-325k")
	assert_eq(Big.new(-3_257_000).to_aa(), "-3.2m")
	assert_eq(Big.new(-32_570_000).to_aa(), "-32.5m")
	assert_eq(Big.new(-325_700_000).to_aa(), "-325m")
	assert_eq(Big.new(-3_257_000_000).to_aa(), "-3.2b")


func test_to_aa_billions_and_up() -> void:
	assert_eq(Big.new(32.57e3).to_aa(), "32.5k")
	assert_eq(Big.new(32.57e6).to_aa(), "32.5m")
	assert_eq(Big.new(32.57e9).to_aa(), "32.5b")
	assert_eq(Big.new(32.57e12).to_aa(), "32.5t")
	assert_eq(Big.new(32.57e15).to_aa(), "32.5aa")
	assert_eq(Big.new(32.57e18).to_aa(), "32.5ab")
	assert_eq(Big.new(32.57e21).to_aa(), "32.5ac")
	assert_eq(Big.new(32.57e24).to_aa(), "32.5ad")
	assert_eq(Big.new(32.57e102).to_aa(), "32.5bd")
	assert_eq(Big.new(32.57e180).to_aa(), "32.5cd")


func test_sum() -> void:
	assert_almost_eq(Big.add(3, 5).to_float(), 8.0, 0.001)
	assert_almost_eq(Big.add(Big.new(3e18), Big.new(5e18)).to_float(), 8e18, 0.001)


func test_clamp() -> void:
	assert_eq(Big.clamp(3, 1, 5).to_int(), 3)
	assert_eq(Big.clamp(-1, 1, 5).to_int(), 1)
	assert_eq(Big.clamp(9, 1, 5).to_int(), 5)


func test_div() -> void:
	assert_eq(Big.div(9, 8).to_float(), 1.0)
	assert_eq(Big.div(25, 4).to_float(), 6.0)
	assert_eq(Big.div(-25, 4).to_float(), -6.0)
	assert_eq(Big.div(-25, -4).to_float(), 6.0)


func test_mul() -> void:
	assert_eq(Big.mul(9, 8).to_float(), 72.0)
	assert_eq(Big.mul(10, 0.9).to_float(), 0.0) # 0.9 is rounded to 0.
