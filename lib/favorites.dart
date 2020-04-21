import 'package:flutter/material.dart';
import 'database.dart';
import 'model/favorite.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final Set<String> _favorites = Set<String>();
  final dbHelper = DatabaseHelper.instance;
  Favorite fav;
  List<Favorite> favorites = new List();

  @override
  void initState() {
    super.initState();
    fav = new Favorite();
    dbHelper.list(fav).then((res) {
      setState(() {
        res.forEach((f) {
          print(f);
          favorites.add(new Favorite.fromMap(f));
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('Favoritos'),
          centerTitle: true,
          backgroundColor: Color(0xFFd4d4d4),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: 
              favorites.length == 0 ? Text('Nenhum registro encontrado :(', style: TextStyle(color: Colors.black),) :
              Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: new ListView.builder(
                      itemCount: favorites.length,
                      itemBuilder: (context, position) {
                        return Column(
                          children: <Widget>[
                            ListTile(
                              contentPadding: EdgeInsets.only(left: 10, right:10),
                              title: Text(
                                '${favorites[position].name}',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_forever, color: Colors.grey[700],), 
                                onPressed: () {_remove(position, favorites[position]);}
                              ),
                              onTap: () {
                                _open(favorites[position]);
                              }
                            ),
                            Divider(height: 5.0, color: Colors.grey[400],),
                          ],
                        );
                      }),
                  )
                ],
              )
            ),
          )
        ),
      );
  }

  _remove(int index, Favorite fav){
    dbHelper.deleteWhere(fav, '${fav.colId} = ?', [fav.id]).then((ret) {
      if(ret==0){
        _showSnackBar('Falha ao remover favorito.');
      }else{
        _showSnackBar('Favorito removido.');
        setState(() {
          favorites.removeAt(index);
        });
      }
    });
  }

  _open(Favorite fav){
    Navigator.pop(context, fav);
  }

  _showSnackBar(String msg){
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 3),
    ));
  }
}