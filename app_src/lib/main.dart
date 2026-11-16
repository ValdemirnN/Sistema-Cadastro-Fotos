import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

final db = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(MaterialApp(
    title: 'Cadastro de Fotos',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF1F3A5F), useMaterial3: true),
    home: db.auth.currentSession == null ? const LoginPage() : const ListaPage(),
  ));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;

  Future<void> entrar() async {
    setState(() => carregando = true);
    try {
      await db.auth.signInWithPassword(email: email.text.trim(), password: senha.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ListaPage()));
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Cadastro de Fotos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
            TextField(controller: senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: carregando ? null : entrar, child: Text(carregando ? 'Entrando...' : 'Entrar')),
          ]),
        ),
      );
}

class ListaPage extends StatefulWidget {
  const ListaPage({super.key});
  @override
  State<ListaPage> createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  List<Map<String, dynamic>> itens = [];
  String busca = '';
  String filtro = 'todos'; // todos | sem | com
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => carregando = true);
    try {
      var q = db.from('pessoas').select();
      if (busca.isNotEmpty) {
        final b = busca.replaceAll(',', ' ');
        q = q.or('nome.ilike.%$b%,matricula.ilike.%$b%');
      }
      if (filtro == 'sem') q = q.isFilter('foto_path', null);
      if (filtro == 'com') q = q.not('foto_path', 'is', null);
      final r = await q.order('nome').limit(1000);
      setState(() => itens = List<Map<String, dynamic>>.from(r));
    } catch (e) {
      _msg('Erro ao carregar: $e');
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  void _msg(String t) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<void> tirarFoto(Map<String, dynamic> p) async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      imageQuality: 85,
    );
    if (x == null) return;
    try {
      // reduz para ~400px e JPEG qualidade 70 (≈ 30-60 KB)
      final bytes = await FlutterImageCompress.compressWithFile(
        x.path,
        minWidth: 400,
        minHeight: 400,
        quality: 70,
        format: CompressFormat.jpeg,
      );
      if (bytes == null) throw 'Falha ao comprimir a imagem';
      final path = '${p['matricula']}.jpg';
      await db.storage.from('fotos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      await db.from('pessoas').update({
        'foto_path': path,
        'foto_em': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', p['id']);
      _msg('Foto salva (${(bytes.length / 1024).round()} KB)');
      carregar();
    } catch (e) {
      _msg('Erro ao enviar foto: $e');
    }
  }

  Future<void> verFoto(Map<String, dynamic> p) async {
    if (p['foto_path'] == null) return;
    try {
      final bytes = await db.storage.from('fotos').download(p['foto_path']);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(p['nome']),
          content: Image.memory(bytes),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                tirarFoto(p);
              },
              child: const Text('Tirar outra'),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
          ],
        ),
      );
    } catch (e) {
      _msg('Erro ao abrir foto: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: TextField(
            decoration: const InputDecoration(hintText: 'Buscar nome ou matrícula', border: InputBorder.none),
            onChanged: (v) {
              busca = v.trim();
              carregar();
            },
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (v) {
                filtro = v;
                carregar();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'todos', child: Text('Todos')),
                PopupMenuItem(value: 'sem', child: Text('Sem foto')),
                PopupMenuItem(value: 'com', child: Text('Com foto')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await db.auth.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
            ),
          ],
        ),
        body: carregando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: carregar,
                child: ListView.builder(
                  itemCount: itens.length,
                  itemBuilder: (_, i) {
                    final p = itens[i];
                    final tem = p['foto_path'] != null;
                    return ListTile(
                      title: Text(p['nome']),
                      subtitle: Text('${p['matricula']} • ${p['local_trabalho'] ?? ''}'),
                      trailing: Icon(tem ? Icons.check_circle : Icons.photo_camera,
                          color: tem ? Colors.green : null),
                      onTap: () => tirarFoto(p),
                      onLongPress: () => verFoto(p),
                    );
                  },
                ),
              ),
      );
}
