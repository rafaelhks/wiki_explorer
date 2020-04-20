import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'database.dart';
import 'favorites.dart';
import 'model/favorite.dart';

class WikipediaExplorer extends StatefulWidget {
  String initURL = 'https://pt.wikipedia.org/';

  WikipediaExplorer();

  WikipediaExplorer.fromURL(String url){
    initURL = url;
  }

  @override
  _WikipediaExplorerState createState() => _WikipediaExplorerState();
}

class _WikipediaExplorerState extends State<WikipediaExplorer> {
  Completer<WebViewController> _controller = Completer<WebViewController>();
  WebViewController _wvController;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  final Set<String> _favorites = Set<String>();
  final dbHelper = DatabaseHelper.instance;
  Favorite fav;

  @override
  void initState() {
    super.initState();
    fav = new Favorite();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      // appBar: AppBar(
      //   backgroundColor: Color(0xFFd4d4d4),
      //   title: const Text('Wikipedia Explorer', style: TextStyle(color: Color(0xFF4f4f4f)),),
      //   // actions: <Widget>[
      //   //     // action button
      //   //     IconButton(
      //   //       icon: Icon(Icons.bookmark, color: Color(0xFF4f4f4f),),
      //   //       onPressed: () {
      //   //         Navigator.push(context, MaterialPageRoute(builder: (context) => new FavoritesPage()));
      //   //       },
      //   //     ),
      //   // ]
      // ),
      body: new SafeArea(
        child: WebView(
          initialUrl: widget.initURL,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
            setState(() {
              _wvController = webViewController;
            });
          },
          onPageFinished: (String url) {
              //Navigator.of(_keyLoader.currentContext, rootNavigator: true).pop();
              _defineIfIsFav(url);
          },
          onPageStarted: (String url){
            //showLoadingDialog(context);
          },
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: _interceptNavigation,
        ),
      ),
      //floatingActionButton: _bookmarkButton(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {_bottomItemTap(index);},
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark, color: Color(0xFF4f4f4f),),
            title: Text('Favoritos'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: _isFav() ? Colors.red : Color(0xFF4f4f4f)),
            title: Text(_isFav() ? 'Remover' : 'Salvar'),
          ),
        ],
      ),
    );
  }

  _bookmarkButton() {
    return FutureBuilder<WebViewController>(
      future: _controller.future,
      builder:
          (BuildContext context, AsyncSnapshot<WebViewController> controller) {
        if (controller.hasData) {
          return FloatingActionButton(
            backgroundColor: Color(0xFFd4d4d4),
            onPressed: () async {
              _favoriteCurrent();
            },
            child: Icon(Icons.favorite, color: _isFav() ? Colors.red : Color(0xFF4f4f4f)),
          );
        }
        return Container();
      },
    );
  }

  _bottomItemTap(index) async {
    if(index==0){
      Favorite result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FavoritesPage()),
      );
      if(result != null){
        setState(() {
          _wvController.loadUrl(result.link);
          fav = result;
        });
      }

      _defineIfIsFav(fav.link);
    }
    else if(index==1){
      _favoriteCurrent();
    }
  }

  _isFav(){
    return fav.id!=null && fav.id>0;
  }

  _defineIfIsFav(String url){
    dbHelper.listWhere(fav, "${fav.colLink} = '$url'").then((res) {
      if(res!=null && res.length>0){
        setState(() {
          fav = new Favorite.fromMap(res[0]);
        });
      }else{
        setState(() {
          fav = new Favorite();
        });
      }
      print('Resultado: $res');
    });
  }

  _favoriteCurrent() async{
    String url = await _wvController.currentUrl();
    String name = await _wvController.getTitle();

    if(_isFav()){
      dbHelper.deleteWhere(fav, '${fav.colLink} = ?', [url]).then((ret) {
        if(ret==0){
          _showSnackBar('Falha ao remover favorito.');
        }else{
          _showSnackBar('Favorito removido.');
          setState(() {
            fav = new Favorite();
          });
        }
      });
    }else{
      Favorite f = new Favorite();
      f.name = name;
      f.link = url;
      dbHelper.insert(f).then((value) {
        if(value!=null && value>0) {
          _showSnackBar('Salvo nos favoritos.');
          f.id = value;
          setState(() {
            fav = f;
          });
        }
      });
    }
  }

  _clearSnackBars(){
    _scaffoldKey.currentState.removeCurrentSnackBar();
  }

  _showSnackBar(String msg){
    _clearSnackBars();
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 3),
        action: SnackBarAction(label: 'Fechar', onPressed: () {
          _scaffoldKey.currentState.hideCurrentSnackBar();
        }),
    ));
  }

  _externalUrlAlert(String url){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Conteúdo externo!"),
          content: new Text('A página que você está tentando acessar não é uma página da Wikipedia. Deseja acessar via navegador?'),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Não"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Sim"),
              onPressed: () async {
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  _showSnackBar('Não foi possível abrir a página.');
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  NavigationDecision _interceptNavigation(NavigationRequest request) {  
    if (!request.url.contains("wikipedia.org")) {    
      _externalUrlAlert(request.url);
      return NavigationDecision.prevent;
    }
    
    return NavigationDecision.navigate;
  }

  Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return new WillPopScope(
            onWillPop: () async => false,
            child: SimpleDialog(
                key: _keyLoader,
                backgroundColor: Colors.black54,
                children: <Widget>[
                  Center(
                    child: Column(children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10,),
                      Text("Carregando...",style: TextStyle(color: Colors.blueAccent),)
                    ]),
                  )
                ]));
      }
    );
  }
}