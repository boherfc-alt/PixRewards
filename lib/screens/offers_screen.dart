import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kGold = Color(0xFFD4AF37);
const Color kGoldLight = Color(0xFFF2D675);
const Color kBlack = Color(0xFF0B0B0B);
const Color kCard = Color(0xFF161616);

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List offers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final res = await Supabase.instance.client
          .from('offers')
          .select('id,nome,descricao,reward_user,link_afiliado')
          .eq('ativa', true)
          .order('reward_user', ascending: false);
      if (!mounted) return;
      setState(() => offers = res);
    } catch (e) {
      if (!mounted) return;
      setState(() => offers = [
            {
              'id': '1',
              'nome': 'VPN Turbo',
              'descricao': 'Navegue seguro',
              'reward_user': 1.0,
              'link_afiliado': 'https://play.google.com/store',
            }
          ]);
    }
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<User?> entrar(SupabaseClient supa, List<String> erros) async {
    var user = supa.auth.currentUser;
    if (user != null) return user;

    try {
      await (supa.auth as dynamic).signInAnonymously();
    } catch (e) {
      erros.add('anonimo: $e');
    }
    return supa.auth.currentUser;
  }

  Future<void> pegar(oferta) async {
    final supa = Supabase.instance.client;
    final erros = <String>[];
    final user = await entrar(supa, erros);
    if (user == null) {
      if (!mounted) return;
      final detalhe = erros.join(' | ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 12),
          content: Text(
            detalhe.isEmpty
                ? 'Nao foi possivel entrar. Tente de novo.'
                : 'Erro ao entrar: $detalhe',
          ),
        ),
      );
      return;
    }
    try {
      await supa.from('installs').insert({
        'user_id': user.id,
        'offer_id': oferta['id'],
        'status': 'clicou',
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voce ja pegou essa oferta!')),
      );
      return;
    }
    await launchUrl(
      Uri.parse(oferta['link_afiliado']),
      mode: LaunchMode.externalApplication,
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
          'PIX REWARD',
          style: TextStyle(
            color: kGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: kGold))
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: offers.length,
              itemBuilder: (_, i) {
                final o = offers[i];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Color(0x55D4AF37), width: 1),
                  ),
                  child: Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(0x26D4AF37),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kGold, width: 1),
                      ),
                      child: Icon(Icons.phone_android, color: kGold),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o['nome'].toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "GANHE R\$ ${(num.tryParse(o['reward_user'].toString()) ?? 0).toStringAsFixed(2).replaceAll('.', ',')}",
                            style: TextStyle(
                              color: kGoldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      onPressed: () => pegar(o),
                      child: Text(
                        'PEGAR',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
