class_name AllCaps
extends RefCounted
## Caixa alta no jogo inteiro (decisão do usuário: "tudo em caixa alta").
## Em vez de mexer em centenas de textos, olhamos cada nó que entra na árvore:
## - Label tem a propriedade `uppercase` (só muda o desenho; `text` continua igual, então
##   os testes e o código que leem `text` não mudam);
## - Button não tem, então passamos o próprio `text` para maiúsculas quando ele entra e
##   sempre que for redesenhado (texto trocado depois pelo código também é pego).
## Um nó com a meta "keep_case" fica como está (ex.: algo digitado pelo jogador).


static func install(tree: SceneTree) -> void:
	tree.node_added.connect(_on_node_added)


static func _on_node_added(n: Node) -> void:
	if n.has_meta("keep_case"):
		return
	if n is Label:
		(n as Label).uppercase = true
	elif n is Button:
		var b := n as Button
		_upper_button.call_deferred(b)
		if not b.has_meta("_all_caps"):  # o botão pode sair e voltar à árvore: liga uma vez só
			b.set_meta("_all_caps", true)
			b.draw.connect(_upper_button.bind(b).call_deferred)


## O argumento não é tipado: a chamada adiada pode chegar depois de o botão ser liberado.
static func _upper_button(obj: Variant) -> void:
	if not is_instance_valid(obj) or not obj is Button:
		return
	var b := obj as Button
	if b.has_meta("keep_case"):
		return
	var up := b.text.to_upper()
	if up != b.text:
		b.text = up
