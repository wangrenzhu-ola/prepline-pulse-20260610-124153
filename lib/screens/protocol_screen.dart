import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProtocolScreen extends StatefulWidget {
  const ProtocolScreen({super.key});

  static const routeName = '/protocol';
  static const placeholderUrl = 'https://developer.apple.com/support/terms/';

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends State<ProtocolScreen> {
  late final WebViewController _webViewController;
  var _retryCount = 0;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => _retryLoad(),
        ),
      )
      ..loadRequest(Uri.parse(ProtocolScreen.placeholderUrl));
  }

  @override
  Widget build(BuildContext context) {
    final title = ModalRoute.of(context)?.settings.arguments as String? ??
        'Policy document';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _webViewController),
            if (_loading)
              const Center(
                child: CircularProgressIndicator.adaptive(),
              ),
          ],
        ),
      ),
    );
  }

  void _retryLoad() {
    if (_retryCount >= 2) {
      setState(() => _loading = false);
      return;
    }
    _retryCount += 1;
    Future<void>.delayed(Duration(milliseconds: 300 * _retryCount), () {
      if (!mounted) {
        return;
      }
      _webViewController.loadRequest(Uri.parse(ProtocolScreen.placeholderUrl));
    });
  }
}
