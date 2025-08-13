import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mikrofon Testi',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  // final String testUrl = 'https://webcammictest.com/';
  final String testUrl =
      'https://demo-app.sestek.com/iframeloader/sestekloader.html';

  @override
  void initState() {
    super.initState();

    // Android için izinleri kontrol et
    if (Platform.isAndroid) {
      _checkAndRequestPermissions();
    }

    _initializeWebView();
  }

  Future<void> _checkAndRequestPermissions() async {
    // Mikrofon izni
    var microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus.isDenied) {
      microphoneStatus = await Permission.microphone.request();
    }

    // Kamera izni
    var cameraStatus = await Permission.camera.status;
    if (cameraStatus.isDenied) {
      cameraStatus = await Permission.camera.request();
    }

    // Depolama izinleri
    var storageStatus = await Permission.storage.status;
    if (storageStatus.isDenied) {
      storageStatus = await Permission.storage.request();
    }

    if (microphoneStatus.isDenied || cameraStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mikrofon ve kamera izinleri gerekli!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView yükleniyor (progress : $progress%)');
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..addJavaScriptChannel(
        'handleRedirect',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("Webview'den gelen mesaj: ${message.message}");
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message.message)));
        },
      )
      ..loadFlutterAsset('assets/index.html');

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the WebViewPage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('Mikrofon Testi'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
