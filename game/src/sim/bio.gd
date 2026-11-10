class_name Bio
extends RefCounted
## Resumos curtos de pilotos e técnicos montados SÓ com dados que o jogo já tem (nada inventado): país, idade, equipe,
## carreira e potencial. Mostrados na ficha do piloto e na tela de Pessoal.


static func driver(p: Dictionary, season: int) -> String:
	var parts: Array[String] = []
	var age := DriverStats.age(p, season)
	var nat := String(p.get("nationality", ""))
	parts.append("%s, %d anos." % [nat, age] if age > 0 else "%s." % nat)
	if p.has("career"):  # F1: números da carreira
		var c: Dictionary = p["career"]
		var s := "%d largadas, %d vitórias, %d pódios" % [int(c.get("starts", 0)), int(c.get("wins", 0)), int(c.get("podiums", 0))]
		if int(c.get("poles", 0)) > 0:
			s += ", %d poles" % int(c["poles"])
		parts.append(s + ".")
		if int(p.get("titles", 0)) > 0:
			parts.append("%d título%s mundia%s." % [int(p["titles"]), "" if int(p["titles"]) == 1 else "s", "l" if int(p["titles"]) == 1 else "is"])
	elif p.has("category"):  # F2/F3
		parts.append("Corre na %s pela %s." % [String(p["category"]), String(p.get("series_team", "—"))])
		if p.has("potential"):
			parts.append("Nota %d, potencial %d." % [int(p.get("rating", 0)), int(p["potential"])])
	return " ".join(parts)


static func staff(person: Dictionary, team_name: String) -> String:
	var role := String(Personnel.ROLE_NAMES.get(person.get("role", ""), "Técnico"))
	var s := role if team_name == "" else "%s da %s" % [role, team_name]
	s += ". " + String(person.get("nationality", ""))
	s += "." if not s.ends_with(".") else ""
	if bool(person.get("real", false)):
		s += " Nome real, nota estimada pelo jogo."
	return s
