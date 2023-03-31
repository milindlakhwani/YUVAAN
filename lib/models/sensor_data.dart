class SensorData {
  double temperature;
  double humidity;
  double pressure;
  double co;
  double co2;
  double methane;
  double wind_speed;
  double alcohol;
  double lpg;
  double propane;
  double hydrogen;

  SensorData({
    this.temperature,
    this.humidity,
    this.co,
    this.co2,
    this.methane,
    this.pressure,
    this.wind_speed,
    this.alcohol,
    this.hydrogen,
    this.lpg,
    this.propane,
  });

  SensorData.fromJson(Map<String, dynamic> json) {
    temperature = json['temperature'];
    humidity = json['humidity'];
    pressure = json['pressure'];
    co = json['co'];
    co2 = json['co2'];
    methane = json['methane'];
    wind_speed = json['wind_speed'];
  }

  SensorData.fromList(List<double> values) {
    temperature = values[0];
    humidity = values[1];
    pressure = values[2];
    co = values[3];
    co2 = values[4];
    methane = values[5];
    wind_speed = values[6];
    alcohol = values[7];
    hydrogen = values[8];
    lpg = values[9];
    propane = values[10];
  }

  // factory SensorData.fromMap(Map<String, dynamic> doc) {
  //   return SensorData(
  //     temperature: doc['temperature'],
  //     humidity: doc['humidity'],
  //     pressure: doc['pressure'],
  //     co: doc['co'],
  //     co2: doc['co2'],
  //     methane: doc['methane'],
  //     wind_speed: doc['wind_speed'],
  //   );
  // }
}
