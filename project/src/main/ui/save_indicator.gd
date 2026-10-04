extends CanvasLayer

const POP_DURATION: float = 0.15
const MIN_VISIBLE_DURATION: float = 1.0

var _play_tween: Tween
var _stop_tween: Tween

func _ready() -> void:
	PlayerSave.before_save.connect(play)
	PlayerSave.after_save.connect(stop)
	%Label.visible = false


## Shows the save indicator with a 'pop in' animation.
func play() -> void:
	if %Label.visible == true and not Utils.is_tween_running(_stop_tween):
		return
	
	if not %Label.visible:
		%Label.scale.x = 0.0
		%Label.visible = true
	
	_stop_tween = Utils.kill_tween(_stop_tween)
	_play_tween = Utils.recreate_tween(self, _play_tween)
	_play_tween.tween_property(%Label, "scale:x", 1.0, POP_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)


## Hides the save indicator with a 'pop out' animation.
func stop() -> void:
	if %Label.visible == false:
		return
	
	_stop_tween = Utils.recreate_tween(self, _stop_tween)
	_stop_tween.tween_interval(MIN_VISIBLE_DURATION)
	_stop_tween.tween_property(%Label, "scale:x", 0.0, POP_DURATION) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	_stop_tween.tween_callback(%Label.set.bind("visible", false))
