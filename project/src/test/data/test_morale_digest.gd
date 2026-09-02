extends GutTest

var digest: MoraleDigest = MoraleDigest.new()

func before_each() -> void:
	digest.reset()


func test_headline_builder() -> void:
	digest.add_headline(MoraleEvent.DAY_OFF).type(Gobs.WATER).pct(0.25)
	assert_almost_eq(digest.headlines[0].evaluate(gob("🔥 3")), 0.00, 0.01)
	assert_almost_eq(digest.headlines[0].evaluate(gob("💧 2")), 0.25, 0.01)


func test_convert_to_json_and_back() -> void:
	digest.add_headline(MoraleEvent.DAY_OFF).type(Gobs.WATER).pct(0.25)
	var result: Dictionary[String, Variant] = digest.to_json_dict()
	digest.reset()
	digest.from_json_dict(result)
	assert_eq(1, digest.headlines.size())
	assert_almost_eq(digest.headlines[0].evaluate(gob("🔥 3")), 0.00, 0.01)
	assert_almost_eq(digest.headlines[0].evaluate(gob("💧 2")), 0.25, 0.01)


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)
