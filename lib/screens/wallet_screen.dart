import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offers_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double saldo = 0;
  double totalGanho = 0;
  double totalSacado = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  double _num(dynamic v) => (num.tryParse(v.toString()) ?? 0).toDouble();

  String reais(double v) => "R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}";

  Future<void> load() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid != null) {
        final res = await Supabase.instance.client
            .from('wallets')
            .select()
            .eq('user_id', uid)
            .maybeSingle();
        if (res != null) {
          saldo = _num(res['saldo']);
          totalGanho = _num(res['total_ganho']);
          totalSacado = _num(res['total_sacado']);
        }
      }
    } catch (e) {}
    if (!mounted) return;
    setState(() => loading = false);
  }

  Widget linha(String titulo, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titulo, style: TextStyle(color: Colors.white70)),
        Text(
          valor,
          style: TextStyle(color: kGoldLight, fontWeight: FontWeight.w600),
        ),
      ],
    );
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
          'MINHA CARTEIRA',
          style: TextStyle(
            color: kGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: kGold))
          : Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kGold, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SALDO DISPONÍVEL',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        reais(saldo),
                        style: TextStyle(
                          color: kGold,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(color: Color(0x55D4AF37)),
                      SizedBox(height: 12),
                      linha('Total ganho', reais(totalGanho)),
                      SizedBox(height: 8),
                      linha('Total sacado', reais(totalSacado)),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
