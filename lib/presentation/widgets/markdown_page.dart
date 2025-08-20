import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownPage extends StatefulWidget {
  final String title;
  final String assetPath;
  const MarkdownPage({super.key, required this.title, required this.assetPath});

  @override
  State<MarkdownPage> createState() => _MarkdownPageState();
}

class _MarkdownPageState extends State<MarkdownPage> {
  String _text = '';

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(widget.assetPath).then((v) {
      if (mounted) setState(() => _text = v);
    });
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final sheet = MarkdownStyleSheet(
      h1: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent),
      h2: const TextStyle(
          decoration: TextDecoration.none,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.redAccent),
      p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.white),
      blockquote: const TextStyle(
        fontSize: 16,
        height: 1.6,
        color: Colors.white70,
        decoration: TextDecoration.none,
      ),
      listBullet: const TextStyle(color: Colors.redAccent),
      codeblockPadding: const EdgeInsets.all(12),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.title),
          centerTitle: true,
          backgroundColor: Colors.black,
        ),
        body: _text.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Markdown(
                data: _text,
                styleSheet: sheet,
                selectable: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                onTapLink: (text, href, title) {
                  if (href != null) _openLink(href);
                },
              ),
      ),
    );
  }
}
