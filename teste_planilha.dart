import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testando conexão com Google Sheets...');

  // Dados de teste
  final testData = {
    'data': '01/01/2024',
    'lider': 'Teste Líder',
    'membros_presentes': 5,
    'convidados': 2,
    'criancas': 1,
    'ofertas': 100.50,
    'supervisao': true,
    'observacoes': 'Teste de conexão com planilha - Script Dart',
    'user_name': 'Script Teste',
  };

  const String scriptUrl = 'https://script.google.com/macros/s/AKfycbxcoNcZhKcTaYjOcGTHJdZbiEZlS8HQMNG5jleDkbvaFWGo_QXP_bMXf0fKZgHLkPbt/exec';

  try {
    print('📤 Enviando dados para: $scriptUrl');

    final response = await http.post(
      Uri.parse(scriptUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'spreadsheetId': '1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4',
        'sheetName': 'Células',
        'data': testData,
      }),
    );

    print('📊 Status Code: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true) {
        print('✅ SUCESSO: Dados enviados para a planilha!');
        print('📝 Mensagem: ${responseData['message']}');
      } else {
        print('❌ ERRO na planilha: ${responseData['error']}');
      }
    } else {
      print('❌ ERRO HTTP: ${response.statusCode}');
    }
  } catch (e) {
    print('💥 ERRO: $e');
  }

  print('🏁 Teste concluído.');
}