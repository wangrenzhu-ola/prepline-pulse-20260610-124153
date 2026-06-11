import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProtocolScreen extends StatefulWidget {
  const ProtocolScreen({super.key});

  static const routeName = '/protocol';
  static const userAgreementUrl =
      'https://qavix.teltaj.com/ServiceAgreement.html';
  static const privacyPolicyUrl =
      'https://qavix.teltaj.com/privacy-summary.html';

  static String urlForTitle(String title) {
    return title.toLowerCase().contains('privacy')
        ? privacyPolicyUrl
        : userAgreementUrl;
  }

  @override
  State<ProtocolScreen> createState() => _ProtocolScreenState();
}

class _ProtocolScreenState extends State<ProtocolScreen> {
  late final WebViewController _webViewController;
  var _retryCount = 0;
  var _loading = true;
  var _requestLoaded = false;
  var _currentUrl = ProtocolScreen.userAgreementUrl;

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
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestLoaded) {
      return;
    }
    final title = _documentTitle(context);
    _currentUrl = ProtocolScreen.urlForTitle(title);
    _requestLoaded = true;
    _webViewController.loadRequest(Uri.parse(_currentUrl));
  }

  @override
  Widget build(BuildContext context) {
    final title = _documentTitle(context);
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
      _webViewController.loadRequest(Uri.parse(_currentUrl));
    });
  }

  String _documentTitle(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as String? ??
        'Policy document';
  }
}
