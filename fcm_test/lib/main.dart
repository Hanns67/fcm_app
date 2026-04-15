import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'dart:convert';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:fcm_test/services/sound_services.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Message background: ${message.messageId}');

}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}


// ─────────────────────────────────────────────────────────────
// SERVICE FCM
// ─────────────────────────────────────────────────────────────
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //base de donnees firestorage ou sont stockes les instances
  static const String _collection = 'tokensInstances';

//informations de securite,pour autoriser l'acces a l'administration de firebase
  static const String _projectId   = 'kallioapp';
  static const String _clientEmail = 'firebase-adminsdk-fbsvc@kallioapp.iam.gserviceaccount.com';
  static const String _privateKey  = "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDsldtE+ANkuKmw\nysrlOvznlYfr7MOIXN5AG81instkIUcrKDFZ6bdIkv5dKPwlRmjyXxL93x2MVvPW\nfsxx2KGsj0IsV/++w0TORMDC9eD7mVILgPzXeo/87baw77++O9bjPIhPk+sQepVb\n1hbtlyX9klokBkAzbJUaBPfdyQDuQl6CuTeDr+Hg0IgtKGpBGbzYYB+mk6KLkC+3\nL13q3dqxPCCwpJDkyQ6DfpNt4wVEfAbzqBA3jqMTPlDYkoc27UlB5907L5JE8SpC\nREN0wasPHafwVaUR8K91q/4v8fahXcgmcipIOBGjbMZztpIAOdQx46sXyl45KevW\nZ1vXouIvAgMBAAECggEAI0Cb0PBju7kIZUonvCBzWXlJLOO1VGGs0ZX9n0RUv4bL\nOVMJMiybyDn0TPgJGkTI6SnhhT1Jry+wWwsUdkz2n4/OfG0LCTxvdDd/wY0sXlEU\n40HvwEEy/gKDG7pIXUBCtM7AQPCkMMBooQE1nrwhnQxsV2csXyfpelxjKAOwxSTf\n4UtDIhSK8bD1hDs4X+HzoQ5lZDD7sSV9Tr6ZYBlF4euvEbQxDity+VxPVf8GQFcU\n8CQy5HvG3ZLCPJeV3v82ccQrnkvhMQ5xCvn4qUvOTYxvcg1jXVtpAKFcBfnL2aZp\n5qFQQRQABDxccYexxl2ZWn54qMvSUlXkRTNGExkkAQKBgQD55xsU3UGLuj235Pf6\n0zvf2idNCvYvCvH2tGrSKSwcVtafqajQO/2EhGobnWZRbkGsrLKpdEUfvxA6+wNU\nY/O1Eh8DcyZ1wmtU+nLJPOCSzMi95SZqFaSh06C1ReDLfr6bU6p6brpqK+ngzgk2\nCXaSsmjI77gepM1PjpXS3+ihjwKBgQDyW5H+yZpQ9DU6i2uqa1viOiYyu3clJovy\nkr51+s8WbByigunItOkmUpFftLUBlxoOlo2UZPKH1l/dQffa2SIfRrcpsMUJBCPo\nd8P1un0RcU6zjkYEmIB063RfgwLcDMBbmU1PCQ5VUds97N++3Q2k+TFl82I110Hf\nYVi4MpwlYQKBgGQnC8Jz3eX60OtXN07twyw2iNOmlf1KfKhrq/foCkadQsygOQij\nUjn+u2uvzCbMckOavsuMznsnnoCUwsPafvxNc+J1Dq/ZKBzZdpFR9Yq/yZ/ZK2kO\nnXlBkEG17J6BgDBN+p+wqsMMMGIpEKX4au3l1HrbH8YgNCwzL7ZgiCHfAoGATsdz\nOoXf0oa/MquVMM07DdtnBUCopvvTq+MFZCZF4Hz+BdlWEvazftCCDsEXwU+TmcBY\nfy8dIwiNGsfRwGKqU85RxYx/T8H3xh4AJcUb2GqjcXxCyEWmI9tRdaaJbGv8rwmy\n9oj0DsnP4V45ELqcL88Mvp4Rg3zYHbtv8lgJJ6ECgYEA3TlfdL9bFgHFJK6xJqIH\n3k6xhJebQ+LIY47YQEP4nnACSSvMSMlJwIiuS04wacfgYX2muEc91QULkCwmGgX8\n55UTu91K6n07nkzteOvtPOfd9qdT/LOPeunwZ5t9AaOsXnPTjNlSH3FpwkP7biYs\noD6vBMVaL64s4+6Y9ZwmEfQ=\n-----END PRIVATE KEY-----\n";

