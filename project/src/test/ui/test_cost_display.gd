extends GutTest

func before_each() -> void:
	PlayerData.reset()


func test_amount_from_cost() -> void:
	PlayerData.peak_gold = Big.new(1_000)
	assert_eq(CostDisplay.amount_from_cost(Big.new(1)), CostDisplay.COINS_1)
	assert_eq(CostDisplay.amount_from_cost(Big.new(9)), CostDisplay.COINS_1)
	assert_eq(CostDisplay.amount_from_cost(Big.new(29)), CostDisplay.COINS_2)
	assert_eq(CostDisplay.amount_from_cost(Big.new(49)), CostDisplay.COINS_3)
	assert_eq(CostDisplay.amount_from_cost(Big.new(69)), CostDisplay.COINS_5)
	assert_eq(CostDisplay.amount_from_cost(Big.new(99)), CostDisplay.BAGS_1)
	assert_eq(CostDisplay.amount_from_cost(Big.new(299)), CostDisplay.BAGS_2)
	assert_eq(CostDisplay.amount_from_cost(Big.new(499)), CostDisplay.BAGS_3)
	assert_eq(CostDisplay.amount_from_cost(Big.new(501)), CostDisplay.BAGS_5)
