import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
          .order('payout_total', ascending: false);
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

  Future<void> pegar(oferta) async {
    final supa = Supabase.instance.client;
    var user = supa.auth.currentUser;
    if (user ==
