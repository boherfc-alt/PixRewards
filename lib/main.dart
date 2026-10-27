
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/offers_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/history_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: 'https://pmnghuepbxxktuiqivkl.supabase.co', anonKey: 'sb_publishable_d3MKEPnK6clbjNCsHFNpmg_0nvbgovD');
  runApp(const PixRewardsApp());
}
class PixRewardsApp extends StatelessWidget { const PixRewardsApp({super.key}); @override Widget build(BuildContext context){ return MaterialApp(title: 'PixRewards', debugShowCheckedModeBanner: false, theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Color(0xFF0A0E1A)), home: const MainTabs()); } }
class MainTabs extends StatefulWidget { const MainTabs({super.key}); @override State<MainTabs> createState()=> _MainTabsState(); }
class _MainTabsState extends State<MainTabs> { int idx=0; final screens=const [OffersScreen(), WalletScreen(), HistoryScreen()]; @override Widget build(BuildContext context){ return Scaffold(body: screens[idx], bottomNavigationBar: BottomNavigationBar(backgroundColor: Colors.black, selectedItemColor: Color(0xFF00E676), unselectedItemColor: Colors.grey, currentIndex: idx, onTap: (i)=> setState(()=> idx=i), items: const [BottomNavigationBarItem(icon: Icon(Icons.bolt), label: 'Ganhar Pix'), BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Carteira'), BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico')])); } }
