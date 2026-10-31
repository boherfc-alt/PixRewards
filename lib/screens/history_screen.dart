import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _gold = Color(0xFFD4AF37);
const Color _bg = Color(0xFF0B0B0B);
const Color _card = Color(0xFF161616);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> itens = [];
  bool loading = true;

  SupabaseClient get _supa => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final lista = <Map<String, dynamic>>[];
    final uid = _supa.auth.currentUser?.id;
    if (uid != null) {
      // Ofertas pegas
      try {
        final installs = await _supa
            .from('installs')
            .select('id,offer_id,status,created_at')
            .eq('user_id', uid);
        final offers = await _supa.from('offers').select('id,nome');
        final nomes = <String, String>{
          for (final o in offers) o['id'].toString(): o['nome'].toString(),
        };
        for (final i in installs) {
          lista.add({
            'titulo': nomes[i['offer_id'].toString()] ?? 'Oferta',
            'status': i['status'].toString(),
            'data': DateTime.tryParse(i['created_at'].toString()),
            'saque': false,
          });
        }
      } catch (_) {}
      // Pedidos de saque
      try {
        final saques = await _supa
            .from('withdrawals')
            .select('id,valor,status,created_at')
            .eq('user_id', uid);
        for (final s in saques) {
          final v = (num.tryParse(s['valor'].toString()) ?? 0).toDouble();
          lista.add({
            'titulo':
                'Saque Pix - R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}',
            'status': s['status'].toString(),
            'data': DateTime.tryParse(s['created_at'].toString()),
            'saque': true,
          });
        }
      } catch (_) {}
    }
    lista.sort((a, b) {
      final da = a['data'] as DateTime?;
      final db = b['data'] as DateTime?;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    if (!mounted) return;
    setState(() {
      itens = lista;
      loading = false;
    });
  }

  String _rotulo(String status) {
    switch (status) {
      case 'clicou':
        return 'CLICOU';
      case 'instalou':
        return 'INSTALOU';
      case 'verificado':
        return 'VERIFICADO';
      case 'creditado':
      case 'pago':
        return 'PAGO';
      case 'rejeitado':
        return 'REJEITADO';
      case 'pendente':
        return 'PENDENTE';
      default:
        return status.toUpperCase();
    }
  }

  Color _cor(String rotulo) {
    if (rotulo == 'PAGO') return Color(0xFF00E676);
    if (rotulo == 'REJEITADO') return Colors.redAccent;
    return _gold;
  }

  String _data(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(l.day)}/${dois(l.month)} ${dois(l.hour)}:${dois(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: _gold, width: 1.5)),
        title: Text(
          'HISTORICO',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: _gold))
          : RefreshIndicator(
              color: _gold,
              onRefresh: load,
              child: itens.isEmpty
                  ? ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 120),
                        Center(
                          child: Text('Historico vazio',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(12),
                      itemCount: itens.length,
                      itemBuilder: (_, i) {
                        final it = itens[i];
                        final rotulo = _rotulo(it['status'].toString());
                        final cor = _cor(rotulo);
                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: Color(0x55D4AF37), width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                it['saque'] == true
                                    ? Icons.pix
                                    : Icons.phone_android,
                                color: _gold,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it['titulo'].toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      _data(it['data'] as DateTime?),
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: cor, width: 1),
                                ),
                                child: Text(
                                  rotulo,
                                  style: TextStyle(
                                    color: cor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
