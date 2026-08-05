extends GutTest

func test_abbr_num() -> void:
	assert_eq(Utils.abbr_num(3_257), "3,257")
	assert_eq(Utils.abbr_num(325_700), "325,700")
	assert_eq(Utils.abbr_num(32_570_000), "32,570k")
	assert_eq(Utils.abbr_num(3_257_000_000), "3,257m")
	assert_eq(Utils.abbr_num(325_700_000_000), "325,700m")
	assert_eq(Utils.abbr_num(32_570_000_000_000), "32,570b")
	assert_eq(Utils.abbr_num(32_570_000_000_000_000), "32,570t")
	assert_eq(Utils.abbr_num(3_257_000_000_000_000_000), "@!#,%&!")
