@tool
class_name Big extends Resource

const MIN_INT: int = -999_999_999_999_999_999
const MAX_INT: int = 999_999_999_999_999_999

const ALPHABET: String = "bcdfghjklmnpqrstvwxyz"

static var ZERO: Big = Big.new(0)
static var ONE: Big = Big.new(1)

static var _suffixes_aa: Dictionary[int, String] = {
	0: "",
	1: "k", # thousand (kilo)
	2: "m", # million
	3: "b", # billion
	4: "t", # trillion
	5: "q", # quadrillion
	6: "z", # zillion
	7: "bj", # a bajillion
}

var _value: float

func _init(m: Variant) -> void:
	match typeof(m):
		TYPE_FLOAT:
			_value = Utils.trunc(m)
		TYPE_INT:
			_value = float(m)
		_:
			push_warning("Unrecognized type: %s" % [typeof(m)])


func to_float() -> float:
	return _value


func to_int() -> int:
	@warning_ignore("narrowing_conversion")
	return clamp(_value, MIN_INT, MAX_INT)


func to_aa() -> String:
	if is_nan(_value):
		return "nan"
	if is_inf(_value):
		return "-inf" if _value < 0.0 else "inf"
	
	# calculate abs_value, mantissa
	var abs_value: float = abs(_value)
	var exponent: float = floor(log(abs_value) / log(10)) # 3,257 = 3.2 * 10e3; exponent = 3
	var suffix_key: int = 0 if exponent < 4 else floori(exponent / 3.0)
	var mantissa: float = abs_value * pow(0.1, suffix_key * 3.0)
	if suffix_key >= 1 and mantissa >= 1000.0:
		suffix_key += 1
		mantissa *= 0.001
	
	var result: String = ""
	if mantissa < 100:
		var fpart: float = mantissa - floor(mantissa)
		if fpart != 0.0:
			result = ".%d" % [floor(fpart * 10)]
	var ipart: float = floor(mantissa)
	while ipart >= 1000:
		result = ",%03d%s" % [fmod(ipart, 1000), result]
		ipart = floor(ipart / 1000)
	
	if not _suffixes_aa.has(suffix_key):
		var offset: int = (suffix_key - 1) % 21
		@warning_ignore("integer_division")
		var base: int = ((suffix_key - 1) / 21)
		_suffixes_aa[suffix_key] = "%s%s" % [ALPHABET[base], ALPHABET[offset]]
	var suffix: String = _suffixes_aa[suffix_key]
	result = "%d%s%s" % [ipart, result, suffix]
	if _value < 0:
		result = "%s%s" % ["-", result]
	
	return result


func is_eq(n: Variant) -> bool:
	n = _type_check(n)
	return is_equal_approx(_value, n._value)


func is_ne(n: Variant) -> bool:
	n = _type_check(n)
	return not is_equal_approx(_value, n._value)


func is_gt(n: Variant) -> bool:
	n = _type_check(n)
	return _value > n._value


func is_gte(n: Variant) -> bool:
	n = _type_check(n)
	return _value > n._value or is_equal_approx(_value, n._value)


func is_lt(n: Variant) -> bool:
	n = _type_check(n)
	return _value < n._value


func is_lte(n: Variant) -> bool:
	n = _type_check(n)
	return _value < n._value or is_equal_approx(_value, n._value)


func _to_string() -> String:
	return str(_value)


static func add(x: Variant, y: Variant) -> Big:
	x = _type_check(x)
	y = _type_check(y)
	return new(x._value + y._value)


static func sub(x: Variant, y: Variant) -> Big:
	x = _type_check(x)
	y = _type_check(y)
	return new(x._value - y._value)


static func mul(x: Variant, y: Variant) -> Big:
	x = _type_check(x)
	y = _type_check(y)
	return new(x._value * y._value)


static func div(x: Variant, y: Variant) -> Big:
	x = _type_check(x)
	y = _type_check(y)
	return new(x._value / y._value)


static func mod(x: Variant, y: Variant) -> Big:
	x = _type_check(x)
	y = _type_check(y)
	return new(fmod(x._value, y._value))


static func max(x: Variant, y: Variant) -> Big:
	x = _type_check(x)
	y = _type_check(y)
	return x if x._value > y._value else y


static func min(x: Variant, y: Variant) -> Big:
	x = _type_check(x)
	y = _type_check(y)
	return x if x._value < y._value else y


@warning_ignore("shadowed_global_identifier")
static func clamp(n: Variant, min: Variant, max: Variant) -> Big:
	n = _type_check(n)
	min = _type_check(min)
	max = _type_check(max)
	return new(clamp(n._value, min._value, max._value))


static func _type_check(n: Variant) -> Big:
	return n if n is Big else Big.new(n)
