extends GutTest

func test_abbr_num() -> void:
	assert_eq(Utils.abbr_num(3_257), "3,257")
	assert_eq(Utils.abbr_num(325_700), "325k")
	assert_eq(Utils.abbr_num(32_570_000), "32.5m")
	assert_eq(Utils.abbr_num(3_257_000_000), "3,257m")
	assert_eq(Utils.abbr_num(325_700_000_000), "325b")
	assert_eq(Utils.abbr_num(32_570_000_000_000), "32.5t")
	assert_eq(Utils.abbr_num(32_570_000_000_000_000), "32.5q")
	assert_eq(Utils.abbr_num(3_257_000_000_000_000_000), "@!#,%&!")
