
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;


// --- WIDGET QR CODE DO MEMBRO ---
class QRMembroWidget extends StatelessWidget {
  const QRMembroWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Faça login para ver seu QR Code', style: TextStyle(color: Colors.white70)));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Seu QR Code de membro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: QrImageView(
            data: user.uid,
            size: 200.0,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SelectableText(user.uid, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Text(user.displayName ?? user.email ?? '', style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}


// --- TELA DE PAGAMENTO PIX ---
class TelaPagamentoPix extends StatelessWidget {
  final double valor;
  final String inscricaoId;
  const TelaPagamentoPix({super.key, required this.valor, required this.inscricaoId});

  Future<Map<String, dynamic>> _gerarPix() async {
    // Exemplo de chamada ao backend que retorna {qrCodeImageUrl, copiaECola}
    // Substitua pela URL real do seu backend
    final url = Uri.parse('https://paz-backend.onrender.com');
    final response = await http.post(url, body: jsonEncode({
      'valor': valor,
      'inscricaoId': inscricaoId,
    }), headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro ao gerar cobrança PIX');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento PIX'), backgroundColor: Colors.transparent),
      backgroundColor: const Color(0xFF020617),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gerarPix(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final data = snapshot.data ?? {};
          final qrCodeImageUrl = data['qrCodeImageUrl'] as String?;
          final copiaECola = data['copiaECola'] as String?;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: _GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pix, color: Color(0xFF00BFA5), size: 48),
                    const SizedBox(height: 16),
                    Text('Valor: R\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, color: Colors.amber, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    if (qrCodeImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(qrCodeImageUrl, height: 220, width: 220, fit: BoxFit.contain),
                      ),
                    if (copiaECola != null) ...[
                      const SizedBox(height: 24),
                      SelectableText(copiaECola, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: copiaECola));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Código PIX copiado!')));
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar código PIX'),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text('Após o pagamento, a confirmação pode levar alguns minutos.', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyA4dRSAmRpUZLudG29s4CqvRvFmVcTOmVE",
          authDomain: "pazcastanhal-809cd.firebaseapp.com",
          projectId: "pazcastanhal-809cd",
          storageBucket: "pazcastanhal-809cd.firebasestorage.app",
          messagingSenderId: "647154132280",
          appId: "1:647154132280:web:7be303c4b584531d618dcd",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    if (!kIsWeb) {
      FirebaseMessaging.instance.subscribeToTopic("todos");
      await _setupFirebaseMessaging();
    }
  } catch (e) {
    debugPrint("Erro Firebase: $e");
  }
  runApp(const AppPazPremium());
}

/// Handler para mensagens recebidas em background/terminated
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("[Push] Mensagem recebida em background: ${message.messageId}");
}

Future<void> _setupFirebaseMessaging() async {
  // Permissão para notificações (iOS/Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // Mensagens recebidas com app em foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('[Push] Mensagem recebida em foreground: \\nTítulo: \\${message.notification?.title}\\nBody: \\${message.notification?.body}');
    // Aqui você pode exibir um dialog/snackbar/local_notification
  });

  // Mensagens recebidas quando o app é aberto por uma notificação
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('[Push] Usuário abriu app pela notificação: ${message.messageId}');
    // Navegação ou ação customizada
  });

  // Handler para background/terminated
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Mensagem inicial (caso app foi aberto por push)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint('[Push] App aberto por notificação (getInitialMessage): ${initialMessage.messageId}');
  }
}
Future<void> signInWithGoogle(BuildContext context) async {
  try {
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      return;
    }
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return;
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login com Google realizado')));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no login Google: $e')));
  }
}
class AppPazPremium extends StatelessWidget {
  const AppPazPremium({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1), brightness: Brightness.dark),
      ),
      home: const TelaSplash(),
    );
  }
}

// --- 1. TELA DE SPLASH ---
class TelaSplash extends StatefulWidget {
  const TelaSplash({super.key});
  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScaffold()));
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Center(child: Image.asset('assets/icon.png', width: 220, filterQuality: FilterQuality.high)),
    );
  }
}

// --- 2. SCAFFOLD PRINCIPAL ---
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _isReadingMode = false;

  void _mudarTela(int i) { setState(() { _currentIndex = i; _isReadingMode = false; }); }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      TelaInicio(onNavigate: _mudarTela),
      const TelaAvisosPro(),
      const TelaAgendaPro(),
      TelaBibliaPro(onReading: (b) => setState(() => _isReadingMode = b), onNavigate: _mudarTela),
      const AbaMembroFull(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      extendBody: true,
      body: Stack(children: [
        Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F172A), Color(0xFF020617)])))),
        AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: KeyedSubtree(key: ValueKey(_currentIndex), child: pages[_currentIndex])),
      ]),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: _isReadingMode ? 0 : 110,
        child: _isReadingMode ? const SizedBox.shrink() : _buildModernNav(),
      ),
    );
  }

  Widget _buildModernNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 65,
      decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withAlpha(30))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _navBtn(0, Icons.home_filled), _navBtn(1, Icons.notifications), _navBtn(2, Icons.event), _navBtn(3, Icons.menu_book), _navBtn(4, Icons.person),
      ]),
    );
  }

  Widget _navBtn(int index, IconData icon) {
    bool isSel = _currentIndex == index;
    return GestureDetector(onTap: () => _mudarTela(index), child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isSel ? const Color(0xFF6366F1) : Colors.transparent, shape: BoxShape.circle), child: Icon(icon, color: isSel ? Colors.white : Colors.white.withAlpha(80), size: 24)));
  }
}

// --- 3. TELA INICIAL (HOME) ---
class TelaInicio extends StatelessWidget {
  final Function(int) onNavigate;
  const TelaInicio({super.key, required this.onNavigate});

