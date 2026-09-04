class_name Party

var name: String
var prompt: String
var likers: Array[Gobs.Type]
var dislikers: Array[Gobs.Type]

## Scales both the delta and pct of the party. This means a value of 0.5 will leave 25% of the original effect (half
## the magnitude, applied to half the goblins)
var nerf_factor: float = 1.0

func _init(init_name: String) -> void:
	name = init_name


func execute() -> String:
	return ""
