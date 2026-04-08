import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'stripe_service.dart';

class TelaPagamentoStripe extends StatefulWidget {
  final double valor;
  final String inscricaoId;
  const TelaPagamentoStripe({super.key, required this.valor, required this.inscricaoId});

  @override
  State<TelaPagamentoStripe> createState() => _TelaPagamentoStripeState();
}

class _TelaPagamentoStripeState extends State<TelaPagamentoStripe> {
  bool _loading = false;
  String? _error;

  Future<void> _payWithStripe() async {
    setState(() { _loading = true; _error = null; });
    try {
      // 1. Cria PaymentIntent no backend
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: (widget.valor * 100).toInt(), // Stripe usa centavos
        currency: 'brl',
        description: 'Pagamento inscrição ${widget.inscricaoId}',
      );
      // 2. Inicializa pagamento
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'Paz Castanhal',
          style: ThemeMode.dark,
        ),
      );
      // 3. Exibe PaymentSheet
      await Stripe.instance.presentPaymentSheet();
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Pagamento realizado!'),
            content: const Text('Seu pagamento foi processado com sucesso.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento Stripe'), backgroundColor: Colors.transparent),
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Valor: R\$ ${widget.valor.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, color: Colors.amber, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Pagar com cartão'),
                    onPressed: _payWithStripe,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
      ),
    );
  }
}