  String _saudacao() {
    var h = DateTime.now().hour;
    if (h < 12) return "Bom dia";
    if (h < 18) return "Boa tarde";
    return "Boa noite";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('config').doc('home').snapshots(),
      builder: (context, snap) {
        Map d = snap.data?.data() as Map? ?? {};
        String img = d['imgBanner'] ?? "";
        return SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(children: [
            const SizedBox(height: 50),
            Center(child: Image.asset('assets/icon.png', height: 75)),
            const SizedBox(height: 25),
            if (user != null)
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get(),
                builder: (c, us) {
                  if (us.connectionState == ConnectionState.waiting) {
                    return Text("${_saudacao()}, carregando...", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold));
                  }
                  if (us.hasError) {
                    return Text("${_saudacao()}, ${user.displayName ?? user.email?.split('@').first ?? 'Membro'}!", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold));
                  }
                  if (!us.hasData || !us.data!.exists) {
                    return Text("${_saudacao()}, ${user.displayName ?? user.email?.split('@').first ?? 'Membro'}!", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold));
                  }
                  Map<String, dynamic>? u = us.data!.data() as Map<String, dynamic>?;
                  String? nome = u?['nome']?.toString().trim();
                  if (nome != null && nome.isNotEmpty) {
                    return Text("${_saudacao()}, $nome!", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold));
                  }
                  // Fallback para displayName do Google ou email
                  return Text("${_saudacao()}, ${user.displayName ?? user.email?.split('@').first ?? 'Membro'}!", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold));
                },
              )
            else 
              Text("${_saudacao()}! Paz seja convosco.", style: const TextStyle(fontSize: 18, color: Colors.white70)),
            const SizedBox(height: 20),
            if (img.isEmpty) _buildVerse(d) else ClipRRect(borderRadius: BorderRadius.circular(25), child: Image.network(img, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s)=>_buildVerse(d))),
            const SizedBox(height: 35),
            const Align(alignment: Alignment.centerLeft, child: Text("Acesso Rápido", style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 15),
            Wrap(spacing: 15, runSpacing: 15, children: [
              _atBtn(context, Icons.event, "Agenda", Colors.cyan, () => onNavigate(2)),
              _atBtn(context, Icons.groups_3, "Célula", Colors.blueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const TelaHubCelula()))),
              _atBtn(context, Icons.chat, "Contato", Colors.lime, () => launchUrl(Uri.parse("https://wa.me/5591988629296"), mode: LaunchMode.externalApplication)),
              _atBtn(context, Icons.school, "Cursos", Colors.orangeAccent, () => launchUrl(Uri.parse("https://pazbibleschool.com"), mode: LaunchMode.inAppBrowserView)),
              _atBtn(context, Icons.auto_stories, "Devocional", Colors.indigoAccent, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const TelaListaDoc(coll: 'devocionais', title: 'Devocionais')))),
              _atBtn(context, Icons.assignment, "Inscrições", Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const TelaInscricoes()))),
              _atBtn(context, Icons.shopping_bag, "Loja", Colors.pinkAccent, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const TelaLoja()))),
              _atBtn(context, Icons.play_circle_fill, "Mensagens", Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const TelaListaVideos()))),
              _atBtn(context, Icons.volunteer_activism, "Ofertas", Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (c)=>const TelaFinanceiro()))),
            ]),
            const SizedBox(height: 120),
          ]),
        );
      },
    );
  }

  Widget _buildVerse(Map d) => _GlassCard(child: Column(children: [
    const Icon(Icons.format_quote, color: Colors.amber),
    SelectableText(d['versiculo'] ?? "O Senhor é o meu pastor...", textAlign: TextAlign.center, style: GoogleFonts.notoSerif(fontSize: 16, color: Colors.white, fontStyle: FontStyle.italic)),
    Text(d['referencia'] ?? "", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
  ]));

  Widget _atBtn(BuildContext context, IconData i, String l, Color c, VoidCallback t) {
    return SizedBox(width: (MediaQuery.of(context).size.width - 85) / 3, child: InkWell(onTap: t, child: Column(children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: c.withAlpha(40), borderRadius: BorderRadius.circular(20)), child: Icon(i, color: c)),
      const SizedBox(height: 8),
      Text(l, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ])));
  }
}

// --- 4. AGENDA ---
class TelaAgendaPro extends StatelessWidget {
  const TelaAgendaPro({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text("Agenda"), backgroundColor: Colors.transparent),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('agenda').orderBy('timestamp').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              var ev = snap.data!.docs[i].data() as Map? ?? {};
              if (ev.isEmpty) return const SizedBox.shrink();
              // Extrair dia e mês de dataEvento
              String dia = "";
              String mes = "";
              if (ev['dataEvento'] != null && ev['dataEvento'] is Timestamp) {
                final DateTime dt = (ev['dataEvento'] as Timestamp).toDate();
                dia = dt.day.toString().padLeft(2, '0');
                mes = DateFormat.MMM('pt_BR').format(dt).toUpperCase();
              }
              return _GlassCard(child: Row(children: [
                Column(children: [
                  Text(dia.isNotEmpty ? dia : "--", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  Text(mes.isNotEmpty ? mes : "MES", style: const TextStyle(fontSize: 12)),
                ]),
                const SizedBox(width: 20),
                Expanded(child: Builder(
                  builder: (context) {
                    final valorStr = ev['valor'] != null ? ev['valor'].toString() : '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev['titulo']?.toString() ?? "Evento", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        Text(ev['hora']?.toString() ?? "", style: const TextStyle(color: Colors.amber)),
                        if (valorStr.isNotEmpty)
                          Text("Valor: R\$${valorStr}", style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
                      ],
                    );
                  },
                )),
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  onPressed: () => Share.share(
                    "Convidamos você: ${ev['titulo']?.toString() ?? 'Evento'} em ${dia}/${mes} às ${ev['hora']?.toString() ?? ''}"
                  ),
                )
              ]));
            },
          );
        },
      ),
    );
  }
}

// --- 5. BÍBLIA TABELA PERIÓDICA + GAME ---
class TelaBibliaPro extends StatefulWidget {
  final Function(bool) onReading; final Function(int) onNavigate;
  const TelaBibliaPro({super.key, required this.onReading, required this.onNavigate});
  @override
  State<TelaBibliaPro> createState() => _TelaBibliaProState();
}

