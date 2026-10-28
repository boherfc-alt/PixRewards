
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
class OffersScreen extends StatefulWidget { const OffersScreen({super.key}); @override State<OffersScreen> createState()=> _OffersScreenState(); }
class _OffersScreenState extends State<OffersScreen> {
  List offers=[]; bool loading=true;
  @override void initState(){ super.initState(); load(); }
  Future<void> load() async { try{ final res=await Supabase.instance.client.from('offers').select().eq('ativa',true).order('payout_total',ascending:false); setState(()=> offers=res); }catch(e){ setState(()=> offers=[{'id':'1','nome':'VPN Turbo','descricao':'Navegue seguro','payout_total':8.5,'reward_user':1.0,'profit_owner':7.5,'link_afiliado':'https://play.google.com/store'}]); } setState(()=> loading=false); }
  Future<void> pegar(oferta) async { final supa=Supabase.instance.client; var user=supa.auth.currentUser; if(user==null){ await supa.auth.signUp(email: 'user\${DateTime.now().millisecondsSinceEpoch}@pixrewards.com', password: 'pixrewards123'); user=supa.auth.currentUser; if(user==null) return; } try{ await supa.from('installs').insert({'user_id':user.id,'offer_id':oferta['id'],'status':'clicou'}); }catch(_){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voce ja pegou essa oferta!'))); return; } await launchUrl(Uri.parse(oferta['link_afiliado']), mode: LaunchMode.externalApplication); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E1A),
      appBar: AppBar(
        title: Text('PixRewards - Ganhe R\$1'),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: offers.length,
              itemBuilder: (_, i) {
                final o = offers[i];
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(0xFF00E676).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.phone_android, color: Color(0xFF00E676)),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o['nome'].toString(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "GANHE R\$ ${o['reward_user']} - Lucro R\$ ${o['profit_owner']}",
                            style: TextStyle(color: Colors.greenAccent, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00E676),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => pegar(o),
                      child: Text('PEGAR'),
                    ),
                  ]),
                );
              },
            ),
    );
  }
}
