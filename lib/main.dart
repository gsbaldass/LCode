import 'dart:convert';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Barcode;
import 'package:shared_preferences/shared_preferences.dart';

// ---------- Modelo ----------
class Frasco {
  String id, doadora, tipo; // tipo: C, T, M
  int ml;
  DateTime coleta, pasteur;
  double? cremato, dornic, temp;
  String status; // estoque | reservado | enviado
  String? rn;
  Frasco(this.id, this.doadora, this.tipo, this.ml, this.coleta, this.pasteur,
      {this.cremato, this.dornic, this.temp, this.status = 'estoque', this.rn});

  static String _d(DateTime d) => d.toIso8601String().substring(0, 10);
  static String br(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String get payload => jsonEncode({
        'f': id, 'd': doadora, 't': tipo, 'ml': ml, 'c': _d(coleta), 'p': _d(pasteur),
        if (cremato != null) 'cr': cremato, if (dornic != null) 'do': dornic,
        if (temp != null) 'tp': temp,
      });

  Map<String, dynamic> toJson() => {
        'id': id, 'doadora': doadora, 'tipo': tipo, 'ml': ml, 'coleta': _d(coleta),
        'pasteur': _d(pasteur), 'cremato': cremato, 'dornic': dornic, 'temp': temp,
        'status': status, 'rn': rn,
      };
  factory Frasco.fromJson(Map j) => Frasco(j['id'], j['doadora'], j['tipo'], j['ml'],
      DateTime.parse(j['coleta']), DateTime.parse(j['pasteur']),
      cremato: j['cremato']?.toDouble(), dornic: j['dornic']?.toDouble(),
      temp: j['temp']?.toDouble(), status: j['status'], rn: j['rn']);
}

const tipos = {'C': 'Colostro', 'T': 'Transição', 'M': 'Maduro'};

// ---------- Visual ----------
class Paleta {
  static const bg = Color(0xFFE6F1EC);
  static const forest = Color(0xFF15463A);
  static const forestMid = Color(0xFF1B5C4A);
  static const mint = Color(0xFFD8EBE3);
  static const mintSoft = Color(0xFFF3F8F6);
  static const coral = Color(0xFFE86B5A);
  static const peach = Color(0xFFF3A15F);
  static const ink = Color(0xFF122E27);
  static const muted = Color(0xFF6A857C);
  static const line = Color(0xFFD3E4DC);
}

TextTheme _texto(TextTheme base) {
  final f = GoogleFonts.plusJakartaSansTextTheme(base);
  return f.copyWith(
    headlineLarge: f.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: Paleta.ink, letterSpacing: -0.8, height: 1.1),
    headlineMedium: f.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: Paleta.ink, letterSpacing: -0.6),
    titleLarge: f.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Paleta.ink, letterSpacing: -0.3),
    titleMedium: f.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Paleta.ink),
    bodyLarge: f.bodyLarge?.copyWith(color: Paleta.ink, height: 1.35),
    bodyMedium: f.bodyMedium?.copyWith(color: Paleta.muted, height: 1.4),
    labelLarge: f.labelLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.1),
  );
}

InputDecoration _campo(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 20, color: Paleta.forestMid),
      filled: true,
      fillColor: Paleta.mintSoft,
      labelStyle: const TextStyle(color: Paleta.muted, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Paleta.forestMid, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

class SoftCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const SoftCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });
  @override
  Widget build(BuildContext c) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: Paleta.forest.withValues(alpha: 0.06), blurRadius: 22, offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(26), onTap: onTap, child: body));
  }
}

class ChipStatus extends StatelessWidget {
  final String status;
  const ChipStatus(this.status, {super.key});
  @override
  Widget build(BuildContext c) {
    final map = {
      'estoque': (Paleta.mint, Paleta.forest, 'Estoque'),
      'reservado': (const Color(0xFFFFE8D6), Paleta.peach, 'Reservado'),
      'enviado': (const Color(0xFFFFE3DE), Paleta.coral, 'Enviado'),
    };
    final s = map[status] ?? (Paleta.mint, Paleta.forest, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: s.$1, borderRadius: BorderRadius.circular(20)),
      child: Text(s.$3, style: TextStyle(color: s.$2, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String kicker, title;
  const PageHeader(this.kicker, this.title, {super.key});
  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(kicker, style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(c).textTheme.headlineMedium),
        ]),
      );
}