class _TelaBibliaProState extends State<TelaBibliaPro> {
  List _livros = []; Map? _l; int? _c;
  final List<String> _siglas = ["Gn", "Ex", "Lv", "Nm", "Dt", "Js", "Jz", "Rt", "1Sm", "2Sm", "1Rs", "2Rs", "1Cr", "2Cr", "Ed", "Ne", "Et", "Jó", "Sl", "Pv", "Ec", "Ct", "Is", "Jr", "Lm", "Ez", "Dn", "Os", "Jl", "Am", "Ob", "Jn", "Mq", "Na", "Hc", "Sf", "Ag", "Zc", "Ml", "Mt", "Mc", "Lc", "Jo", "At", "Rm", "1Co", "2Co", "Gl", "Ef", "Fp", "Cl", "1Ts", "2Ts", "1Tm", "2Tm", "Tt", "Fm", "Hb", "Tg", "1Pe", "2Pe", "1Jo", "2Jo", "3Jo", "Jd", "Ap"];
  String mKey = "${DateTime.now().year}-${DateTime.now().month}";
  bool _markedRead = false;
  String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  late ConfettiController _confettiController;

  @override
  void initState() { 
    super.initState(); 
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _load();
    if (DateTime.now().day == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMonthEndDialog());
    }
  }
  _load() async { final String res = await rootBundle.loadString('assets/data/biblia.json'); setState(() => _livros = json.decode(res)); }

  Color _cor(int index) {
    // Separação por cores conforme tipos de livros da Bíblia
    if (index <= 4) return Colors.blue;        // Pentateuco
    if (index <= 16) return Colors.green;      // Livros Históricos
    if (index <= 21) return Colors.orange;     // Livros Poéticos
    if (index <= 26) return Colors.purple;     // Profetas Maiores
    if (index <= 38) return Colors.red;        // Profetas Menores
    if (index <= 42) return Colors.teal;       // Evangelhos
    if (index == 43) return Colors.cyan;       // Atos
    if (index <= 56) return Colors.indigo;     // Epístolas Paulinas
    if (index <= 64) return Colors.pink;       // Epístolas Gerais
    return Colors.amber;                       // Apocalipse
  }

  Future<void> _handleStartReading() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    final docRef = FirebaseFirestore.instance.collection('ranking').doc("${u.uid}_$mKey");
    final doc = await docRef.get();
    final data = doc.data() ?? {};
    final lastDay = data['lastAccessDay'] as String?;
    if (lastDay != today) {
      await docRef.set({
        'nome': u.email!.split('@')[0],
        'pontos': FieldValue.increment(0),
        'daysAccessed': FieldValue.increment(1),
        'totalPoints': FieldValue.increment(3),
        'month': mKey,
        'lastAccessDay': today,
      }, SetOptions(merge: true));
    }
  }

  void _showMonthEndDialog() {
    final prevMonth = DateTime.now().subtract(const Duration(days: 1));
    final prevMKey = "${prevMonth.year}-${prevMonth.month}";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🏆 Fim do Desafio Mensal!"),
        content: SizedBox(
          height: 400,
          width: 300,
          child: Stack(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('ranking').where('month', isEqualTo: prevMKey).orderBy('totalPoints', descending: true).limit(10).snapshots(),
                builder: (c, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView(
                    children: snap.data!.docs.asMap().entries.map((entry) {
                      final d = entry.value;
                      final rank = entry.key + 1;
                      String medal = "";
                      if (rank == 1) medal = "🥇";
                      else if (rank == 2) medal = "🥈";
                      else if (rank == 3) medal = "🥉";
                      return ListTile(
                        leading: Text("$medal #$rank"),
                        title: Text(d['nome']),
                        trailing: Text("${d['totalPoints']} XP"),
                      );
                    }).toList(),
                  );
                },
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: [Colors.amber, Colors.blue, Colors.green, Colors.red],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fechar")),
        ],
      ),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_livros.isEmpty) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: Text(_l == null ? "Desafio Mensal" : "${_l!['name']} ${_c ?? ''}"), backgroundColor: Colors.transparent, leading: _l != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { widget.onReading(false); setState(() { if(_c != null) _c = null; else _l = null; }); }) : null),
      body: _l == null ? _buildHome() : (_c == null ? _buildCaps() : _buildRead()),
    );
  }

  Widget _buildHome() => ListView(padding: const EdgeInsets.all(20), children: [
    ElevatedButton.icon(onPressed: () => setState(() => _l = _livros[0]), icon: const Icon(Icons.auto_stories), label: const Text("INICIAR JORNADA"), style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20))),
    const SizedBox(height: 25),
    const Text("🏆 TOP 10 LEITORES", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ranking').where('month', isEqualTo: mKey).orderBy('totalPoints', descending: true).limit(10).snapshots(),
      builder: (c, snap) {
        if(!snap.hasData) return const LinearProgressIndicator();
        return _GlassCard(child: Column(children: snap.data!.docs.map((d) => ListTile(dense: true, title: Text(d['nome']), trailing: Text("${d['totalPoints']} XP"))).toList()));
      },
    ),
    const SizedBox(height: 25),
    GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8), itemCount: _livros.length, itemBuilder: (c, i) => InkWell(
      onTap: () => setState(() => _l = _livros[i]),
      child: Container(decoration: BoxDecoration(color: _cor(i).withAlpha(40), borderRadius: BorderRadius.circular(8), border: Border.all(color: _cor(i))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_siglas[i], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        Text(_livros[i]['name'], style: const TextStyle(fontSize: 6), overflow: TextOverflow.ellipsis),
      ])),
    )),
  ]);

  Widget _buildCaps() => GridView.builder(padding: const EdgeInsets.all(25), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10), itemCount: _l!['chapters'].length, itemBuilder: (c, i) => InkWell(onTap: () async { await _handleStartReading(); setState(() { _c = i + 1; _markedRead = false; }); widget.onReading(true); }, child: Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Center(child: Text("${i + 1}", style: const TextStyle(color: Colors.white))))));

  Widget _buildRead() => Column(children: [
    Expanded(child: ListView(
        padding: const EdgeInsets.all(30),
        children: [
          ..._l!['chapters'][_c! - 1].asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: SelectableText("${e.key + 1} ${e.value}", style: GoogleFonts.notoSerif(fontSize: 18, color: Colors.white, height: 1.8))))
        ])),
    _GlassCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            if (_c! > 1) setState(() => _c = _c! - 1);
          }),
      ElevatedButton(
          onPressed: _markedRead
              ? null
              : () async {
                  final u = FirebaseAuth.instance.currentUser;
                  if (u != null) {
                    final docRef = FirebaseFirestore.instance
                        .collection('ranking')
                        .doc("${u.uid}_$mKey");
                    final doc = await docRef.get();
                    final data = doc.data() ?? {};
                    List lidos = (data['lidos'] ?? []) as List;
                    final capObj = {
                      'livro': _l!['abbrev'],
                      'cap': _c
                    };
                    final jaLeu = lidos.any((el) =>
                        el is Map &&
                        el['livro'] == capObj['livro'] &&
                        el['cap'] == capObj['cap']);
                    if (!jaLeu) {
                      lidos.add(capObj);
                      await docRef.set({
                        'nome': u.email!.split('@')[0],
                        'pontos': FieldValue.increment(1),
                        'totalPoints': FieldValue.increment(1),
                        'month': mKey,
                        'lidos': lidos,
                      }, SetOptions(merge: true));
                      setState(() => _markedRead = true);
                    } else {
                      setState(() => _markedRead = true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Você já marcou este capítulo como lido.')));
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
              backgroundColor:
                  _markedRead ? Colors.green : Colors.grey.withOpacity(0.5)),
          child: Text(_markedRead ? "LIDO ✅" : "MARCAR LIDO")),
      IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            if (_c! < _l!['chapters'].length) setState(() => _c = _c! + 1);
          }),
    ])),
    const SizedBox(height: 20),
  ]);
}

