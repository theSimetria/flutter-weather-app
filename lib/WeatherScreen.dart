import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather_icons/weather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for day names


class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final String apiKey = 'a9f9362d5ed58fadb2c5044bf75b899b'; // Replace with your API key
  String city = 'Zagreb'; // Default city
  double? temperature;
  String? weatherCondition;
  IconData? weatherIcon;
  int? humidity;
  int? windSpeed;
  bool isLoading = false;
  List<Map<String, dynamic>> forecast = []; // Stores the 3-day forecast

  @override
  void initState() {
    super.initState();
    loadLastCity();
  }

  /// Loads the last searched city from SharedPreferences
  Future<void> loadLastCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastCity = prefs.getString('lastCity');
    if (lastCity != null) {
      city = lastCity;
    }
    fetchWeather(city);
  }

  /// Saves the last searched city to SharedPreferences
  Future<void> saveLastCity(String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastCity', location);
  }

  /// Fetches weather data from OpenWeather API (Current + 3-Day Forecast)
  Future<void> fetchWeather(String location) async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$location&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final todayWeather = data['list'][0];

        setState(() {
          city = data['city']['name'];
          if (city.toLowerCase().contains("donji grad")) {
            city = "Zagreb"; // Force it to be Zagreb
          }
          temperature = todayWeather['main']['temp'] != null
              ? todayWeather['main']['temp'].toDouble().round().toDouble()
              : null;
          humidity = todayWeather['main']['humidity'];
          windSpeed = todayWeather['wind']['speed'].toInt();
          weatherCondition = todayWeather['weather'][0]['main'];
          weatherIcon = getWeatherIcon(weatherCondition ?? 'Clear');

          // Get 3-day forecast (Every 8th item = next day's weather)
          forecast = [
            for (int i = 1; i <= 3; i++)
              {
                'temp': data['list'][i * 8]['main']['temp'] != null
                    ? data['list'][i * 8]['main']['temp'].toDouble().round().toDouble()
                    : 0.0,
                'condition': data['list'][i * 8]['weather'][0]['main'],
                'icon': getWeatherIcon(data['list'][i * 8]['weather'][0]['main']),
              }
          ];
        });

        saveLastCity(city);
      } else {
        showError();
      }
    } catch (e) {
      showError();
    }

    setState(() {
      isLoading = false;
    });
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return WeatherIcons.day_sunny;
      case 'clouds':
        return WeatherIcons.cloud;
      case 'rain':
        return WeatherIcons.rain;
      case 'drizzle':
        return WeatherIcons.showers;
      case 'thunderstorm':
        return WeatherIcons.thunderstorm;
      case 'snow':
        return WeatherIcons.snow;
      case 'mist':
      case 'fog':
        return WeatherIcons.fog;
      default:
        return WeatherIcons.na;
    }
  }

  void showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to fetch weather. Try again!')),
    );
  }

  /// Opens a popup dialog for searching a city
  void showSearchDialog() {
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Search City"),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(hintText: "Enter city name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (searchController.text.isNotEmpty) {
                  fetchWeather(searchController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Search"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF108DDB), // Blue
              Color(0xFF273C7F), // Light Blue
              Color(0xFF14151E), // Orange
              Color(0xFF121112), // Red
            ],
            stops: [0.0, 0.3, 0.6, 1.0], // Control blending points
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => fetchWeather(city),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // City name + Search button
              Padding(
                padding: const EdgeInsets.only(top: 40), // Adjust the top padding as needed
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      city,
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.normal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white, size: 30),
                      onPressed: showSearchDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (temperature != null)
                Column(
                  children: [
                    Icon(weatherIcon, size: 100, color: Colors.white),
                    const SizedBox(height: 6),
                    Text('${temperature?.toInt() ?? 0}°C', style: const TextStyle(fontSize: 50, color: Colors.white)),
                    Text(weatherCondition ?? '', style: const TextStyle(fontSize: 20, color: Colors.white70)),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Icon(WeatherIcons.strong_wind, color: Colors.white),
                            Text('$windSpeed km/h', style: const TextStyle(color: Colors.white)),
                            const Text('Wind', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(width: 30),
                        Column(
                          children: [
                            const Icon(WeatherIcons.humidity, color: Colors.white),
                            Text('$humidity%', style: const TextStyle(color: Colors.white)),
                            const Text('Humidity', style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(27, 28, 39, 0.1),
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(38, 55,117, 0.1),
                            spreadRadius: 6,
                            blurRadius: 1,
                            offset: Offset(0, 0), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Next 3 Days', style: TextStyle(fontSize: 16, color: Colors.white)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: forecast.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> day = entry.value;

                              // Get the weekday name dynamically
                              DateTime dayDate = DateTime.now().add(Duration(days: index + 1));
                              String dayName = DateFormat('E').format(dayDate); // "Mon", "Tue", etc.

                              return Column(
                                children: [
                                  Text(dayName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)), // Day name
                                  const SizedBox(height: 5),
                                  Icon(day['icon'], color: Colors.white, size: 40),
                                  Text('${day['temp'].toInt()}°C', style: const TextStyle(color: Colors.white)),
                                  Text(day['condition'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

}
