import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const InAppWebViewScreen({
    super.key,
    required this.url,
    this.title = 'TaskRoom',
  });

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  late final WebViewController _controller;

  bool _isLoading = true;
  bool _hasError = false;
  int _loadingProgress = 0;
  String _currentUrl = '';
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _initWebView();
  }

  void _initWebView() {
    // Platform-specific creation params
    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080D12))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _currentUrl = url;
            });
          },
          onProgress: (progress) {
            setState(() => _loadingProgress = progress);
          },
          onPageFinished: (url) async {
            setState(() => _isLoading = false);
            final canGoBack = await _controller.canGoBack();
            setState(() => _canGoBack = canGoBack);
          },
          onWebResourceError: (error) {
            // Only show error for main frame failures, not sub-resource errors
            if (error.isForMainFrame ?? true) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            // Allow all navigation within the same domain
            // Block only truly external apps (tel:, mailto:, etc.)
            final uri = Uri.tryParse(request.url);
            if (uri != null &&
                uri.scheme != 'http' &&
                uri.scheme != 'https') {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Android-specific settings
    if (_controller.platform is AndroidWebViewController) {
      final androidController =
      _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }
  }

  Future<bool> _handleBackButton() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false; // Don't pop the route
    }
    return true; // Pop the route (close WebView)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleBackButton();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor:
        isDark ? const Color(0xFF080D12) : const Color(0xFFF0F4F8),
        appBar: _buildAppBar(isDark),
        body: Stack(
          children: [
            // WebView
            if (!_hasError)
              WebViewWidget(controller: _controller)
            else
              _buildErrorState(),

            // Progress bar at top
            if (_isLoading && !_hasError)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress < 100
                      ? _loadingProgress / 100
                      : null,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor:
      isDark ? const Color(0xFF0F1822) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          _canGoBack ? Icons.arrow_back_ios_new_rounded : Icons.close_rounded,
          size: 20,
        ),
        onPressed: () async {
          final shouldPop = await _handleBackButton();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (_currentUrl.isNotEmpty)
            Text(
              _cleanUrl(_currentUrl),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.55),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
        ],
      ),
      actions: [
        // Reload button
        if (_hasError || !_isLoading)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reload',
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
              _controller.reload();
            },
          ),
        // Open in browser
        IconButton(
          icon: const Icon(Icons.open_in_browser_rounded, size: 20),
          tooltip: 'Open in browser',
          onPressed: _openInBrowser,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.color
                  ?.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No connection',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your internet connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _controller.reload();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Strips https:// and trailing slash for cleaner display
  String _cleanUrl(String url) {
    return url
        .replaceFirst(RegExp(r'^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  Future<void> _openInBrowser() async {
    final currentUrl = await _controller.currentUrl();
    final urlToOpen = currentUrl ?? widget.url;
    final uri = Uri.tryParse(urlToOpen);
    if (uri == null) return;
    // Using url_launcher which is already in the project
    // ignore: deprecated_member_use
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }
}