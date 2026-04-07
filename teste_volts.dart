import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testando check-in/check-out com Google Sheets...');

  // Dados de teste para check-in
  final checkinData = {
    'user_id': 'teste_user_123',
    'nome': 'João Silva',
    'ministerio': 'Louvor',
    'itens': {
      'cracha': true,
      'cordao': true,
      'equipamento': false,
    },
    'situacao': 'Em uso',
    'tipo': 'checkin',
  };

  const String scriptUrl = 'https://script.google.com/macros/s/AKfycbzZ4mQU_8NlcSX61LAQQcPMgfLGUUz160yBthg14-8D3IavWKHoNVmYkSQCiqJXqDLH/exec';

  try {
    print('📤 Enviando dados de check-in para: $scriptUrl');

    final response = await http.post(
      Uri.parse(scriptUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'spreadsheetId': '1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4',
        'sheetName': 'Volts',
        'data': checkinData,
      }),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        print('✅ SUCESSO: Check-in enviado para a planilha!');
        print('📝 Mensagem: ${responseData['message']}');
      } else {
        print('❌ ERRO na planilha: ${responseData['error']}');
      }
    } else {
      print('❌ ERRO HTTP: ${response.statusCode}');
    }

    // Teste check-out
    print('\n🔄 Testando check-out...');
    final checkoutData = {
      'user_id': 'teste_user_123',
      'nome': 'João Silva',
      'ministerio': 'Louvor',
      'itens': {
        'cracha': true,
        'cordao': true,
        'equipamento': false,
      },
      'situacao': 'Checkout OK',
      'tipo': 'checkout',
    };

    final checkoutResponse = await http.post(
      Uri.parse(scriptUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'spreadsheetId': '1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4',
        'sheetName': 'Volts',
        'data': checkoutData,
      }),
    );

    print('📊 Status Code Check-out: ${checkoutResponse.statusCode}');
    print('📄 Response Body Check-out: ${checkoutResponse.body}');

    if (checkoutResponse.statusCode == 200) {
      final responseData = jsonDecode(checkoutResponse.body);
      if (responseData['success'] == true) {
        print('✅ SUCESSO: Check-out enviado para a planilha!');
      } else {
        print('❌ ERRO no check-out: ${responseData['error']}');
      }
    } else {
      print('❌ ERRO HTTP no check-out: ${checkoutResponse.statusCode}');
    }

  } catch (e) {
    print('💥 ERRO: $e');
  }

  print('🏁 Teste concluído.');
}