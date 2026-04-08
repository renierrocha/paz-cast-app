import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class StripeService {
  static const String backendUrl = 'https://seu-backend.com/api'; // Substitua pela URL real do seu backend

  // Cria um PaymentIntent no backend
  static Future<Map<String, dynamic>> createPaymentIntent({
    required int amount,
    required String currency,
    String? description,
  }) async {
    final url = Uri.parse('$backendUrl/create-payment-intent');
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
    };
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        if (description != null) 'description': description,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao criar PaymentIntent: ${response.body}');
    }
  }
}
