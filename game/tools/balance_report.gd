extends SceneTree
## Calibra o equilíbrio de forças: simula vários GPs e imprime quanto do resultado (posição final) vem do CARRO,
## do PILOTO e do que sobra (decisões da gerência, estratégia, tráfego, incidentes e acaso).
##
## Meta do usuário (2026-11-03): ~55% carro, ~25% piloto, ~20% o resto.
##
## Método: regressão da posição final em (força do carro naquele GP, já com a forma do fim de semana) e (nota geral do
## piloto). O R² total é dividido entre os dois pela regra de Shapley (corrige a correlação entre bons pilotos e bons
## carros); o que ficou sem explicação é o "resto".
##
## Uso (na pasta game/):
##   godot --headless -s tools/balance_report.gd -- --weekends=30 --incidents=1 --weather=random
## Opções: --seed0=<n> (vários processos em paralelo), --format=race_only|full, --pct=<0..1>, --dump=<arquivo.json>
## (grava as amostras brutas para agregar vários processos com tools/balance_merge.py).

const CIRCUITS := ["interlagos", "monza", "spa", "silverstone", "suzuka", "barcelona", "austin", "hungaroring", "zandvoort", "montreal"]


func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var n := int(args.get("weekends", "30"))
	var seed0 := int(args.get("seed0", "1"))
	var incidents := float(args.get("incidents", "1"))
	var form := float(args.get("form", "1"))
	var weather := String(args.get("weather", "random"))
	var pct := float(args.get("pct", "0.5"))
	var format := String(args.get("format", "race_only"))

	var overall := {}
	var team_of := {}
	for d: Dictionary in GameData.drivers():
		overall[d["id"]] = DriverStats.overall(d)
		team_of[d["id"]] = d["team"]
	var samples: Array = []  # [posição, força do carro, nota do piloto, abandonou]
	var team_pos := {}
	var team_pts := {}
	var winners := {}
	var dnf_total := 0
	var pole_win := 0
	var t0 := Time.get_ticks_msec()
	for i in n:
		var opts := {"seed": seed0 + i, "incident_rate": incidents, "form": form, "duration_pct": pct, "format": format}
		if weather != "random":
			opts["weather"] = weather
		var w := WeekendSim.new(CIRCUITS[i % CIRCUITS.size()], opts)
		while not w.is_over():
			w.simulate_current()
		var order: Array = w.results["race"]
		var car_eff := {}
		for t: Dictionary in w.teams:
			car_eff[t["id"]] = float(t["car_rating"])
		var grid: Array = w.grids.get("race", [])
		if not grid.is_empty() and grid[0] == order[0]:
			pole_win += 1
		winners[team_of[order[0]]] = int(winners.get(team_of[order[0]], 0)) + 1
		var sums := {}
		var counts := {}
		for p in order.size():
			var did: String = order[p]
			var tid: String = team_of[did]
			samples.append([float(p + 1), car_eff[tid], overall[did]])
			sums[tid] = float(sums.get(tid, 0.0)) + p + 1
			counts[tid] = int(counts.get(tid, 0)) + 1
			team_pts[tid] = float(team_pts.get(tid, 0.0)) + w.points_for(p + 1, false)
		for tid: String in sums:
			if not team_pos.has(tid):
				team_pos[tid] = []
			team_pos[tid].append(sums[tid] / counts[tid])
		dnf_total += int(w.dnf_count) if "dnf_count" in w else 0

	if args.has("dump"):
		var f := FileAccess.open(String(args["dump"]), FileAccess.WRITE)
		f.store_string(JSON.stringify(samples))
	var sh := shapley(samples)
	print("\n=== %d GPs | incidentes x%.1f | forma x%.1f | clima %s | %d%% da corrida | %d ms ===" % [n, incidents, form, weather, int(pct * 100), Time.get_ticks_msec() - t0])
	print("CARRO %4.1f%%   PILOTO %4.1f%%   RESTO %4.1f%%   (R² total %.2f)" % [100 * sh[0], 100 * sh[1], 100 * sh[2], sh[3]])
	print("pole venceu: %d/%d | vencedores por equipe: %s" % [pole_win, n, winners])
	var rows: Array = []
	for tid: String in team_pos:
		var a: Array = team_pos[tid]
		rows.append([_mean(a), tid, team_pts[tid] / n, _min(a), _max(a)])
	rows.sort()
	for r: Array in rows:
		print("  %-12s pos média %5.2f (melhor GP %4.1f, pior %4.1f) | pontos/GP %5.1f" % [r[1], r[0], r[3], r[4], r[2]])
	quit()


## samples: [[y, x1, x2], ...]. Devolve [parte do x1, parte do x2, resto, R² total].
static func shapley(samples: Array) -> Array:
	var r2_1 := r2(samples, true, false)
	var r2_2 := r2(samples, false, true)
	var r2_12 := r2(samples, true, true)
	var s1 := 0.5 * (r2_1 + (r2_12 - r2_2))
	var s2 := 0.5 * (r2_2 + (r2_12 - r2_1))
	return [s1, s2, 1.0 - r2_12, r2_12]


## R² da regressão linear de y em x1 e/ou x2 (mínimos quadrados, equações normais).
static func r2(samples: Array, use1: bool, use2: bool) -> float:
	var n := float(samples.size())
	var my := 0.0
	var m1 := 0.0
	var m2 := 0.0
	for s: Array in samples:
		my += s[0]
		m1 += s[1]
		m2 += s[2]
	my /= n
	m1 /= n
	m2 /= n
	var syy := 0.0
	var s11 := 0.0
	var s22 := 0.0
	var s12 := 0.0
	var s1y := 0.0
	var s2y := 0.0
	for s: Array in samples:
		var y: float = s[0] - my
		var a: float = s[1] - m1
		var b: float = s[2] - m2
		syy += y * y
		s11 += a * a
		s22 += b * b
		s12 += a * b
		s1y += a * y
		s2y += b * y
	if use1 and use2:
		var det := s11 * s22 - s12 * s12
		if absf(det) < 1e-9:
			return 0.0
		var b1 := (s1y * s22 - s2y * s12) / det
		var b2 := (s2y * s11 - s1y * s12) / det
		return (b1 * s1y + b2 * s2y) / syy
	if use1:
		return s1y * s1y / (s11 * syy)
	return s2y * s2y / (s22 * syy)


func _mean(a: Array) -> float:
	var s := 0.0
	for x in a:
		s += float(x)
	return s / maxf(a.size(), 1)


func _min(a: Array) -> float:
	var m := 1e9
	for x in a:
		m = minf(m, float(x))
	return m


func _max(a: Array) -> float:
	var m := -1e9
	for x in a:
		m = maxf(m, float(x))
	return m