//Recuperation du token de l'instance
  static String get _fcmUrl =>
      'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send';

  static Future<String?> initAndRegister() async {
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;

    final token = await _messaging.getToken();
    if (token == null) return null;

    await _saveToken(token);
    _messaging.onTokenRefresh.listen(_saveToken);

    return token;
  }

  //enregistrement du token de l'instance dans firestore

  static Future<void> _saveToken(String token) async {
    await _firestore.collection(_collection).doc(token).set({
      'token':     token,
      'platform':  _platform,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('✅ Token Firestore enregistré');
  }

  static String get _platform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS:     return 'ios';
      default:                     return 'other';
    }
  }

//recuperation des tokens des instances deja disponibles.
  static Stream<List<InstanceToken>> watchOtherTokens(String myToken) {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .where((doc) => doc.id != myToken)
            .map((doc) => InstanceToken.fromFirestore(doc))
            .toList());
  }

//Obtention d'un jeton jwt,pour avoir l'acces FCM
  static Future<String> _getAccessToken() async {
    final now = DateTime.now();

    final jwt = JWT({
      'iss':   _clientEmail,
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud':   'https://oauth2.googleapis.com/token',
      'iat':   now.millisecondsSinceEpoch ~/ 1000,
      'exp':   (now.millisecondsSinceEpoch ~/ 1000) + 3600,
    });

    final signedJwt = jwt.sign(
      RSAPrivateKey(_privateKey),
      algorithm: JWTAlgorithm.RS256,
    );

    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion':  signedJwt,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur OAuth2: ${response.body}');
    }

    return jsonDecode(response.body)['access_token'] as String;
  }

  //methode d'envoie de la notification a une instance cible,
  //avec le token de celle ci,le titre et le corps de la notification,ainsi que des donnees supplementaires optionnelles

  static Future<NotificationResult> sendNotification({
    required String targetToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': targetToken,
            'notification': {'title': title, 'body': body},
            'data': data ?? {'action': 'open_app'},
            'android': {
              'priority': 'high',
              'notification': {
                // Son système Android joué quand l'app est en background/fermée
                'sound': 'receive',         // → res/raw/receive.mp3 dans le projet Android
                'default_sound': false,
              },
            },
            'apns': {
              'payload': {
                'aps': {
                  // Son iOS joué quand l'app est en background/fermée
                  'sound': 'receive.mp3',   // → à placer dans Runner/Resources/ sur iOS
                  'badge': 1,
                },
              },
            },
          },
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return NotificationResult.success();
      }

      final errMsg = jsonDecode(response.body)['error']?['message'] ?? 'Erreur inconnue';
      return NotificationResult.failure(errMsg);
    } catch (e) {
      return NotificationResult.failure(e.toString());
    }
  }
}

// ─────────────────────────────────────────────────────────────
// MODÈLES
// ─────────────────────────────────────────────────────────────
//structure de donnees representant une instance en fonction des donnees stockees dans firestore
class InstanceToken {
  final String token;
  final DateTime? createdAt;
  final String? platform;

  InstanceToken({required this.token, this.createdAt, this.platform});

  factory InstanceToken.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return InstanceToken(
      token:     d['token'] ?? doc.id,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      platform:  d['platform'],
    );
  }

  String get shortToken => token.length > 20
      ? '${token.substring(0, 10)}...${token.substring(token.length - 8)}'
      : token;
}
/*strtucture de donnees representant le resultat de l'envoie d'une notification,avec un indicateur de succes et 
un message d'erreur eventuel*/
class NotificationResult {
  final bool success;
  final String? error;
  NotificationResult.success() : success = true, error = null;
  NotificationResult.failure(this.error) : success = false;
}

