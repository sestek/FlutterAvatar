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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mikrofon Testi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Ana Sayfa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Seçenekleri',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(
                    context,
                    'Genel Test',
                    Icons.settings,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WebViewPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

    // İzin durumlarını kontrol et ve kullanıcıya bildir
    if (microphoneStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mikrofon izni gerekli! Lütfen ayarlardan izin verin.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } else if (microphoneStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mikrofon izni verildi!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    if (cameraStatus.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera izni gerekli! Lütfen ayarlardan izin verin.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }

    // İzin durumlarını debug için yazdır
    debugPrint('Mikrofon izni: $microphoneStatus');
    debugPrint('Kamera izni: $cameraStatus');
    debugPrint('Depolama izni: $storageStatus');
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
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView yükleniyor (progress : $progress%)');
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // Sayfa yüklendiğinde mikrofon izni için JavaScript kodu çalıştır
            _injectMicrophonePermissionScript();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView hatası: ${error.description}');
          },
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
      ..addJavaScriptChannel(
        'permissionHandler',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint("İzin durumu: ${message.message}");
          if (message.message.contains('microphone_denied')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mikrofon izni reddedildi. Lütfen ayarlardan izin verin.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (message.message.contains('microphone_granted')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mikrofon izni verildi!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
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

  void _injectMicrophonePermissionScript() {
    const String script = '''
      // Mikrofon izni için gelişmiş script
      async function requestMicrophonePermission() {
        try {
          if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
            console.log('Mikrofon izni isteniyor...');
            const stream = await navigator.mediaDevices.getUserMedia({ 
              audio: {
                echoCancellation: true,
                noiseSuppression: true,
                autoGainControl: true
              }, 
              video: false 
            });
            console.log('Mikrofon erişimi başarılı');
            window.permissionHandler.postMessage('microphone_granted');
            return stream;
          } else {
            console.log('getUserMedia desteklenmiyor');
            window.permissionHandler.postMessage('microphone_not_supported');
          }
        } catch (err) {
          console.log('Mikrofon erişimi hatası:', err);
          window.permissionHandler.postMessage('microphone_denied: ' + err.message);
        }
      }
      
      // Sayfa yüklendiğinde mikrofon izni iste
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', requestMicrophonePermission);
      } else {
        requestMicrophonePermission();
      }
    ''';
    
    _controller.runJavaScript(script);
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
