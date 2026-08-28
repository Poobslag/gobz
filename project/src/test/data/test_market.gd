extends GutTest

func test_round_to_sig_figs() -> void:
	assert_eq(Market.round_to_sig_figs(0.0, 1), 0.0)
	assert_eq(Market.round_to_sig_figs(123.0, 1), 100.0)
	assert_eq(Market.round_to_sig_figs(456.0, 2), 460.0)
	assert_eq(Market.round_to_sig_figs(-123.0, 1), -100.0)
	assert_eq(Market.round_to_sig_figs(-456.0, 2), -460.0)


func test_round_to_sig_figs_small() -> void:
	assert_eq(Market.round_to_sig_figs(0.123_456_789, 1), 0.100_000_000)
	assert_eq(Market.round_to_sig_figs(0.123_456_789, 2), 0.120_000_000)
	assert_eq(Market.round_to_sig_figs(0.123_456_789, 3), 0.123_000_000)
	assert_eq(Market.round_to_sig_figs(0.123_456_789, 6), 0.123_457_000)


func test_round_to_sig_figs_big() -> void:
	assert_eq(Market.round_to_sig_figs(123_456_789, 1), 100_000_000.0)
	assert_eq(Market.round_to_sig_figs(123_456_789, 2), 120_000_000.0)
	assert_eq(Market.round_to_sig_figs(123_456_789, 3), 123_000_000.0)
	assert_eq(Market.round_to_sig_figs(123_456_789, 6), 123_457_000.0)


func test_round_to_sig_figs_border() -> void:
	assert_eq(Market.round_to_sig_figs(449.999, 1), 400.000)
	assert_eq(Market.round_to_sig_figs(450.000, 1), 500.000)
	
	assert_eq(Market.round_to_sig_figs(0.0149, 1), 0.0100)
	assert_eq(Market.round_to_sig_figs(0.0150, 1), 0.0200)