// ─────────────────────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Instances',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE PRINCIPALE
// ─────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _myToken;
  String  _status  = '⏳ Initialisation...';
  bool    _loading = true;

  @override
  void initState() {
    super.initState();
    _init();

    // ── Réception foreground : son + snackbar ──
    FirebaseMessaging.onMessage.listen((msg) async {
      // Jouer le son de réception
      await SoundService.playReceive();
      _snack('📩 ${msg.notification?.title}: ${msg.notification?.body}');
    });

    // ── App ouverte via tap sur notification ──
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('App ouverte depuis notification: ${msg.data}');
    });
  }

  @override
  void dispose() {
    SoundService.dispose();
    super.dispose();
  }

  Future<void> _init() async {

    try {
      final token = await FCMService.initAndRegister();
      setState(() {
        _myToken = token;
        _status  = token != null ? '✅ Enregistré sur Firestore' : '❌ Échec init';
        _loading = false;
      });
    } catch (e) {
      setState(() { _status = '❌ $e'; _loading = false; });
    }
  }

  void _snack(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: ok ? const Color(0xFF1565C0) : Colors.red[700],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        title: const Text('FCM Instances',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1)),
        actions: [
          if (_myToken != null)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white60),
              tooltip: 'Copier mon token',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _myToken!));
                _snack('✅ Token copié');
              },
            ),
        ],
      ),
      body: Column(children: [
        _buildMyInstanceCard(),
        _buildSectionTitle(),
        Expanded(child: _buildInstancesList()),
      ]),
    );
  }

  Widget _buildMyInstanceCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.45)),
        boxShadow: [BoxShadow(
          color: const Color(0xFF1565C0).withOpacity(0.12),
          blurRadius: 18, offset: const Offset(0, 4),
        )],
      ),
      child: Row(children: [
        Container(
          width: 10, height: 10,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: _myToken != null ? Colors.greenAccent : Colors.red,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: (_myToken != null ? Colors.greenAccent : Colors.red).withOpacity(0.6),
              blurRadius: 8,
            )],
          ),
        ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cette instance',
              style: TextStyle(color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(_status,
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
          if (_myToken != null) ...[
            const SizedBox(height: 6),
            Text(
              '${_myToken!.substring(0, 18)}...${_myToken!.substring(_myToken!.length - 10)}',
              style: const TextStyle(
                  color: Colors.white30, fontSize: 10, fontFamily: 'monospace'),
            ),
          ],
        ])),
      ]),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text('AUTRES INSTANCES',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2,
            )),
      ),
    );
  }

  Widget _buildInstancesList() {
    if (_loading || _myToken == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }

    return StreamBuilder<List<InstanceToken>>(
      stream: FCMService.watchOtherTokens(_myToken!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('❌ Erreur: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent)));
        }

        final list = snapshot.data ?? [];

        if (list.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_other, size: 60, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 14),
              Text('Aucune autre instance détectée',
                  style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14)),
              const SizedBox(height: 6),
              Text('Lancez l\'app sur un autre appareil',
                  style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 12)),
            ],
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: list.length,
          itemBuilder: (ctx, i) => _InstanceCard(
            instance: list[i],
            onResult: (r) => _snack(
              r.success ? '✅ Notification envoyée !' : '❌ ${r.error}',
              ok: r.success,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// COMPOSANT CARTE D'INSTANCE
// ─────────────────────────────────────────────────────────────
class _InstanceCard extends StatefulWidget {
  final InstanceToken instance;
  final Function(NotificationResult) onResult;
  const _InstanceCard({required this.instance, required this.onResult});

  @override
  State<_InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<_InstanceCard> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);

    // Son d'envoi joué immédiatement au clic
    await SoundService.playSend();

    final result = await FCMService.sendNotification(
      targetToken: widget.instance.token,
      title: '👋 Notification FCM',
      body: 'Une instance vous contacte !',
      data: {
        'action': 'open_app',
        'ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );

    setState(() => _sending = false);
    widget.onResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            widget.instance.platform == 'android' ? Icons.android
                : widget.instance.platform == 'ios' ? Icons.apple
                : Icons.devices,
            color: const Color(0xFF42A5F5), size: 20,
          ),
        ),
        const SizedBox(width: 14),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Instance ${widget.instance.shortToken}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 3),
          Text(widget.instance.platform ?? 'Plateforme inconnue',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
        ])),

        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              disabledBackgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: _sending
                ? const SizedBox(width: 13, height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38))
                : const Icon(Icons.send_rounded, size: 15),
            label: Text(_sending ? 'Envoi...' : 'Notifier',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}