ButtonStyle get _pill => FilledButton.styleFrom(
      backgroundColor: Paleta.forest,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
    );

ButtonStyle get _pillSoft => FilledButton.styleFrom(
      backgroundColor: Paleta.mint,
      foregroundColor: Paleta.forest,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 15),
    );

// ---------- Estado / persistência ----------
class Store extends ChangeNotifier {
  List<Frasco> frascos = [];
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString('frascos');
    if (s != null) frascos = (jsonDecode(s) as List).map((e) => Frasco.fromJson(e)).toList();
    notifyListeners();
  }
  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('frascos', jsonEncode(frascos.map((f) => f.toJson()).toList()));
    notifyListeners();
  }
  Future<void> add(Frasco f) async { frascos.add(f); await save(); }
  int nextId() => frascos.length + 1;

  List<Frasco> sugerir(String tipo, int ml) {
    final c = frascos.where((f) => f.status == 'estoque' && f.tipo == tipo).toList();
    final unico = c.where((f) => f.ml >= ml).toList()..sort((a, b) => a.ml.compareTo(b.ml));
    if (unico.isNotEmpty) return [unico.first];
    c.sort((a, b) => b.ml != a.ml ? b.ml.compareTo(a.ml) : a.pasteur.compareTo(b.pasteur));
    final sel = <Frasco>[]; var soma = 0;
    for (final f in c) { if (soma >= ml) break; sel.add(f); soma += f.ml; }
    return soma >= ml ? sel : [];
  }
}

final store = Store();

void main() { store.load(); runApp(const App()); }

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Paleta.forest, surface: Paleta.bg),
      scaffoldBackgroundColor: Paleta.bg,
    );
    return MaterialApp(
      title: 'BLH Marília',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: _texto(base.textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Paleta.bg,
          foregroundColor: Paleta.ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20, color: Paleta.ink),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: Paleta.forest,
          contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        filledButtonTheme: FilledButtonThemeData(style: _pill),
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget { const Home({super.key}); @override State<Home> createState() => _HomeState(); }
class _HomeState extends State<Home> {
  int i = 0;
  static const _dest = [
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Estoque'),
    (Icons.add_circle_outline, Icons.add_circle, 'Novo'),
    (Icons.local_shipping_outlined, Icons.local_shipping, 'Pedidos'),
    (Icons.qr_code_scanner, Icons.qr_code_scanner, 'Ler'),
  ];

  @override
  Widget build(BuildContext c) {
    final pages = [const Estoque(), const NovoFrasco(), const Pedidos(), const Leitor()];
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(listenable: store, builder: (_, __) => pages[i]),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Paleta.forest.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: Row(children: [
            for (var n = 0; n < _dest.length; n++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => i = n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: i == n ? Paleta.mint : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(i == n ? _dest[n].$2 : _dest[n].$1, color: Paleta.forest, size: 22),
                      const SizedBox(height: 4),
                      Text(_dest[n].$3,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: i == n ? FontWeight.w800 : FontWeight.w600,
                            color: Paleta.forest,
                          )),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

void mostrarEtiqueta(BuildContext c, Frasco f) => showDialog(
    context: c,
    builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: SoftCard(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Frasco ${f.id}', style: Theme.of(c).textTheme.titleLarge),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Paleta.mintSoft, borderRadius: BorderRadius.circular(22)),
                child: BarcodeWidget(barcode: Barcode.qrCode(), data: f.payload, width: 180, height: 180, color: Paleta.ink),
              ),
              const SizedBox(height: 14),
              Text('Doadora ${f.doadora} · ${tipos[f.tipo]} · ${f.ml} mL',
                  textAlign: TextAlign.center, style: Theme.of(c).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Pasteurizado: ${Frasco.br(f.pasteur)}'),
              if (f.cremato != null) Text('Crematócrito: ${f.cremato}'),
              if (f.dornic != null) Text('Dornic: ${f.dornic}'),
              const SizedBox(height: 10),
              ChipStatus(f.status),
              if (f.rn != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('RN ${f.rn}')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar')),
              ),
            ]),
          ),
        ));

class Estoque extends StatelessWidget {
  const Estoque({super.key});
  @override
  Widget build(BuildContext c) {
    final totalMl = store.frascos.where((f) => f.status == 'estoque').fold<int>(0, (s, f) => s + f.ml);
    final nEstoque = store.frascos.where((f) => f.status == 'estoque').length;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), children: [
      const PageHeader('Banco de Leite Humano', 'Estoque'),
      SoftCard(
        color: Paleta.forestMid,
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Em estoque agora', style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('$nEstoque frascos', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
              const SizedBox(height: 4),
              Text('$totalMl mL disponíveis', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFD7F0E6))),
            ]),
          ),
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(color: Paleta.peach, borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 28),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      if (store.frascos.isEmpty)
        SoftCard(
          child: Column(children: [
            const Icon(Icons.inventory_2_outlined, size: 40, color: Paleta.forestMid),
            const SizedBox(height: 10),
            Text('Nenhum frasco cadastrado', style: Theme.of(c).textTheme.titleMedium),
            const Text('Cadastre o primeiro no menu Novo.'),
          ]),
        )
      else
        for (final f in store.frascos.reversed) ...[
          SoftCard(
            onTap: () => mostrarEtiqueta(c, f),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Paleta.mint, borderRadius: BorderRadius.circular(16)),
                child: Text(f.tipo, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: Paleta.forest)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Frasco ${f.id} · ${f.ml} mL', style: Theme.of(c).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('Doadora ${f.doadora} · ${Frasco.br(f.pasteur)}'),
                  const SizedBox(height: 8),
                  ChipStatus(f.status),
                ]),
              ),
              const Icon(Icons.qr_code_2_rounded, color: Paleta.forestMid),
            ]),
          ),
          const SizedBox(height: 12),
        ],
    ]);
  }
}

