import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

// Para usar o plugin path_provider
import 'package:path_provider/path_provider.dart';

// Função principal
void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  // Gera o controlador do input
  final _toDoController = TextEditingController();

  // Minhas tarefas
  List _toDoList = [];

  // Ultimo item removido
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  // Buscar as tarefas salvas no meu celular
  @override
  void initState() {
    super.initState();

    // Pega as tarefas
    _readData().then((data){
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  // Adiciona itens a lista
  void _addToDo() {
    // Atualiza o estado da tela
    setState(() {
      // Cria uma lista do tipo Map
      Map<String, dynamic> newToDo = Map();

      // Seta os valores
      newToDo["title"] = _toDoController.text;
      newToDo["ok"]    = false;
      _toDoList.add(newToDo);

      // Limpa o input
      _toDoController.text = ""; 

      // Salva os dados permanentemente
      _saveData();
    });
  }

  // Atualiza uma tarefa
  void _updateTask(index, value) {
    setState(() {
      // Seta o valor do checkbox
      _toDoList[index]["ok"] = value;

      // Salva os dados permanentemente
      _saveData();
    });
  }

  // Remove um item da lista
  void _removeTask(index) {
    _lastRemoved = Map.from(_toDoList[index]);
    _lastRemovedPos = index;
    _toDoList.removeAt(index);
    _saveData();
  }

  // Atualiza a lista
  Future<Null> _refresh() async {
    // Espera 1seg para realizar a ação
    await Future.delayed(Duration(seconds: 1));

    // Faz a ordenação
    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }
    

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded( // Serve para definir a largura do input sem isso da erro
                  child: TextField(
                      controller: _toDoController,
                      decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(    // Gera a lista
                padding: EdgeInsets.only(top: 10.0),
                itemCount: _toDoList.length,
                itemBuilder: buildItem
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Monta a minha lista de tarefas
  Widget buildItem(context, index) {
    // Permite que arrastemos um item para o lado
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile( // Item da lista
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(
            _toDoList[index]["ok"] ? Icons.check : Icons.error
          ),
        ),
        onChanged: (value) => _updateTask(index, value),
      ),
      onDismissed: (direction) {
        setState(() {
          _removeTask(index);

          // Cria o snack bar
          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );

          // Mostra o snackbar na tela
          Scaffold.of(context).removeCurrentSnackBar(); 
          Scaffold.of(context).showSnackBar(snack);
        });
      } ,
    );
  }

  // Busca o arquivo json
  Future<File> _getFile() async{
    
    // Busca o diretorio do arquivo
    final directory = await getApplicationDocumentsDirectory();

    // Retorna o caminho do meu arquivo
    return File("${directory.path}/data.json");
  } 

  // Salva os dados
  Future<File> _saveData() async{
    // Converte a lista em json
    String data = json.encode(_toDoList);

    // Pega o arquivo json
    final file = await _getFile();

    // Salva a lista no arquivo json
    return file.writeAsString(data);
  }

  // Obtem os dados
  Future<String> _readData() async{
    try{
      // Busca o arquivo
      final file = await _getFile();

      // Ler o arquivo
      return file.readAsString();
    }catch(e) {
      return null;
    }
  }
}
