import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  final String apiKey =
      'pat9PYLZ3jMlj9AN2.d3ecc72334962e299bd9757bb7badbcf734de2fea1528186e112abfca9c4c4f1';
  final String baseId = 'appXVEAL5jETcjmaE';
  final String tableName = 'Bookings';

  Future<void> createBooking({
    required String artistId,
    required String date,
    required String time,
    required String location,
  }) async {
    final url = Uri.parse('https://api.airtable.com/v0/$baseId/$tableName');

    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final body = jsonEncode({
      'fields': {
        'artist_ID': [artistId],
        'date': date,
        'time': time,
        'location': location,
      }
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create booking: ${response.body}');
    }
  }
}
