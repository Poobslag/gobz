class_name StringUtils
## Utility class for string operations.
##
## Where possible, these functions mimic the style of org.apache.commons.lang3.StringUtils.

## Formats a number with commas like '1,234,567'.
static func comma_sep(n: int) -> String:
	var result := ""
	var i: int = abs(n)
	
	while i > 999:
		result = ",%03d%s" % [i % 1000, result]
		i /= 1000
	
	return "%s%s%s" % ["-" if n < 0 else "", i, result]
