import 'package:liveness_azure_flutter/liveness_azure_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // You will need use another plugin, in this case is [permission_handler](https://pub.dev/packages/permission_handler), to get camera permission.
  Future<PermissionStatus> requestCameraPermission() async {
    return Permission.camera.request();
  }

  Future initLiveness() async {
    if (await requestCameraPermission() == PermissionStatus.granted) {
      // It is not recommended to use this method in a real project, the session token must be obtained from the client backend.
      final session = await LivenessAzureFlutter.createSession(
          faceApiEndpoint: 'faceApiEndpoint', apiKey: 'apikey1234');

      if (session != null) {
        try {
          final liveness = await LivenessAzureFlutter.initLiveness(
              authTokenSession: session.authSession,

              // You can customize texts feedback or leave default (exists too LivenessTheme.pt() to portuguese)
              theme: const LivenessTheme(
                  feedbackNone: 'Hold Still.',
                  feedbackLookAtCamera: 'Look at camera.',
                  feedbackFaceNotCentered: 'Center your face in the circle.',
                  feedbackMoveCloser: 'Too far away! Move in closer.',
                  feedbackContinueToMoveCloser: 'Continue to move closer.',
                  feedbackMoveBack: 'Too close! Move farther away.',
                  feedbackReduceMovement: 'Too much movement.',
                  feedbackSmile: 'Smile for the camera!',
                  feedbackAttentionNotNeeded: 'Done, finishing up...'));

          print('liveness result: ${liveness?.resultId}');
        } catch (msg, stacktrace) {
          // error

        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(title: const Text('Plugin example app')),
            body: Center(
                child: FutureBuilder(
                    future: requestCameraPermission(),
                    builder: (c, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const CircularProgressIndicator();
                      }

                      return TextButton(
                          onPressed: initLiveness,
                          child: const Text("Init Liveness"));
                    }))));
  }
}
