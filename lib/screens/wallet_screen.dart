import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _gold = Color(0xFFD4AF37);
const Color _bg = Color(0xFF0B0B0B);
const Color _card = Color(0xFF161616);
const double _minSaque = 10.0;

InputDecoration _dec(String label) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0x55D4AF37)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: _gold),
      ),
    );

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

  SupabaseClient get _supa => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    load();
  }

  double _num(dynamic v) => (num.tryParse(v.toString()) ?? 0).toDouble();

  String _brl(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Conta anonima nao tem e-mail confirmado.
  bool get _semEmail {
    final u = _supa.auth.currentUser;
    if (u == null) return true;
    final email = u.email;
    return email == null || email.isEmpty;
  }

  Future<void> load() async {
    try {
      final uid = _supa.auth.currentUser?.id;
      if (uid != null) {
        final res = await _supa
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
    } catch (_) {}
    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _vincularEmail() async {
    final emailC = TextEditingController();
    final senhaC = TextEditingController();
    bool enviando = false;
    bool enviado = false;
    String? erro;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          backgroundColor: _card,
          title: Text('Vincule seu e-mail', style: TextStyle(color: _gold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  enviado
                      ? 'Enviamos um link de confirmacao para ${emailC.text.trim()}. Abra o e-mail, confirme e volte aqui.'
                      : 'Para sacar, vincule um e-mail e crie uma senha. Assim voce nao perde seu saldo se trocar de celular.',
                  style: TextStyle(color: Colors.white70),
                ),
                if (!enviado) ...[
                  SizedBox(height: 12),
                  TextField(
                    controller: emailC,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white),
                    decoration: _dec('E-mail'),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: senhaC,
                    obscureText: true,
                    style: TextStyle(color: Colors.white),
                    decoration: _dec('Senha (minimo 6 caracteres)'),
                  ),
                ],
                if (erro != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(erro ?? '',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Fechar', style: TextStyle(color: Colors.grey)),
            ),
            if (!enviado)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                onPressed: enviando
                    ? null
                    : () async {
                        final e = emailC.text.trim();
                        final s = senhaC.text;
                        if (!e.contains('@') || !e.contains('.')) {
                          setD(() => erro = 'Digite um e-mail valido.');
                          return;
                        }
                        if (s.length < 6) {
                          setD(() => erro = 'A senha precisa ter 6 ou mais caracteres.');
                          return;
                        }
                        setD(() {
                          enviando = true;
                          erro = null;
                        });
                        try {
                          await _supa.auth.updateUser(
                            UserAttributes(email: e, password: s),
                          );
                          setD(() {
                            enviando = false;
                            enviado = true;
                          });
                        } on AuthException catch (ex) {
                          setD(() {
                            enviando = false;
                            erro = ex.message;
                          });
                        } catch (_) {
                          setD(() {
                            enviando = false;
                            erro = 'Nao foi possivel enviar. Tente de novo.';
                          });
                        }
                      },
                child: Text('ENVIAR LINK',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                onPressed: () async {
                  try {
                    await _supa.auth.refreshSession();
                  } catch (_) {}
                  if (!_semEmail) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    _snack('E-mail confirmado! Toque em SACAR.');
                  } else {
                    setD(() => erro =
                        'Ainda nao confirmado. Abra o link no e-mail e tente de novo.');
                  }
                },
                child: Text('JA CONFIRMEI',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
          ],
        );
      }),
    );
  }

  Future<void> _sacar() async {
    if (saldo < _minSaque) {
      _snack('Saldo minimo para saque: ${_brl(_minSaque)}');
      return;
    }
    if (_semEmail) {
      await _vincularEmail();
      return;
    }
    try {
      await _supa.auth.refreshSession();
    } catch (_) {}
    final valorC = TextEditingController(
        text: saldo.toStringAsFixed(2).replaceAll('.', ','));
    final pixC = TextEditingController();
    bool enviando = false;
    String? erro;
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          backgroundColor: _card,
          title: Text('Sacar via Pix', style: TextStyle(color: _gold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Saldo: ${_brl(saldo)}',
                    style: TextStyle(color: Colors.white70)),
                SizedBox(height: 8),
                TextField(
                  controller: valorC,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: Colors.white),
                  decoration: _dec('Valor (R\$)'),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: pixC,
                  style: TextStyle(color: Colors.white),
                  decoration: _dec('Chave Pix (CPF, e-mail, telefone...)'),
                ),
                SizedBox(height: 10),
                Text(
                  'Confira a chave com atencao: o Pix nao pode ser desfeito.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (erro != null)
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(erro ?? '',
                        style: TextStyle(color: Colors.redAccent)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              onPressed: enviando
                  ? null
                  : () async {
                      final valor = double.tryParse(
                              valorC.text.trim().replaceAll(',', '.')) ??
                          0;
                      final chave = pixC.text.trim();
                      if (valor < _minSaque) {
                        setD(() =>
                            erro = 'O valor minimo e ${_brl(_minSaque)}.');
                        return;
                      }
                      if (valor > saldo) {
                        setD(() => erro = 'Valor maior que o seu saldo.');
                        return;
                      }
                      if (chave.length < 5) {
                        setD(() => erro = 'Informe uma chave Pix valida.');
                        return;
                      }
                      setD(() {
                        enviando = true;
                        erro = null;
                      });
                      try {
                        await _supa.rpc('request_withdrawal', params: {
                          'p_valor': valor,
                          'p_chave_pix': chave,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        _snack('Pedido enviado! Acompanhe no Historico.');
                        await load();
                      } on PostgrestException catch (ex) {
                        setD(() {
                          enviando = false;
                          erro = ex.message;
                        });
                      } catch (_) {
                        setD(() {
                          enviando = false;
                          erro = 'Nao foi possivel enviar. Tente de novo.';
                        });
                      }
                    },
              child: Text('PEDIR SAQUE',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        );
      }),
    );
  }

  Widget _linha(String label, double valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text(_brl(valor),
              style: TextStyle(
                  color: _gold, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
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
          'MINHA CARTEIRA',
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
              child: ListView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                children: [
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _gold, width: 1),
                    ),
                    child: Column(
                      children: [
                        Text('SALDO DISPONIVEL',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 2)),
                        SizedBox(height: 12),
                        Text(
                          _brl(saldo),
                          style: TextStyle(
                            color: _gold,
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 16),
                        Divider(color: Color(0x55D4AF37)),
                        _linha('Total ganho', totalGanho),
                        _linha('Total sacado', totalSacado),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: _sacar,
                      child: Text('SACAR VIA PIX',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Saque minimo: ${_brl(_minSaque)}',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
