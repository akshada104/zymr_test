
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:http/http.dart' as http;

var weatherProvider =
ChangeNotifierProvider((ref) => WeatherProvider(ref));

class WeatherProvider extends ChangeNotifier {
  final Ref ref;
  WeatherProvider(this.ref);

  final WeatherFactory weatherFactory =
  WeatherFactory('f86eb6d3ddeb985f608c4ab83a9b3c5d');

  Weather? weather;
  DateTime? now ;
  var cityName;
  List<Weather>? nextWeekForecast;
  List<Weather>? previousWeekForecast;

  void getWeather(String cityName){
    weatherFactory.currentWeatherByCityName(cityName).then((value) {
      weather = value;
      now = weather?.date;
      notifyListeners();
    });
  }

  Future<void> fetchWeatherData() async {

    final nextWeekForecastResponse = await weatherFactory.fiveDayForecastByCityName(cityName);
      nextWeekForecast = nextWeekForecastResponse;

      notifyListeners();
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }


  String? currentAddress;
  Position? currentPosition;
  bool isLoading  = false;

  Future<void> getCurrentPosition() async {
    isLoading = true;
    notifyListeners();
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      currentPosition = position;
     await getAddressFromLatLng(position);
      isLoading = false;
      notifyListeners();
    }).catchError((e) {
      debugPrint(e);
    });
  }


  Future<void> getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        currentPosition!.latitude, currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      cityName = place.locality;
        currentAddress =
        '${place.name}, ${place.subLocality} , ${place.subAdministrativeArea}, ${place.postalCode}';
    }).catchError((e) {
      debugPrint(e);
    });
  }

   Map<String, dynamic>? weatherData;
    var temperature;
    var humidity;
    var windSpeed;

  Future<Map<String, dynamic>?> fetchHistoryWeather(String startDate, String endDate) async {

    final url = Uri.parse(
        'https://archive-api.open-meteo.com/v1/archive?latitude=${currentPosition?.latitude}&longitude=${currentPosition?.longitude}&start_date=$startDate&end_date=$endDate&daily=temperature_2m_max,windspeed_10m_max'
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
          weatherData = decodedData['daily'];
          temperature = decodedData['daily']['temperature_2m_max'][0];
          windSpeed = decodedData['daily']['windspeed_10m_max'][0];
          notifyListeners();
        return {
          'weatherData': weatherData,
          'temperature': temperature,
          'windSpeed': windSpeed,
        };
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchFutureWeather(String startDate, String endDate) async {

    final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${currentPosition?.latitude}&longitude=${currentPosition?.longitude}&daily=temperature_2m_max,windspeed_10m_max'
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        weatherData = decodedData['daily'];
        temperature = decodedData['daily']['temperature_2m_max'][0];
        windSpeed = decodedData['daily']['windspeed_10m_max'][0];
        notifyListeners();
        return {
          'weatherData': weatherData,
          'temperature': temperature,
          'windSpeed': windSpeed,
        };
      }

    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }
}
