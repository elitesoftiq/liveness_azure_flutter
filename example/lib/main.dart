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
'eyJhbGciOiJFUzI1NiIsImtpZCI6ImtleTEiLCJ0eXAiOiJKV1QifQ.eyJyZWdpb24iOiJnZXJtYW55d2VzdGNlbnRyYWwiLCJzdWJzY3JpcHRpb24taWQiOiI1Y2EwYTYwMDFkOGE0N2M1YWU1YTU1NjI2ZThmYmIzNiIsInByb2R1Y3QtaWQiOiJGYWNlLkYwIiwiYWxsb3dlZC1wYXRocyI6Ilt7XCJwYXRoXCI6XCJmYWNlL3YxLjItcHJldmlldy4xL3Nlc3Npb24vc3RhcnRcIixcIm1ldGhvZFwiOlwiUE9TVFwiLFwicXVvdGFcIjoxLFwiY2FsbFJhdGVSZW5ld2FsUGVyaW9kXCI6NjAsXCJjYWxsUmF0ZUxpbWl0XCI6MX0se1wicGF0aFwiOlwiZmFjZS92MS4yLXByZXZpZXcuMS9zZXNzaW9uL2F0dGVtcHQvZW5kXCIsXCJtZXRob2RcIjpcIlBPU1RcIixcInF1b3RhXCI6MyxcImNhbGxSYXRlUmVuZXdhbFBlcmlvZFwiOjUsXCJjYWxsUmF0ZUxpbWl0XCI6MX0se1wicGF0aFwiOlwiZmFjZS92MS4yLXByZXZpZXcuMS9kZXRlY3RMaXZlbmVzcy9zaW5nbGVNb2RhbFwiLFwibWV0aG9kXCI6XCJwb3N0XCIsXCJxdW90YVwiOjMsXCJjYWxsUmF0ZVJlbmV3YWxQZXJpb2RcIjo1LFwiY2FsbFJhdGVMaW1pdFwiOjF9XSIsImF6dXJlLXJlc291cmNlLWlkIjoiL3N1YnNjcmlwdGlvbnMvODY1ODU2MGYtMTc0OS00N2Y2LTkyZDktZjA2YjE1NTI4MjA3L3Jlc291cmNlR3JvdXBzL2F6dXJlLWFpLWVsaXRlL3Byb3ZpZGVycy9NaWNyb3NvZnQuQ29nbml0aXZlU2VydmljZXMvYWNjb3VudHMvZWxpdGVreWMtZmFjZS1hcGkiLCJzaWQiOiJiNzc2Y2YxNC02ZmIzLTRlYmEtODBlZC04ZjgwZTczYzRkMGMiLCJmYWNlIjoie1wiZW5kcG9pbnRcIjpcImh0dHBzOi8vZWxpdGVreWMtZmFjZS1hcGkuY29nbml0aXZlc2VydmljZXMuYXp1cmUuY29tXCIsXCJzZXNzaW9uVHlwZVwiOlwiTGl2ZW5lc3NcIixcImNsaWVudENsYWltc1wiOntcImxpdmVuZXNzT3BlcmF0aW9uTW9kZVwiOlwiUGFzc2l2ZVwifX0iLCJhdWQiOiJ1cm46bXMuZmFjZVNlc3Npb25Ub2tlbiIsImV4cCI6MTczODA2Njg1NywiaWF0IjoxNzM4MDY2MjU3LCJpc3MiOiJ1cm46bXMuY29nbml0aXZlc2VydmljZXMifQ.bHGyzwskXx6lDUyAZqYhU1OcoXRTGFofxNIl5gg1Vf7zd_IjvXUvNDEfkpDdhR_xTjeQ7m_YijVjwp3QqdmFSg',
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