// --- 6. ÁREA DO MEMBRO ---
class AbaMembroFull extends StatefulWidget {
  const AbaMembroFull({super.key});

  @override
  State<AbaMembroFull> createState() => _AbaMembroFullState();
}

class _AbaMembroFullState extends State<AbaMembroFull> {
  Future<bool> _isOperator(String email) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('operadores').doc(email).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            body: Center(
              child: _GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 40, color: Colors.amber),
                    const SizedBox(height: 20),
                    const Text('Área do membro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => signInWithGoogle(context),
                      child: const Text('Login Google'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Área do Membro'), backgroundColor: Colors.transparent),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
            children: [
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olá, ${user.displayName ?? user.email?.split('@').first ?? 'Membro'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(user.email ?? '', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logout realizado')));
                        }
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
              _item('Relatório de Célula', Icons.assignment, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TelaFormRelatorio()))),
              _item('Volts', Icons.flash_on, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TelaVoltsMembro()))),
              _item('Minha Identidade', Icons.qr_code, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TelaCadastroMembro()))),
              _item('Inscrições', Icons.event_available, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TelaInscricoes()))),
              FutureBuilder<bool>(
                future: _isOperator(user.email ?? ''),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (snap.hasData && snap.data == true) {
                    return _expansion('Acesso Restrito', Icons.security, [
                      _sub('Check-in/Check-out', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TelaCheckInOut()))),
                      _sub('Relatório Culto', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TelaListaDoc(coll: 'relatorios_culto', title: 'Relatório Culto')))),
                      _sub('Relatório DIFLEN', () => Navigator.push(context, MaterialPageRoute(builder: (c) => const TelaListaDoc(coll: 'relatorios_diflen', title: 'Relatório DIFLEN')))),
                    ]);
                  } else {
                    return _item('Acesso Restrito', Icons.security, () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Acesso não autorizado'),
                          content: const Text('Você não tem permissão para acessar esta área.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _item(String t, IconData i, VoidCallback tap) => _GlassCard(child: ListTile(leading: Icon(i, color: Colors.blueAccent), title: Text(t, style: const TextStyle(color: Colors.white)), onTap: tap));
  Widget _expansion(String t, IconData i, List<Widget> c) => _GlassCard(child: ExpansionTile(leading: Icon(i, color: Colors.amber), title: Text(t, style: const TextStyle(color: Colors.white)), children: c));
  Widget _sub(String t, [VoidCallback? tap]) => ListTile(title: Text(t, style: const TextStyle(fontSize: 14, color: Colors.white70)), trailing: const Icon(Icons.chevron_right, size: 14), onTap: tap);
}

// --- 7. HUB CÉLULA & LEITURA ---
class TelaHubCelula extends StatelessWidget {
  const TelaHubCelula({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF0F172A), appBar: AppBar(title: const Text("Célula"), backgroundColor: Colors.transparent), body: Padding(padding: const EdgeInsets.all(25), child: GridView.count(crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, children: [
    _it(context, "Estudo", Icons.book, Colors.blue, "Estudo"), _it(context, "Crescimento", Icons.trending_up, Colors.green, "Crescimento"),
    _it(context, "Dinâmicas", Icons.auto_fix_high, Colors.purple, "Dinâmicas"), _it(context, "Quero uma Célula", Icons.chat_bubble_outline, Colors.teal, "", isWa: true),
  ])));
  Widget _it(BuildContext context, String l, IconData i, Color c, String id, {bool isWa = false}) => _GlassCard(child: InkWell(onTap: () => isWa ? launchUrl(Uri.parse("https://wa.me/5591988629296")) : Navigator.push(context, MaterialPageRoute(builder: (c)=>TelaListaDoc(coll: 'celula_conteudo', title: l))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, color: c, size: 32), const SizedBox(height: 8), Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.white))])));
}

class TelaLeituraDoc extends StatefulWidget {
  final String id; final String title; final String coll;
  const TelaLeituraDoc({super.key, required this.id, required this.title, required this.coll});
  @override
  State<TelaLeituraDoc> createState() => _TelaLeituraDocState();
}

class _TelaLeituraDocState extends State<TelaLeituraDoc> {
  late CollectionReference _colRef;
  late DocumentReference _docRef;

  @override
  void initState() {
    super.initState();
    _colRef = FirebaseFirestore.instance.collection(widget.coll);
    _docRef = _colRef.doc(widget.id);
  }

