import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:zymr_test/weather_provider.dart';
import 'package:geolocator/geolocator.dart';

class WeatherUI extends ConsumerStatefulWidget {
  const WeatherUI({super.key});

  @override
  WeatherUIState createState() => WeatherUIState();
}

class WeatherUIState extends ConsumerState<WeatherUI> {
  @override
  void initState() {
    super.initState();
    initialCall();
  }

  var weatherData;
  var temperature;
  var windSpeed;
  Map<String, dynamic>? fetchedData = {};
  Map<String, dynamic>? fetchedFutureData = {};
  Future<void> initialCall() async {
    await ref.read(weatherProvider).getCurrentPosition();
    ref.read(weatherProvider).getWeather(ref.read(weatherProvider).cityName);

    DateTime currentDate = DateTime.now();
    String current = DateFormat('yyyy-MM-dd').format(currentDate);
    DateTime sevenDaysAgo = currentDate.subtract(Duration(days: 7));
    String formattedDate = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

    fetchedData = await ref
        .read(weatherProvider)
        .fetchHistoryWeather(formattedDate, current);

    fetchedFutureData = await ref
        .read(weatherProvider)
        .fetchFutureWeather(formattedDate, current);
  }

  List<DateTime?> selectedDates = [];

  @override
  Widget build(BuildContext context) {
    var weather = ref.watch(weatherProvider).weather;
    return Scaffold(
      appBar: AppBar(
        title: Text('Location and Weather App'),
        elevation: 4,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: ref.watch(weatherProvider).isLoading
                ? const LinearProgressIndicator()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 40.0, right: 20.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(
                                Icons.wb_cloudy_outlined,
                                color: Colors.white,
                                size: 50,
                              ),
                              const SizedBox(
                                height: 4,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      color: Colors.white, size: 18),
                                  Text('${weather?.areaName}',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ],
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Text(
                                '${weather?.temperature.toString()}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        child: CalendarDatePicker2(
                          config: CalendarDatePicker2Config(
                            calendarType: CalendarDatePicker2Type.single,
                            selectedDayHighlightColor: Colors.white60,
                            selectedRangeHighlightColor: Colors.white60,
                            currentDate: DateTime.now(),
                            lastDate: DateTime.now(),
                            weekdayLabelTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            selectedDayTextStyle: const TextStyle(
                              decorationColor: Colors.deepPurpleAccent,
                              color: Colors.deepPurpleAccent,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.transparent,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                            controlsTextStyle: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            firstDayOfWeek: 0,
                          ),
                          value: selectedDates,
                          onValueChanged: (newDate) async {
                            selectedDates = newDate;
                            DateTime dateTime =
                                DateTime.parse(selectedDates[0].toString());
                            DateTime dateOnly = DateTime(
                                dateTime.year, dateTime.month, dateTime.day);
                            String formattedDate =
                                DateFormat('yyyy-MM-dd').format(dateOnly);

                            await ref.read(weatherProvider).fetchHistoryWeather(
                                formattedDate, formattedDate);
                          },
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        height: MediaQuery.of(context).size.height * 0.13,
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              'Current City : ${weather?.areaName.toString()}',
                              style: const TextStyle(
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            ref.watch(weatherProvider).temperature == null
                                ? Text(
                                    'Current Temparature : ${weather?.temperature.toString()} C',
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  )
                                : Text(
                                    'Selected Day Temparature : ${ref.watch(weatherProvider).temperature.toString()} C',
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                            const SizedBox(
                              height: 8,
                            ),
                            ref.watch(weatherProvider).windSpeed == null
                                ? Text(
                                    'Wind Speed : ${weather?.windSpeed.toString()} km/h',
                                    style: const TextStyle(color: Colors.black))
                                : Text(
                                    'Wind Speed : ${ref.watch(weatherProvider).windSpeed.toString()} km/h',
                                    style: const TextStyle(color: Colors.black)),
                            const SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                      fetchedData?.length != 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    height: 150,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 7,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        String date =
                                            fetchedData?['weatherData']['time']
                                                [index];
                                        double temperature =
                                            fetchedData?['weatherData']
                                                        ['temperature_2m_max']
                                                    [index] ??
                                                0.0;
                                        double windSpeed =
                                            fetchedData?['weatherData']
                                                        ['windspeed_10m_max']
                                                    [index] ??
                                                0.0;

                                        DateTime currentDate =
                                            DateFormat('yyyy-MM-dd')
                                                .parse(date);
                                        String formattedDate =
                                            DateFormat('MMM d')
                                                .format(currentDate);

                                        return Container(
                                          height: 150,
                                          width: 130,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10.0),
                                            border: Border.all(
                                              color: Colors.white60,
                                              width: 2.0,
                                            ),
                                          ),
                                          margin: EdgeInsets.all(5),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                DateFormat('E')
                                                    .format(currentDate),
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                'Temp: $temperature°C',
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                'Wind: $windSpeed km/h',
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                      fetchedFutureData?.length != 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    height: 150,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 7,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        String date =
                                            fetchedFutureData?['weatherData']
                                                ['time'][index];
                                        double temperature =
                                            fetchedFutureData?['weatherData']
                                                        ['temperature_2m_max']
                                                    [index] ??
                                                0.0;
                                        double windSpeed =
                                            fetchedFutureData?['weatherData']
                                                        ['windspeed_10m_max']
                                                    [index] ??
                                                0.0;

                                        DateTime currentDate =
                                            DateFormat('yyyy-MM-dd')
                                                .parse(date);
                                        String formattedDate =
                                            DateFormat('MMM d')
                                                .format(currentDate);

                                        return Container(
                                          height: 150,
                                          width: 130,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10.0),
                                            border: Border.all(
                                              color: Colors.white60,
                                              width: 2.0,
                                            ),
                                          ),
                                          margin: EdgeInsets.all(5),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                DateFormat('E')
                                                    .format(currentDate),
                                                style:const TextStyle(
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                'Temp: $temperature°C',
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                              Text(
                                                'Wind: $windSpeed km/h',
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