class NovoFrasco extends StatefulWidget { const NovoFrasco({super.key}); @override State<NovoFrasco> createState() => _NovoState(); }
class _NovoState extends State<NovoFrasco> {
  final doadora = TextEditingController(), ml = TextEditingController(text: '300'),
      cremato = TextEditingController(), dornic = TextEditingController(), temp = TextEditingController();
  String tipo = 'M';
  DateTime coleta = DateTime.now(), pasteur = DateTime.now();

  Future<DateTime?> _pick(DateTime d) => showDatePicker(
      context: context, initialDate: d, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)));

  Widget _data(String label, DateTime d, VoidCallback onTap) => SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: onTap,
        color: Paleta.mintSoft,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label, style: const TextStyle(color: Paleta.muted, fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text(Frasco.br(d), style: const TextStyle(color: Paleta.ink, fontWeight: FontWeight.w800, fontSize: 16)),
          trailing: const Icon(Icons.event, color: Paleta.forestMid),
        ),
      );

  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), children: [
        const PageHeader('Cadastro', 'Novo frasco'),
        SoftCard(
          child: Column(children: [
            TextField(controller: doadora, decoration: _campo('Nº da doadora (anonimizado)', icon: Icons.person_outline)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey('tipo-novo-$tipo'),
              initialValue: tipo,
              decoration: _campo('Classificação do leite', icon: Icons.science_outlined),
              items: [for (final e in tipos.entries) DropdownMenuItem(value: e.key, child: Text('${e.key} — ${e.value}'))],
              onChanged: (v) => setState(() => tipo = v!),
            ),
            const SizedBox(height: 12),
            TextField(controller: ml, keyboardType: TextInputType.number, decoration: _campo('Volume pasteurizado (mL)', icon: Icons.opacity)),
            const SizedBox(height: 12),
            _data('Data da 1ª coleta', coleta, () async { final d = await _pick(coleta); if (d != null) setState(() => coleta = d); }),
            const SizedBox(height: 12),
            _data('Data da pasteurização', pasteur, () async { final d = await _pick(pasteur); if (d != null) setState(() => pasteur = d); }),
            const SizedBox(height: 12),
            TextField(controller: cremato, keyboardType: TextInputType.number, decoration: _campo('Crematócrito')),
            const SizedBox(height: 12),
            TextField(controller: dornic, keyboardType: TextInputType.number, decoration: _campo('Acidez Dornic')),
            const SizedBox(height: 12),
            TextField(controller: temp, keyboardType: TextInputType.number, decoration: _campo('Temperatura (°C)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Salvar e gerar código'),
                onPressed: () async {
                  if (doadora.text.trim().isEmpty || int.tryParse(ml.text) == null) return;
                  final f = Frasco('${store.nextId()}', doadora.text.trim(), tipo, int.parse(ml.text), coleta, pasteur,
                      cremato: double.tryParse(cremato.text.replaceAll(',', '.')),
                      dornic: double.tryParse(dornic.text.replaceAll(',', '.')),
                      temp: double.tryParse(temp.text.replaceAll(',', '.')));
                  await store.add(f);
                  if (c.mounted) mostrarEtiqueta(c, f);
                },
              ),
            ),
          ]),
        ),
      ]);
}

