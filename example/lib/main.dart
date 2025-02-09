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

      try {
        final liveness = await LivenessAzureFlutter.initLiveness(
            authTokenSession:
'eyJhbGciOiJFUzI1NiIsImtpZCI6ImtleTEiLCJ0eXAiOiJKV1QifQ.eyJyZWdpb24iOiJxYXRhcmNlbnRyYWwiLCJzdWJzY3JpcHRpb24taWQiOiIxZmZiZDczYmM3MDQ0OTNkYjgxMmI1MDMyYzBhYTU0OSIsInByb2R1Y3QtaWQiOiJGYWNlLlMwIiwiYWxsb3dlZC1wYXRocyI6Ilt7XCJwYXRoXCI6XCJmYWNlL3YxLjItcHJldmlldy4xL3Nlc3Npb24vc3RhcnRcIixcIm1ldGhvZFwiOlwiUE9TVFwiLFwicXVvdGFcIjoxLFwiY2FsbFJhdGVSZW5ld2FsUGVyaW9kXCI6NjAsXCJjYWxsUmF0ZUxpbWl0XCI6MX0se1wicGF0aFwiOlwiZmFjZS92MS4yLXByZXZpZXcuMS9zZXNzaW9uL2F0dGVtcHQvZW5kXCIsXCJtZXRob2RcIjpcIlBPU1RcIixcInF1b3RhXCI6MyxcImNhbGxSYXRlUmVuZXdhbFBlcmlvZFwiOjUsXCJjYWxsUmF0ZUxpbWl0XCI6MX0se1wicGF0aFwiOlwiZmFjZS92MS4yLXByZXZpZXcuMS9kZXRlY3RMaXZlbmVzcy9zaW5nbGVNb2RhbFwiLFwibWV0aG9kXCI6XCJwb3N0XCIsXCJxdW90YVwiOjMsXCJjYWxsUmF0ZVJlbmV3YWxQZXJpb2RcIjo1LFwiY2FsbFJhdGVMaW1pdFwiOjF9XSIsImF6dXJlLXJlc291cmNlLWlkIjoiL3N1YnNjcmlwdGlvbnMvODY1ODU2MGYtMTc0OS00N2Y2LTkyZDktZjA2YjE1NTI4MjA3L3Jlc291cmNlR3JvdXBzL2F6dXJlLWFpLWVsaXRlL3Byb3ZpZGVycy9NaWNyb3NvZnQuQ29nbml0aXZlU2VydmljZXMvYWNjb3VudHMvZWxpdGVreWMtZmFjZS1hcGktdGVzdCIsInNpZCI6ImE4YzdlNGMxLTY3YTctNDhmZi1hMGE2LTlkOWFkOTgwNzBlZiIsImZhY2UiOiJ7XCJlbmRwb2ludFwiOlwiaHR0cHM6Ly9lbGl0ZWt5Yy1mYWNlLWFwaS10ZXN0LmNvZ25pdGl2ZXNlcnZpY2VzLmF6dXJlLmNvbVwiLFwic2Vzc2lvblR5cGVcIjpcIkxpdmVuZXNzXCIsXCJjbGllbnRDbGFpbXNcIjp7XCJsaXZlbmVzc09wZXJhdGlvbk1vZGVcIjpcIlBhc3NpdmVcIn19IiwiYXVkIjoidXJuOm1zLmZhY2VTZXNzaW9uVG9rZW4iLCJleHAiOjE3MzkxMDcxNjUsImlhdCI6MTczOTEwNTM2NSwiaXNzIjoidXJuOm1zLmNvZ25pdGl2ZXNlcnZpY2VzIn0.GMeUOq_fWafcctNiE_wDMvlYVuLR9t1xcTEtStc5vaIOQxhDwwaE0XKlA5F9sst7we8dqkeOjtS7XKKCYCGRqQ',
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
