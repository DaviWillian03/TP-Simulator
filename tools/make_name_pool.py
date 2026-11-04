"""Gera game/data/name_pool.json: nomes e sobrenomes por nacionalidade para pilotos FICTÍCIOS que surgem ao longo
da campanha (regens) e para técnicos genéricos. Evita sobrenomes de pessoas conhecidas da F1/F2/F3 atual.
Uso: python tools/make_name_pool.py
"""
import json
import pathlib

OUT = pathlib.Path(__file__).resolve().parent.parent / "game" / "data" / "name_pool.json"
POOL = {
    "Brasil": (["Thiago", "Caio", "Rafaela", "Murilo", "Enzo", "Davi", "Lorenzo", "Bernardo", "Heitor", "Iago"],
               ["Albuquerque", "Bragança", "Cavalcanti", "Damasceno", "Esteves", "Figueiró", "Guimarães", "Lacerda", "Moraes", "Teixeira"]),
    "Reino Unido": (["Archie", "Finley", "Isla", "Harvey", "Jude", "Ollie", "Rory", "Seb", "Theo", "Elliot"],
                    ["Ashworth", "Blackwood", "Cartwright", "Davenport", "Fairbairn", "Gillespie", "Holloway", "Kingsley", "Pickering", "Radcliffe"]),
    "Itália": (["Alessio", "Christian", "Davide", "Edoardo", "Filippo", "Leonardo", "Nicolò", "Riccardo", "Samuele", "Tommaso"],
               ["Benedetti", "Caruso", "D'Amico", "Fabbri", "Gallo", "Lombardi", "Marchetti", "Orlandi", "Pellegrini", "Valentini"]),
    "França": (["Arthur", "Baptiste", "Clément", "Gabin", "Louis", "Maël", "Nathan", "Raphaël", "Timéo", "Yanis"],
               ["Aubert", "Barbier", "Chevalier", "Dumont", "Fontaine", "Guérin", "Lemaire", "Mercier", "Perrin", "Renaud"]),
    "Alemanha": (["Ben", "Elias", "Felix", "Henry", "Jakob", "Leon", "Moritz", "Niklas", "Paul", "Tim"],
                 ["Albrecht", "Baumann", "Dietrich", "Engel", "Hartmann", "Kessler", "Lorenz", "Pohl", "Seidel", "Winter"]),
    "Espanha": (["Adrián", "Bruno", "Gonzalo", "Hugo", "Iker", "Marc", "Nil", "Pau", "Rubén", "Unai"],
                ["Aguilar", "Bermejo", "Castaño", "Delgado", "Escudero", "Ferrer", "Garrido", "Herrero", "Lozano", "Vidal"]),
    "Países Baixos": (["Bram", "Daan", "Jesse", "Lars", "Milan", "Noah", "Ruben", "Sem", "Thijs", "Tygo"],
                      ["Bakker", "Dekker", "Hendriks", "Jansen", "Kuipers", "Meijer", "Smit", "Visser", "Wouters", "Zijlstra"]),
    "Japão": (["Haruki", "Itsuki", "Kaito", "Minato", "Ren", "Riku", "Sora", "Takumi", "Yuto", "Hayato"],
              ["Aoki", "Fujita", "Hasegawa", "Kimura", "Kobayashi", "Matsuda", "Okada", "Sakamoto", "Shimizu", "Yamaguchi"]),
    "Estados Unidos": (["Brody", "Carter", "Dylan", "Grayson", "Hunter", "Logan", "Mason", "Parker", "Ryder", "Tyler"],
                       ["Bennett", "Coleman", "Donovan", "Fletcher", "Garrison", "Holt", "McAllister", "Prescott", "Sullivan", "Whitaker"]),
    "Austrália": (["Cooper", "Flynn", "Hamish", "Jai", "Lachlan", "Mitchell", "Riley", "Tate", "Zac", "Angus"],
                  ["Ashby", "Brennan", "Crowley", "Dunstan", "Galloway", "Hennessy", "Kerr", "Macleod", "O'Connell", "Tremayne"]),
    "México": (["Santiago", "Mateo", "Emiliano", "Diego", "Regina", "Iker", "Rodrigo", "Patricio", "Andrés", "Leonel"],
               ["Arriaga", "Beltrán", "Cervantes", "Durán", "Escobedo", "Fuentes", "Galindo", "Ochoa", "Quiroga", "Zamora"]),
    "Argentina": (["Bautista", "Benjamín", "Joaquín", "Lautaro", "Máximo", "Nahuel", "Santino", "Tobías", "Valentino", "Thiago"],
                  ["Acosta", "Bustos", "Cabrera", "Domínguez", "Funes", "Godoy", "Ledesma", "Ojeda", "Paz", "Sosa"]),
    "China": (["Hao", "Jun", "Lei", "Ming", "Rui", "Tian", "Wei", "Xuan", "Yu", "Zhen"],
              ["Chen", "Deng", "Guo", "He", "Lin", "Luo", "Song", "Tang", "Xu", "Zhao"]),
    "Finlândia": (["Aleksi", "Eetu", "Joona", "Leevi", "Niko", "Onni", "Rasmus", "Santeri", "Veeti", "Väinö"],
                  ["Aaltonen", "Heikkinen", "Kallio", "Laine", "Lehtinen", "Nieminen", "Rantanen", "Salonen", "Tuominen", "Virtanen"]),
    "Dinamarca": (["Anton", "August", "Emil", "Frederik", "Magnus", "Malthe", "Oscar", "Viktor", "William", "Asger"],
                  ["Andersen", "Christiansen", "Frandsen", "Holm", "Kjær", "Lauridsen", "Mikkelsen", "Nygaard", "Poulsen", "Skov"]),
    "Polônia": (["Bartosz", "Filip", "Igor", "Jakub", "Kacper", "Mikołaj", "Oskar", "Szymon", "Wiktor", "Antoni"],
                ["Adamczyk", "Bielecki", "Czarnecki", "Dudek", "Górski", "Jankowski", "Kowalczyk", "Michalski", "Sobczak", "Wróbel"]),
}
OUT.write_text(json.dumps({"_notas": "FICTÍCIO. Nomes para pilotos novos (regens) e técnicos genéricos. tools/make_name_pool.py",
                           "nationalities": {k: {"first": v[0], "last": v[1]} for k, v in POOL.items()}}, ensure_ascii=False, indent=1), encoding="utf-8")
print("ok", len(POOL))
