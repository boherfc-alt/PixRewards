import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offers_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid != null) {
      try {
        final res = await client
            .from('installs')
            .select('id,status,offers(nome,reward_user)')
            .eq('user_id', uid);
        items = res;
      } catch (e) {
        try {
          final res = await client
              .from('installs')
              .select('id,status')
              .eq('user_id', uid);
          items = res;
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() => loading = false);
  }

  String nomeDe(dynamic it) {
    final of = it['offers'];
    if (of is Map && of['nome'] != null) return of['nome'].toString();
    return 'Oferta';
  }

  String statusDe(dynamic it) {
    final s = (it['status'] ?? '').toString();
    if (s == 'clicou') return 'CLICOU';
    return s.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: kGold, width: 1.5)),
        title: Text(
          'HISTÓRICO',
          style: TextStyle(
            color: kGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: kGold))
          : items.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Nenhuma oferta ainda.\nToque em PEGAR na aba Ganhar Pix.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Color(0x55D4AF37), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              nomeDe(it),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0x26D4AF37),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kGold, width: 1),
                            ),
                            child: Text(
                              statusDe(it),
                              style: TextStyle(
                                color: kGold,
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
    );
  }
}
