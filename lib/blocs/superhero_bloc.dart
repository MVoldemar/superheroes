import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/api_exception.dart';
import 'package:superheroes/favorite_superheroes_storage.dart';
import 'package:superheroes/model/superhero.dart';

class SuperheroBloc {
  http.Client? client;
  final String id;

  final superheroSubject = BehaviorSubject<Superhero>();


  StreamSubscription? getFromFavoriteSubscription;
  StreamSubscription? requestSubscription;
  StreamSubscription? addToFavoriteSubscription;
  StreamSubscription? removeFromFavoriteSubscription;
  StreamSubscription? replaceFromFavoriteSubscription;

  SuperheroBloc({this.client, required this.id, }) {
    getFromFavorites();
  }

  void getFromFavorites() {
    getFromFavoriteSubscription?.cancel();
    getFromFavoriteSubscription = FavoriteSuperheroesStorage.getInstance()
        .getSuperhero(id).asStream().listen((superhero) {
          if(superhero != null) {
            superheroSubject.add(superhero);
            print("У нас есть модель в избранном");
          }
          requestSuperhero(superhero);
        },
        onError: (error, stackTrace) =>
            print("Error happened in getFromFavorites: $error, $stackTrace"));
  }

  void addToFavorite(){
    final superhero = superheroSubject.valueOrNull;
    if(superhero == null){
      print("ERROR: superhero is null");
      return;
    }

    addToFavoriteSubscription?.cancel();
    addToFavoriteSubscription = FavoriteSuperheroesStorage.getInstance()
        .addToFavorites(superhero).asStream().listen((event) {
          print("Added to favorites: $event");

    }
    ,
    onError: (error, stackTrace) =>
        print("Error happend in addToFavorites: $error, $stackTrace"));

  }

  void removeFromFavorites(){
    removeFromFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription = FavoriteSuperheroesStorage.getInstance()
        .removeFromFavorites(id).asStream().listen((event) {
      print("Removed from favorites: $event");

    }
        ,
        onError: (error, stackTrace) =>
            print("Error happened in removeFromFavorites: $error, $stackTrace"));

  }


  Stream<bool> observeIsFavorite() => FavoriteSuperheroesStorage.getInstance().observeIsFavorite(id);

  void requestSuperhero(Superhero? superheroStorage) {
    requestSubscription?.cancel();
    requestSubscription = request(superheroStorage).asStream( ).listen(
          (superhero) {
            if(superheroStorage != null && superheroStorage.toString()
                == superhero.toString()) {
              return;
            }
            if(superheroStorage == null) {
              print(superheroStorage == superhero);
              superheroSubject.add(superhero);
              print("У нас нет модели в избранном");
            }

      },
      onError: (error, stackTrace) {
        print("Error happened in requestSuperhero: $error, $stackTrace");
      },
    );
  }




  Future<Superhero> request(Superhero? superheroStorage) async {
    // await Future.delayed(Duration(seconds: 1));
    final token = dotenv.env["SUPERHERO_TOKEN"];

    final response = await (client ??=http.Client()).
    get(Uri.parse("https://superheroapi.com/api/$token/$id"));

    print(response.statusCode);
    print("$id");
    if(response.statusCode>=500){
      throw ApiException("Server error happened");
    }
    if(response.statusCode<500&&response.statusCode>=400)
    {
      throw ApiException("Client error happened");
    }
    final decoded = json.decode(response.body);
    if (decoded['response'] == 'success') {
      if(superheroStorage != null && superheroStorage.toString() != Superhero.fromJson(decoded).toString()) {
        FavoriteSuperheroesStorage.getInstance().replaceToFavorites(Superhero.fromJson(decoded));
            print("Id совпадают");
        }

      print(Superhero.fromJson(decoded).name);
      return Superhero.fromJson(decoded);
    }
      else if(decoded['response'] == 'error'){
        print("error");
        throw ApiException("Client error happened");
      }
      throw Exception("Unknow error happened");
    }



  Stream<Superhero> observeSuperhero() => superheroSubject.distinct();

  void dispose() {
    client?.close();
    requestSubscription?.cancel();
    getFromFavoriteSubscription?.cancel();
    addToFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription?.cancel();
    replaceFromFavoriteSubscription?.cancel();


    superheroSubject.close();
  }
}