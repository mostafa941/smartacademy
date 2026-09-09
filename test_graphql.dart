import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://nuyfvwarjpndcbhxyfmo.supabase.co/graphql/v1');
  
  final query = '''
    query {
      __type(name: "students") {
        fields {
          name
        }
      }
    }
  ''';

  final response = await http.post(
    url,
    headers: {
      'apikey': 'sb_publishable_vOeCuPbpSEdP8fKuzi74uA_ulQ8P3d3',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'query': query}),
  );

  print('Response: ${response.body}');
}