  Future<void> _toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faça login para curtir')));
      return;
    }
    try {
      final doc = await _docRef.get();
      final likes = List<String>.from(doc['likes'] ?? []);
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      await _docRef.update({'likes': likes});
    } catch (e) {
      debugPrint('Erro ao atualizar like: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title), actions: [IconButton(icon: const Icon(Icons.share), onPressed: () => Share.share("*${widget.title}*\nNo app da Paz!"))]),
    body: StreamBuilder<DocumentSnapshot>(
      stream: _docRef.snapshots(),
      builder: (context, snap) {
        Map data = snap.data?.data() as Map? ?? {};
        quill.QuillController _q;
        try {
          _q = quill.QuillController(
            document: quill.Document.fromJson(jsonDecode(data['texto'] ?? data['conteudo'])),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          _q = quill.QuillController(
            document: quill.Document()..insert(0, data['texto'] ?? data['conteudo'] ?? "Em breve"),
            selection: const TextSelection.collapsed(offset: 0),
          );
        }
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final likes = List<String>.from(data['likes'] ?? []);
        final isLiked = userId != null && likes.contains(userId);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              _GlassCard(
                child: AbsorbPointer(
                  child: quill.QuillEditor.basic(
                    configurations: quill.QuillEditorConfigurations(controller: _q),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(40),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.red.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            likes.length.toString(),
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

// --- 8. LOJA PAZ ---
class TelaLoja extends StatelessWidget {
  const TelaLoja({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Loja Paz")), body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
    _AdsBanner(title: "Livros do Pr. Francinaldo", url: "https://share.google/To7MjnzASZFSbiNDE"),
    const SizedBox(height: 20),
    GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.7, children: [
      _p(context, "Livro do Discípulo", "R\$ 25,00", "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400"),
      _p(context, "Camisa VOLTS", "R\$ 40,00", "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=400"),
    ]),
  ])));
  Widget _p(context, t, p, img) => _GlassCard(child: Column(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(img, fit: BoxFit.cover))), Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)), Text(p, style: const TextStyle(color: Colors.amber)), ElevatedButton(onPressed: () => launchUrl(Uri.parse("https://wa.me/5591988629296?text=Olá, quero comprar o $t")), child: const Text("COMPRAR", style: TextStyle(fontSize: 10)))]));
}

// --- DEMAIS TELAS ---
class TelaCheckInOut extends StatefulWidget {
  const TelaCheckInOut({super.key});

  @override
  State<TelaCheckInOut> createState() => _TelaCheckInOutState();
}

class _TelaCheckInOutState extends State<TelaCheckInOut> {
  String _scannedCode = '';
  bool _isProcessing = false;
  Map<String, dynamic>? _memberData;
  bool _isCheckIn = true; // true = check-in, false = check-out
  Map<String, bool> _selectedItems = {
    'cracha': false,
    'cordao': false,
    'equipamento': false,
  };
  List<Map<String, dynamic>> _pendingCheckouts = [];

  @override
  void initState() {
    super.initState();
    _loadPendingCheckouts();
  }

  Future<void> _loadPendingCheckouts() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await FirebaseFirestore.instance
          .collection('volts_checkin')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .where('situacao', isEqualTo: 'Em uso')
          .get();

