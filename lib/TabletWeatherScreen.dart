import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather_icons/weather_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for day names

class TabletWeatherScreen extends StatefulWidget {
  const TabletWeatherScreen({super.key});

  @override
  _TabletWeatherScreenState createState() => _TabletWeatherScreenState();
}

class _TabletWeatherScreenState extends State<TabletWeatherScreen> {
  final String apiKey = 'YOUR_API'; // Replace with your API key
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

  Future<void> loadLastCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastCity = prefs.getString('lastCity');
    if (lastCity != null) {
      city = lastCity;
    }
    fetchWeather(city);
  }

  Future<void> saveLastCity(String location) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastCity', location);
  }

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
          temperature = todayWeather['main']['temp']?.toDouble().round().toDouble();
          humidity = todayWeather['main']['humidity'];
          windSpeed = todayWeather['wind']['speed'].toInt();
          weatherCondition = todayWeather['weather'][0]['main'];
          weatherIcon = getWeatherIcon(weatherCondition ?? 'Clear');

          // Get 3-day forecast (Every 8th item = next day's weather)
          forecast = [
            for (int i = 1; i <= 3; i++)
              {
                'temp': data['list'][i * 8]['main']['temp']?.toDouble().round().toDouble() ?? 0.0,
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

  /// 🔹 **Added Back Search Dialog**
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF108DDB),
              Color(0xFF273C7F),
              Color(0xFF14151E),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => fetchWeather(city), // ✅ Pull-to-refresh still works
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // ✅ Ensures scrolling
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      // 🔹 **Top Row with City Name & Search Button**
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              city,
                              style: const TextStyle(fontSize: 26, color: Colors.white),
                            ),
                            IconButton(
                              icon: const Icon(Icons.search, color: Colors.white, size: 30),
                              onPressed: showSearchDialog,
                            ),
                          ],
                        ),
                      ),

                      // 🔹 **Tablet Layout: Row (Today's Weather | 3-Day Forecast)**
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // **LEFT: Today's Weather**
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: MediaQuery.of(context).size.height - 100,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center, // ✅ Centers content inside
                                crossAxisAlignment: CrossAxisAlignment.center, // ✅ Centers horizontally
                                children: [
                                  Icon(weatherIcon, size: 160, color: Colors.white),
                                  const SizedBox(height: 20),
                                  Text('${temperature?.toInt() ?? 0}°C',
                                      style: const TextStyle(fontSize: 50, color: Colors.white)),
                                  Text(weatherCondition ?? '',
                                      style: const TextStyle(fontSize: 20, color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),




                          // **RIGHT: 3-Day Forecast in 3 Columns**
                          Expanded(
                            flex: 2,
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                              ),
                              child: Column(
                                children: [
                                  const Text('Next 3 Days', style: TextStyle(fontSize: 18, color: Colors.white)),
                                  const SizedBox(height: 20),

                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3, // **3 columns**
                                      childAspectRatio: 0.8,
                                    ),
                                    itemCount: forecast.length,
                                    itemBuilder: (context, index) {
                                      Map<String, dynamic> day = forecast[index];
                                      String dayName = DateFormat('E').format(DateTime.now().add(Duration(days: index + 1)));

                                      return Column(
                                        children: [
                                          Text(dayName, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                          Icon(day['icon'], color: Colors.white, size: 40),
                                          Text('${day['temp'].toInt()}°C', style: const TextStyle(color: Colors.white)),
                                          Text(day['condition'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}
