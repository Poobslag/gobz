class_name GoblinNames

enum Gender {
	NONE,
	MALE,
	FEMALE,
}

## Vowels
const V1 = ["a","a","a","a","a","e","e","e","e","i","i","i","o","o","o","u","u","u","u","y","aa",
		"ea","ee","ia","ie","io","oi","oi","ui"]

## Male consonants
const M1 = ["","","","","","","","b","c","d","f","g","h","j","k","l","p","r","t","v","w","x","z",
		"bl","br","ch","cl","cr","dr","fr","gl","gn","gr","kl","kr","pl","pr","sl","sr","st","str",
		"tr","vr","wr","zr"]
const M2 = ["","b","b","b","b","d","d","d","d","g","g","g","g","h","h","h","h","k","k","k","k","l",
		"l","l","l","m","m","m","m","n","n","n","n","r","r","r","r","s","s","s","s","t","t","t",
		"t","v","v","v","v","z","z","z","z","bb","bbn","bd","bh","bk","bl","bn","br","bs","bt",
		"bz","db","dd","df","dh","dl","dn","dr","ds","dv","dz","gb","gd","gg","ggn","gh","gk","gl",
		"gm","gn","gr","gs","gt","gz","hb","hd","hk","hn","hz","kk","kl","kn","kv","kz","lb","ld",
		"lg","lk","ll","lr","ls","lt","lv","lz","mr","mt","mv","mz","nr","nt","nv","nz","rb","rd",
		"rg","rk","rl","rm","rn","rr","rs","rt","rv","rz","sb","sd","sh","sk","sm","sn","sr","ss",
		"st","str","sv","sz","tb","tl","tm","tn","tr","tt","tv","tz","vl","vn","vr","vz","xb","xd",
		"xg","xl","xm","xn","xt","zb","zd","zg","zl","zm","zn","zt"]
const M3 = ["c","g","k","k","l","q","r","t","x","x","z","z","bs","cs","ct","gs","gz","kt","kx",
		"kz","lb","ld","llk","lk","lx","ng","nk","rd","rd","rk","rm","rt","rx","s","sb","sz","ts",
		"zz"]

## Female consonants
const F1 = ["","","","","","","","b","c","d","f","g","h","j","k","l","m","n","p","q","r","s","t",
		"v","w","bh","bl","br","ch","cl","cr","fl","fr","gl","gn","gr","kh","kl","ng","ph","pr",
		"sh","sl","sr","st","sw","th","thr","tr","vr","wr"]
const F2 = ["b","b","b","b","f","f","f","f","g","g","g","g","h","h","h","h","k","k","k","k","l",
		"l","l","l","m","m","m","m","n","n","n","n","p","p","p","p","r","r","r","r","s","s","s",
		"s","t","t","t","t","v","v","v","v","bb","bbn","bd","bh","bk","bl","bn","br","bs","bt",
		"bz","fb","fl","fm","fn","fs","ft","gb","gd","gg","ggn","gh","gk","gl","gm","gn","gr","gs",
		"gt","gz","hb","hd","hk","hn","hz","kk","kl","kn","kv","kz","lb","ld","lg","lk","ll","lr",
		"ls","lt","lv","lz","mr","mt","mv","mz","nr","nt","nv","nz","pf","ph","pl","pm","pn","pr",
		"ps","pt","pv","rb","rd","rg","rk","rl","rm","rn","rr","rs","rt","rv","rz","sb","sd","sh",
		"sk","sm","sn","sr","ss","st","str","sv","sz","tb","tl","tm","tn","tr","tt","tv","tz","vl",
		"vn","vr","vz"]
const F3 = ["f","g","h","l","n","q","s","x","z","fs","ft","fz","gs","hx","ld","lk","lm","ls","lt",
		"lx","ng","nk","nq","ns","nx","rt","rx","sh","ss","sx","sz","th","zz"]
const F4 = ["","","","","","","","","","","","","","a","ai","e","ea","ee","i","ia"]

const MALE: Gender = Gender.MALE
const FEMALE: Gender = Gender.FEMALE
const NONE: Gender = Gender.NONE

static func random_name(gender: Gender = Gender.NONE) -> String:
	var name: String = ""
	if gender == Gender.NONE:
		gender = Gender.MALE if randf() < 0.5 else Gender.FEMALE
	if gender == Gender.FEMALE:
		if randf() < 0.5:
			# short female names
			name = F1.pick_random() + V1.pick_random() + F3.pick_random() + F4.pick_random()
		else:
			# long female names
			name = F1.pick_random() + V1.pick_random() + F2.pick_random() + V1.pick_random() \
					+ F3.pick_random() + F4.pick_random()
	else:
		if randf() < 0.5:
			# short male names
			name = M1.pick_random() + V1.pick_random() + M3.pick_random()
		else:
			# long male names
			name = M1.pick_random() + V1.pick_random() + M2.pick_random() + V1.pick_random() \
					+ M3.pick_random()
	return name.capitalize()