      setState(() {
        _pendingCheckouts = snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList();
      });
    } catch (e) {
      print('Erro ao carregar check-outs pendentes: $e');
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result != null && result is String) {
      setState(() {
        _scannedCode = result;
        _isProcessing = true;
      });

      await _processScan(result);
    }
  }

  Future<void> _processScan(String qrCode) async {
    try {
      // Buscar dados do membro no Firestore
      final memberDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(qrCode)
          .get();

      if (!memberDoc.exists) {
        throw Exception('Membro não encontrado');
      }

      final memberData = memberDoc.data()!;
      setState(() {
        _memberData = memberData;
      });

      // Verificar se já fez check-in hoje
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingCheckin = await FirebaseFirestore.instance
          .collection('volts_checkin')
          .where('user_id', isEqualTo: qrCode)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (existingCheckin.docs.isNotEmpty) {
        // Já fez check-in hoje, perguntar se quer fazer check-out
        final checkinData = existingCheckin.docs.first.data();
        final checkedItems = checkinData['itens'] as Map<String, dynamic>? ?? {};

        setState(() {
          _isCheckIn = false;
          _selectedItems = {
            'cracha': checkedItems['cracha'] == true,
            'cordao': checkedItems['cordao'] == true,
            'equipamento': checkedItems['equipamento'] == true,
          };
        });

        if (context.mounted) {
          final shouldCheckout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Check-out'),
              content: Text('Membro ${memberData['nome']} já fez check-in hoje. Deseja fazer check-out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Check-out'),
                ),
              ],
            ),
          );

          if (shouldCheckout == true) {
            await _showCheckoutDialog(existingCheckin.docs.first.id, checkinData);
          }
        }
      } else {
        // Primeiro check-in do dia
        setState(() {
          _isCheckIn = true;
          _selectedItems = {'cracha': false, 'cordao': false, 'equipamento': false};
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _showCheckoutDialog(String docId, Map<String, dynamic> checkinData) async {
    final checkedItems = checkinData['itens'] as Map<String, dynamic>? ?? {};
    Map<String, bool> returnedItems = {
      'cracha': false,
      'cordao': false,
      'equipamento': false,
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Check-out: ${_memberData?['nome']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Itens à devolver:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (checkedItems['cracha'] == true)
                CheckboxListTile(
                  title: const Text('Crachá'),
                  value: returnedItems['cracha'],
                  onChanged: (value) => setState(() => returnedItems['cracha'] = value ?? false),
                ),
              if (checkedItems['cordao'] == true)
                CheckboxListTile(
                  title: const Text('Cordão'),
                  value: returnedItems['cordao'],
                  onChanged: (value) => setState(() => returnedItems['cordao'] = value ?? false),
                ),
              if (checkedItems['equipamento'] == true)
                CheckboxListTile(
                  title: const Text('Equipamento'),
                  value: returnedItems['equipamento'],
                  onChanged: (value) => setState(() => returnedItems['equipamento'] = value ?? false),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _performCheckout(docId, returnedItems);
                Navigator.pop(context);
              },
              child: const Text('Confirmar Check-out'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCheckout(String docId, Map<String, bool> returnedItems) async {
    try {
      // Atualizar no Firestore
      await FirebaseFirestore.instance
          .collection('volts_checkin')
          .doc(docId)
          .update({
            'situacao': 'Checkout OK',
            'checkout_timestamp': FieldValue.serverTimestamp(),
            'itens_devolvidos': returnedItems,
          });

      // Enviar para Google Sheets
      final checkoutData = {
        'user_id': _scannedCode,
        'nome': _memberData?['nome'],
        'ministerio': _memberData?['ministerio'],
        'itens': returnedItems,
        'situacao': 'Checkout OK',
        'tipo': 'checkout',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _sendToVoltsSheet(checkoutData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check-out realizado com sucesso!')),
        );
        _loadPendingCheckouts(); // Recarregar lista
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no check-out: $e')),
        );
      }
    }
  }

  Future<void> _performCheckin() async {
    if (_memberData == null) return;

    try {
      final checkinData = {
        'user_id': _scannedCode,
        'nome': _memberData!['nome'],
        'ministerio': _memberData!['ministerio'],
        'itens': _selectedItems,
        'situacao': 'Em uso',
        'timestamp': FieldValue.serverTimestamp(),
        'tipo': 'checkin',
      };

      // Salvar no Firestore
      await FirebaseFirestore.instance.collection('volts_checkin').add(checkinData);

      // Enviar para Google Sheets
      await _sendToVoltsSheet(checkinData);

      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Check-in Realizado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text('Check-in realizado com sucesso para ${_memberData!['nome']}!'),
                const SizedBox(height: 8),
                const Text('Itens emprestados:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_selectedItems['cracha']!) const Text('• Crachá'),
                if (_selectedItems['cordao']!) const Text('• Cordão'),
                if (_selectedItems['equipamento']!) const Text('• Equipamento'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        _loadPendingCheckouts(); // Recarregar lista
        setState(() {
          _memberData = null;
          _scannedCode = '';
          _selectedItems = {'cracha': false, 'cordao': false, 'equipamento': false};
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no check-in: $e')),
        );
      }
    }
  }

  Future<void> _sendToVoltsSheet(Map<String, dynamic> data) async {
    const String scriptUrl = 'https://script.google.com/macros/s/AKfycbzZ4mQU_8NlcSX61LAQQcPMgfLGUUz160yBthg14-8D3IavWKHoNVmYkSQCiqJXqDLH/exec';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'spreadsheetId': '1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4',
          'sheetName': 'Volts',
          'data': data,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao enviar para planilha: ${response.statusCode}');
      }

      final responseData = jsonDecode(response.body);
      if (!responseData['success']) {
        throw Exception('Erro na planilha: ${responseData['error']}');
      }
    } catch (e) {
      // Log error but don't block the flow
      print('Erro ao enviar para planilha Volts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in/Check-out'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingCheckouts,
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Lista de check-outs pendentes
            if (_pendingCheckouts.isNotEmpty) ...[
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pending_actions, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '${_pendingCheckouts.length} check-out(s) pendente(s)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._pendingCheckouts.map((checkout) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              checkout['nome'] ?? 'Nome não informado',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          Text(
                            checkout['ministerio'] ?? '',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Scanner QR
            _GlassCard(
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, size: 60, color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  const Text(
                    'Escanear QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Aponte a câmera para o QR Code da identidade do membro',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _scanQR,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_isProcessing ? 'Processando...' : 'Escanear'),
                  ),
                ],
              ),
            ),

            // Dados do membro escaneado
            if (_memberData != null) ...[
              const SizedBox(height: 20),
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCheckIn ? 'Check-in' : 'Check-out',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nome: ${_memberData!['nome'] ?? 'Não informado'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      'Ministério: ${_memberData!['ministerio'] ?? 'Não informado'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _isCheckIn ? 'Itens para empréstimo:' : 'Itens à devolver:',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Crachá', style: TextStyle(color: Colors.white)),
                      value: _selectedItems['cracha'],
                      onChanged: _isCheckIn
                          ? (value) => setState(() => _selectedItems['cracha'] = value ?? false)
                          : null,
                      activeColor: Colors.amber,
                    ),
                    CheckboxListTile(
                      title: const Text('Cordão', style: TextStyle(color: Colors.white)),
                      value: _selectedItems['cordao'],
                      onChanged: _isCheckIn
                          ? (value) => setState(() => _selectedItems['cordao'] = value ?? false)
                          : null,
                      activeColor: Colors.amber,
                    ),
                    CheckboxListTile(
                      title: const Text('Equipamento', style: TextStyle(color: Colors.white)),
                      value: _selectedItems['equipamento'],
                      onChanged: _isCheckIn
                          ? (value) => setState(() => _selectedItems['equipamento'] = value ?? false)
                          : null,
                      activeColor: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCheckIn ? _performCheckin : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCheckIn ? Colors.green : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_isCheckIn ? 'Confirmar Check-in' : 'Aguardando check-out...'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatelessWidget {
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner QR'), backgroundColor: Colors.transparent),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

class TelaListaVideos extends StatelessWidget { const TelaListaVideos({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Mensagens")), body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('mensagens').snapshots(), builder: (c, snap) {
    if(!snap.hasData) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(20), children: snap.data!.docs.map((v) => _GlassCard(child: Column(children: [ClipRRect(borderRadius: BorderRadius.circular(15), child: YoutubePlayer(controller: YoutubePlayerController.fromVideoId(videoId: YoutubePlayerController.convertUrlToId(v['url'])!, params: const YoutubePlayerParams(showControls: true)))), const SizedBox(height: 10), Text(v['titulo'], style: const TextStyle(color: Colors.white))]))).toList());
  })); }

class TelaAvisosPro extends StatefulWidget {
  const TelaAvisosPro({super.key});

  @override
  State<TelaAvisosPro> createState() => _TelaAvisosProState();
}

class _TelaAvisosProState extends State<TelaAvisosPro> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    appBar: AppBar(title: const Text("Mural")),
    body: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('avisos').orderBy('data', descending: true).snapshots(),
      builder: (c, snap) => ListView(
        padding: const EdgeInsets.all(20),
        children: (snap.data?.docs ?? []).map((doc) => Dismissible(
          key: Key(doc.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Confirmar exclusão"),
                  content: const Text("Tem certeza que deseja excluir este aviso?"),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Excluir"),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            FirebaseFirestore.instance.collection('avisos').doc(doc.id).delete();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aviso excluído')),
            );
          },
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['titulo'] ?? "",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF818CF8)),
                ),
                Text(
                  doc['descricao'] ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        )).toList(),
      ),
    ),
  );
}
class TelaFinanceiro extends StatelessWidget { const TelaFinanceiro({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Ofertas")), body: StreamBuilder<DocumentSnapshot>(stream: FirebaseFirestore.instance.collection('config').doc('home').snapshots(), builder: (c, snap) => Padding(padding: const EdgeInsets.all(30), child: SizedBox(width: double.infinity, child: _GlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.qr_code_2, size: 80), Text(snap.data?['chavePix'] ?? ""), ElevatedButton(onPressed: () { Clipboard.setData(ClipboardData(text: snap.data?['chavePix'])); }, child: const Text("Copiar PIX"))])))))); }
class TelaListaDoc extends StatelessWidget {
  final String coll;
  final String title;
  const TelaListaDoc({super.key, required this.coll, required this.title});

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> stream;
    if (coll == 'celula_conteudo' && (title == 'Estudo' || title == 'Crescimento')) {
      stream = FirebaseFirestore.instance
          .collection(coll)
          .where('tipo', isEqualTo: title)
          .orderBy('data', descending: true)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection(coll)
          .orderBy('data', descending: true)
          .snapshots();
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (c, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhum conteúdo disponível', style: TextStyle(color: Colors.white70)));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: docs.where((d) {
              final data = d.data() as Map? ?? {};
              return data.isNotEmpty && (data['titulo']?.toString() ?? '').isNotEmpty;
            }).map((d) {
              final data = d.data() as Map? ?? {};
              final titulo = data['titulo']?.toString() ?? d.id;
              final subtitulo = data['subtitulo']?.toString() ?? '';
              return _GlassCard(
                child: ListTile(
                  title: Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: subtitulo.isNotEmpty ? Text(subtitulo, style: const TextStyle(color: Colors.white70)) : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => TelaLeituraDoc(id: d.id, title: titulo, coll: coll),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
class TelaInscricoes extends StatelessWidget {
  const TelaInscricoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscrições")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('inscricoes').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Nenhuma inscrição disponível.", style: TextStyle(color: Colors.white)));
          }
          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final nome = d['nome'] ?? 'Evento';
              final dataEvento = d['data_evento'];
              final dataLimite = d['data_limite'];
              final valor = d['valor'] != null ? double.tryParse(d['valor'].toString().replaceAll(',', '.')) ?? 0.0 : 0.0;
              String? dataEventoStr;
              String? dataLimiteStr;
              if (dataEvento != null && dataEvento is Timestamp) {
                final dt = dataEvento.toDate();
                dataEventoStr = DateFormat('dd/MM/yyyy').format(dt);
              }
              if (dataLimite != null && dataLimite is Timestamp) {
                final dt = dataLimite.toDate();
                dataLimiteStr = DateFormat('dd/MM/yyyy').format(dt);
              }
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: Text(nome, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dataEventoStr != null) Text('Data do evento: $dataEventoStr', style: const TextStyle(color: Colors.white70)),
                      if (dataLimiteStr != null) Text('Inscrições até: $dataLimiteStr', style: const TextStyle(color: Colors.white70)),
                      if (valor > 0) Text('Valor: R\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  trailing: valor > 0
                      ? ElevatedButton.icon(
                          icon: const Icon(Icons.pix, size: 18),
                          label: const Text('Pagar'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => TelaPagamentoPix(valor: valor, inscricaoId: docs[i].id),
                              ),
                            );
                          },
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class TelaFormRelatorio extends StatefulWidget {
  const TelaFormRelatorio({super.key});

  @override
  State<TelaFormRelatorio> createState() => _TelaFormRelatorioState();
}

class _TelaFormRelatorioState extends State<TelaFormRelatorio> {
  final _formKey = GlobalKey<FormState>();
  final _dataController = TextEditingController();
  final _liderController = TextEditingController();
  final _membrosController = TextEditingController();
  final _convidadosController = TextEditingController();
  final _criancasController = TextEditingController();
  final _ofertasController = TextEditingController();
  final _observacoesController = TextEditingController();
  bool _supervisao = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Define a data atual como padrão
    final now = DateTime.now();
    _dataController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  @override
  void dispose() {
    _dataController.dispose();
    _liderController.dispose();
    _membrosController.dispose();
    _convidadosController.dispose();
    _criancasController.dispose();
    _ofertasController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Color(0xFF1a1a2e),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dataController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Salva no Firestore primeiro
      final user = FirebaseAuth.instance.currentUser;
      final relatorioData = {
        'data': _dataController.text,
        'lider': _liderController.text.trim(),
        'membros_presentes': int.tryParse(_membrosController.text) ?? 0,
        'convidados': int.tryParse(_convidadosController.text) ?? 0,
        'criancas': int.tryParse(_criancasController.text) ?? 0,
        'ofertas': double.tryParse(_ofertasController.text.replaceAll(',', '.')) ?? 0.0,
        'supervisao': _supervisao,
        'observacoes': _observacoesController.text.trim(),
        'user_id': user?.uid,
        'user_name': user?.displayName ?? user?.email?.split('@').first ?? 'Anônimo',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('relatorios_celula').add(relatorioData);

      // Envia para Google Sheets
      await _sendToGoogleSheets(relatorioData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório enviado com sucesso!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar relatório: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testGoogleSheetsConnection() async {
    setState(() => _isLoading = true);

    try {
      // Dados de teste
      final testData = {
        'data': '01/01/2024',
        'lider': 'Teste Líder',
        'membros_presentes': 5,
        'convidados': 2,
        'criancas': 1,
        'ofertas': 100.50,
        'supervisao': true,
        'observacoes': 'Teste de conexão com planilha',
        'user_name': 'Usuário Teste',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Salva no Firestore primeiro
      await FirebaseFirestore.instance.collection('relatorios_celula_teste').add(testData);

      // Tenta enviar para Google Sheets
      await _sendToGoogleSheets(testData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Teste realizado com sucesso! Verifique a planilha.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro no teste: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToGoogleSheets(Map<String, dynamic> data) async {
    // TODO: Substitua pela URL do seu Google Apps Script
    // Para criar o script:
    // 1. Acesse https://script.google.com
    // 2. Crie um novo projeto
    // 3. Cole o código do arquivo google_apps_script.js
    // 4. Publique como web app (Execute as: eu, Acesso: qualquer pessoa)
    // 5. Copie a URL e substitua abaixo
    const String scriptUrl = 'https://script.google.com/macros/s/AKfycbxcoNcZhKcTaYjOcGTHJdZbiEZlS8HQMNG5jleDkbvaFWGo_QXP_bMXf0fKZgHLkPbt/exec';

    try {
      final response = await http.post(
        Uri.parse(scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'spreadsheetId': '1hRmGeYYvKyxHJw2NpLNMRAK2ThqLkUo0SwfEy12otc4',
          'sheetName': 'Células',
          'data': data,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao enviar para planilha: ${response.statusCode} - ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      if (!responseData['success']) {
        throw Exception('Erro na planilha: ${responseData['error']}');
      }
    } catch (e) {
      // Se falhar o envio para planilha, ainda salva no Firestore
      // mas mostra aviso ao usuário
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aviso: Relatório salvo localmente, mas houve erro na sincronização com planilha: $e')),
        );
      }
      // Não lança erro para não impedir o fluxo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Célula'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.bug_report),
              tooltip: 'Testar conexão com planilha',
              onPressed: _testGoogleSheetsConnection,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _submitForm,
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => const TelaListaDoc(coll: 'relatorios_celula', title: 'Relatórios Enviados')
          )
        ),
        child: const Icon(Icons.list),
        tooltip: 'Ver relatórios enviados',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(
              controller: _dataController,
              label: 'Data da reunião',
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo obrigatório';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _liderController,
              label: 'Líder',
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo obrigatório';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _membrosController,
              label: 'Membros presentes',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo obrigatório';
                if (int.tryParse(value!) == null) return 'Digite um número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _convidadosController,
              label: 'Convidados',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo obrigatório';
                if (int.tryParse(value!) == null) return 'Digite um número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _criancasController,
              label: 'Crianças',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo obrigatório';
                if (int.tryParse(value!) == null) return 'Digite um número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ofertasController,
              label: 'Ofertas (R\$)',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo obrigatório';
                final numValue = double.tryParse(value!.replaceAll(',', '.'));
                if (numValue == null) return 'Digite um valor válido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _GlassCard(
              child: SwitchListTile(
                title: const Text('Supervisão', style: TextStyle(color: Colors.white)),
                value: _supervisao,
                onChanged: (value) => setState(() => _supervisao = value),
                activeColor: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _observacoesController,
              label: 'Observações',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return _GlassCard(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white30),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white30),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.amber),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        maxLines: maxLines ?? 1,
      ),
    );
  }
}
class TelaVoltsMembro extends StatelessWidget { const TelaVoltsMembro({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("QR")), body: Center(child: _GlassCard(child: QrImageView(data: FirebaseAuth.instance.currentUser!.uid, size: 200, backgroundColor: Colors.white)))); }
class TelaOperadorVolts extends StatelessWidget { final bool isCheckin; const TelaOperadorVolts({super.key, required this.isCheckin}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(isCheckin ? "Check-in" : "Check-out")), body: MobileScanner(onDetect: (c){})); }
class TelaLoginMembro extends StatelessWidget { const TelaLoginMembro({super.key}); @override Widget build(BuildContext context) => Scaffold(body: Center(child: _GlassCard(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.lock, size: 40, color: Colors.amber), ElevatedButton(onPressed: () => FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider()), child: const Text("Login Google"))])))); }
class TelaCadastroMembro extends StatefulWidget { const TelaCadastroMembro({super.key}); @override State<TelaCadastroMembro> createState() => _TelaCadastroMembroState(); }
class _TelaCadastroMembroState extends State<TelaCadastroMembro> {
  final _nomeController = TextEditingController();
  final _ministerioController = TextEditingController();
  final _nascimentoController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
        if (doc.exists) {
          _userData = doc.data();
          _nomeController.text = _userData?['nome'] ?? '';
          _ministerioController.text = _userData?['ministerio'] ?? '';
          _nascimentoController.text = _userData?['nascimento'] ?? '';
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveData() async {
    if (_nomeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome é obrigatório')),
      );
      return;
    }

    if (_ministerioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ministério é obrigatório')),
      );
      return;
    }

    if (_nascimentoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data de nascimento é obrigatória')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
          'nome': _nomeController.text.trim(),
          'ministerio': _ministerioController.text.trim(),
          'nascimento': _nascimentoController.text.trim(),
          'email': user.email,
          'uid': user.uid,
          'dataCadastro': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados salvos com sucesso!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Identidade'),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete seu cadastro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Essas informações são necessárias para gerar seu QR Code único.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 30),
                        TextField(
                          controller: _nomeController,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _ministerioController,
                          decoration: const InputDecoration(
                            labelText: 'Ministério',
                            hintText: 'Ex: Louvor, Dança, Coreografia...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.work),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nascimentoController,
                          decoration: const InputDecoration(
                            labelText: 'Data de nascimento',
                            hintText: 'DD/MM/AAAA',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.datetime,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveData,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSaving
                                ? const CircularProgressIndicator()
                                : const Text('SALVAR E GERAR QR CODE'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_userData != null) ...[
                    const SizedBox(height: 20),
                    _GlassCard(
                      child: Column(
                        children: [
                          const Text(
                            'Seu QR Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          QrImageView(
                            data: FirebaseAuth.instance.currentUser!.uid,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Este QR Code é sua identidade digital de membro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          SizedBox(height: 10),
                          Divider(color: Colors.white24),
                          SizedBox(height: 10),
                          Text(
                            'Como usar para Check-in/Check-out:',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('1. Abra esta tela e mostre seu QR Code ao operador.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('2. O operador irá escanear seu QR Code no app.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('3. Confirme os itens recebidos/devolvidos conforme solicitado.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('4. Pronto! Seu check-in/check-out será registrado.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Text('Dica: Não compartilhe este QR Code com outras pessoas.', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ministerioController.dispose();
    _nascimentoController.dispose();
    super.dispose();
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child; const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withAlpha(20))), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Padding(padding: const EdgeInsets.all(28), child: child))));
}
class _AdsBanner extends StatelessWidget {
  final String title; final String url;
  const _AdsBanner({required this.title, required this.url});
  @override
  Widget build(BuildContext context) => InkWell(onTap: () => launchUrl(Uri.parse(url)), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]), borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.library_books), const SizedBox(width: 15), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))), const Icon(Icons.open_in_new, size: 14)])));
}