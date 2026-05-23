
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'main.dart';

class TelaInscricaoEvento extends StatefulWidget {
  final String inscricaoId;
  final double valor;
  final String nomeEvento;
  const TelaInscricaoEvento({super.key, required this.inscricaoId, required this.valor, required this.nomeEvento});

  @override
  State<TelaInscricaoEvento> createState() => _TelaInscricaoEventoState();
}

class _TelaInscricaoEventoState extends State<TelaInscricaoEvento> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _nascimentoController = TextEditingController();
  final _celularController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _nascimentoController.dispose();
    _celularController.dispose();
    super.dispose();
  }


  Future<void> _enviarInscricao({required bool pagarAgora}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    final nome = _nomeController.text.trim();
    final nascimento = _nascimentoController.text.trim();
    final celular = _celularController.text.trim();
    final status = pagarAgora ? "Aguardando Pagamento" : "Aguardando Pagamento";
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    // Nome da aba/planilha: pode ser o nome do evento ou ID
    final sheetName = widget.nomeEvento.replaceAll(" ", "_");
    final url = Uri.parse('https://script.google.com/macros/s/AKfycbxrrIxJ3-LJjNkD_Bpshcs1J9U7gEBrzOcxaiHHJpd_Y1SGT1FyKMxZqDt56RRZpK83/exec');
    final data = {
      'spreadsheetId': '1zxnRHps2KI2p2eDY65GfSomJTs_R1KRI9OTlqTkwCbY',
      'sheetName': sheetName,
      'data': {
        'inscricaoId': widget.inscricaoId,
        'nome': nome,
        'nascimento': nascimento,
        'celular': celular,
        'status': status,
        'timestamp': timestamp,
      }
    };
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      final resp = response.body;
      if (response.statusCode == 200 && resp.contains('success')) {
        if (pagarAgora) {
          // Vai para tela de pagamento
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => TelaPagamentoPix(valor: widget.valor, inscricaoId: widget.inscricaoId),
            ),
          );
        } else {
          // Mostra mensagem de sucesso
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sua inscrição foi enviada. Efetue o pagamento na Igreja!'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        }
      } else {
        throw Exception('Erro ao enviar inscrição: $resp');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar inscrição: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inscrição - ${widget.nomeEvento}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nascimentoController,
                decoration: const InputDecoration(labelText: 'Data de nascimento (DD/MM/AAAA)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe a data de nascimento' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _celularController,
                decoration: const InputDecoration(labelText: 'Celular'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Informe o celular' : null,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              Text('Valor da inscrição: R\$ ${widget.valor.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.pix),
                      label: _enviando ? const CircularProgressIndicator() : const Text('Pagar Agora'),
                      onPressed: _enviando ? null : () => _enviarInscricao(pagarAgora: true),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.church),
                      label: _enviando ? const CircularProgressIndicator() : const Text('Pagar na Igreja'),
                      onPressed: _enviando ? null : () => _enviarInscricao(pagarAgora: false),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
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