class Pedidos extends StatefulWidget { const Pedidos({super.key}); @override State<Pedidos> createState() => _PedState(); }
class _PedState extends State<Pedidos> {
  final rn = TextEditingController(), vol = TextEditingController(),
      temp = TextEditingController(), resp = TextEditingController();
  String tipo = 'M';
  List<Frasco> sugestao = [];

  @override
  Widget build(BuildContext c) {
    final reservados = store.frascos.where((f) => f.status == 'reservado').toList();
    final volRes = reservados.fold<int>(0, (s, f) => s + f.ml);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), children: [
      const PageHeader('Expedição', 'Pedidos'),
      SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Novo pedido (prescrição)', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 14),
          TextField(controller: rn, decoration: _campo('Nome do RN receptor', icon: Icons.child_care_outlined)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: vol, keyboardType: TextInputType.number, decoration: _campo('Volume (mL)'))),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('tipo-ped-$tipo'),
                initialValue: tipo,
                decoration: _campo('Tipo'),
                items: [for (final e in tipos.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => tipo = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          FilledButton(
            style: _pillSoft,
            onPressed: () {
              final v = int.tryParse(vol.text);
              if (v == null) return;
              setState(() => sugestao = store.sugerir(tipo, v));
              if (sugestao.isEmpty) {
                ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Estoque insuficiente para esse tipo/volume.')));
              }
            },
            child: const Text('Buscar leite correspondente'),
          ),
          for (final f in sugestao) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Paleta.mintSoft, borderRadius: BorderRadius.circular(18)),
              child: Text('Frasco ${f.id} · ${f.ml} mL · Doadora ${f.doadora}\n${Frasco.br(f.pasteur)}',
                  style: const TextStyle(color: Paleta.ink, fontWeight: FontWeight.w600, height: 1.35)),
            ),
          ],
          if (sugestao.isNotEmpty) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                for (final f in sugestao) { f.status = 'reservado'; f.rn = rn.text.trim(); }
                setState(() => sugestao = []);
                await store.save();
              },
              child: Text('Reservar (${sugestao.fold<int>(0, (s, f) => s + f.ml)} mL)'),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Expedição de quinta-feira', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${reservados.length} frasco(s) · $volRes mL', style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (final f in reservados) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Paleta.mintSoft, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Expanded(child: Text('Frasco ${f.id} → ${f.rn}\n${f.ml} mL · ${tipos[f.tipo]}',
                    style: const TextStyle(color: Paleta.ink, fontWeight: FontWeight.w600, height: 1.35))),
                const ChipStatus('reservado'),
              ]),
            ),
          ],
          TextField(controller: temp, keyboardType: TextInputType.number, decoration: _campo('Temperatura da caixa (°C)')),
          const SizedBox(height: 12),
          TextField(controller: resp, decoration: _campo('Responsável (assinatura)', icon: Icons.draw_outlined)),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.local_shipping),
            label: const Text('Confirmar envio'),
            onPressed: reservados.isEmpty || temp.text.isEmpty || resp.text.isEmpty ? null : () async {
              final t = double.tryParse(temp.text.replaceAll(',', '.'));
              for (final f in reservados) { f.status = 'enviado'; f.temp = t; }
              await store.save();
              temp.clear(); resp.clear();
              setState(() {});
            },
          ),
        ]),
      ),
    ]);
  }
}

class Leitor extends StatelessWidget {
  const Leitor({super.key});
  @override
  Widget build(BuildContext c) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PageHeader('Identificação', 'Ler código'),
          Expanded(
            child: SoftCard(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(onDetect: (cap) {
                  final raw = cap.barcodes.first.rawValue;
                  if (raw == null) return;
                  try {
                    final id = jsonDecode(raw)['f'];
                    final f = store.frascos.firstWhere((x) => x.id == id);
                    mostrarEtiqueta(c, f);
                  } catch (_) {
                    ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Código não reconhecido.')));
                  }
                }),
              ),
            ),
          ),
        ]),
      );
}
