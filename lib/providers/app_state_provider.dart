import 'package:anime_verse/models/anime.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/dummy_data.dart';

class AppStateProvider extends ChangeNotifier {
  //data
  List<Anime> _favorites = [];
  //getter
  List<Anime> get favorites => _favorites;

  //State Baru: Genre yang dipilih (default: "All)
  String _selectedGenre = "All";

  //Getter Baru
  String get selectedGenre => _selectedGenre;

  //Method baru: mengubah genre yang dipilih
  void setSelectedGenre(String genre){
    _selectedGenre = genre;
    notifyListeners();
  }

  //State baru: query pencarian (dipisah per layar)
  String _homeSearchQuery = "";
  String _favoriteSearchQuery = "";

  String get homeSearchQuery => _homeSearchQuery;
  String get favoriteSearchQuery => _favoriteSearchQuery;

  //update query pencarian homescreen
  void setHomeSearchQuery(String query){
    _homeSearchQuery = query;
    notifyListeners();
  }

  //update query pencarian favoriteScreen
  void setFavoriteSearchQuery(String query){
    _favoriteSearchQuery = query;
    notifyListeners();
  }

  static const String _storageKey = 'favorite_anime_list'; //kunci penyimpanan

  //Constructor: otomatis memuat favorit saat provider dibuat
  AppStateProvider(){
    _loadFavorites();
  }

  //Simpan daftar favorit ke SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      //1. List<Anime> -> List<Map<String, dynamics>>
      final List<Map<String, dynamic>> favoritesJson = _favorites.map((anime) => anime.toJson()).toList();

      //2. List<Map> -> String JSON, lalu disimpan
      await prefs.setString(_storageKey, jsonEncode(favoritesJson));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      //1. Baca String JSON
      final String? favoritesJson = prefs.getString(_storageKey);

      if(favoritesJson != null){
        //2. String JSON -> List<dynamic>
        final List<dynamic> decoded = jsonDecode(favoritesJson);

        //3. List<dynamic> -> List<Anime>
        _favorites = decoded. map((item) => Anime.fromJson(item as Map<String, dynamic>)).toList();

        notifyListeners();
      }

    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  //helper
  bool isFavorite(String id) {
    return _favorites.any((anime) => anime.id == id);
  }

  void toggleFavorite(Anime anime) {
    if (isFavorite(anime.id)) {
      removeFavorite(anime.id);
    } else {
      addFavorite(anime);
    }
  }

  void addFavorite(Anime anime) {
    if (!isFavorite(anime.id)) {
      _favorites.add(anime);
      _saveFavorites();
      notifyListeners();
    }
  }

  void removeFavorite(String id) {
    _favorites.removeWhere((anime) => anime.id == id);
    _saveFavorites();
    notifyListeners();
  }

  //Ambil daftar anime home yang sudah difilter
  List<Anime> getFilteredAnimeForHome(){
    List<Anime> result = DummyData.animeList;

    //Terapkan filter genre
    if(_selectedGenre != "All"){
      result = result.where((anime){
        //pecah "Action, Adventure" jadi ["Action", "Adventure"]
        final genres = anime.genre.split(',').map((g)=>g.trim()).toList();
        return genres.contains(_selectedGenre);
      }).toList();
    }

    //terapkan filter search (setelah filter genre)
    if(_homeSearchQuery.isNotEmpty){
      result = result.where((anime){
        //bandingkan dalam lowercase agar case-insensitive
        return anime.title.toLowerCase().contains(_homeSearchQuery.toLowerCase());
      }).toList();
    }
    return result;

  }

  //ambil favorit yang sudah difilter (berdasarkan pencarian favorit)
  List<Anime> getFilteredFavorites(){
    List<Anime> result = _favorites;

    //terapkan filter search favorit
    if(_favoriteSearchQuery.isNotEmpty){
      result = result.where((anime){
        return anime.title.toLowerCase().contains(_favoriteSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }
}
