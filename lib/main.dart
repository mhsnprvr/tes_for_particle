import 'package:flutter/material.dart';
import 'package:particle_auth_core/particle_auth_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:uuid/uuid.dart';

import 'package:particle_base/model/user_info.dart' as ParticleUser;
import 'package:particle_base/model/login_info.dart' as PLoginInfo;
import 'package:particle_base/particle_base.dart' as ParticleBase;
import 'package:particle_base/model/chain_info.dart' as ChainInfo;

Future<ParticleUser.UserInfo?> particleSocialLogin(
    {required PLoginInfo.LoginType type}) async {
  try {
    final isAlreadyLoggedIn = await ParticleAuthCore.isConnected();
    if (isAlreadyLoggedIn) {
      return await ParticleAuthCore.getUserInfo();
    }
    final userInfo = await ParticleAuthCore.connect(
      type,
    );
    return userInfo;
  } catch (e) {
    return null;
  }
}

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

final jitsiMeet = JitsiMeet();

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

final Map<String, Object?> featureFlags = {
  FeatureFlags.unsafeRoomWarningEnabled: false,
  FeatureFlags.securityOptionEnabled: false,
  FeatureFlags.iosScreenSharingEnabled: true,
  FeatureFlags.toolboxAlwaysVisible: true,
  FeatureFlags.inviteEnabled: false,
  FeatureFlags.raiseHandEnabled: true,
  FeatureFlags.videoShareEnabled: false,
  FeatureFlags.recordingEnabled: false,
  FeatureFlags.welcomePageEnabled: false,
  FeatureFlags.preJoinPageEnabled: false,
  FeatureFlags.pipEnabled: true,
  FeatureFlags.kickOutEnabled: false,
  FeatureFlags.fullScreenEnabled: true,
  FeatureFlags.reactionsEnabled: false,
  FeatureFlags.videoMuteEnabled: false,
};

final options = JitsiMeetConferenceOptions(
    room: Uuid().v4(),
    serverURL: 'https://meet.colega.app',
    featureFlags: featureFlags,
    configOverrides: {
      "startWithAudioMuted": true,
      "startWithVideoMuted": true,
    });

class _HomeState extends State<Home> {
  bool joined = false;
  bool loggedIn = false;
  bool isPrepared = false;
  bool isPreparing = true;

  prepare() async {
    ParticleBase.ParticleInfo.set(
      "*************",
      "*************",
    );
    ParticleBase.ParticleBase.init(
      ChainInfo.ChainInfo.Avalanche,
      ParticleBase.Env.dev,
    );
    setState(() {
      isPrepared = true;
      isPreparing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    prepare();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isPreparing) CircularProgressIndicator(),
              if (!joined && isPrepared)
                ElevatedButton(
                  onPressed: () {
                    jitsiMeet.join(
                        options,
                        JitsiMeetEventListener(
                          conferenceJoined: (url) {
                            setState(() {
                              joined = true;
                            });
                          },
                          conferenceTerminated: (url, error) {
                            setState(() {
                              joined = false;
                            });
                          },
                          readyToClose: () {
                            setState(() {
                              joined = false;
                            });
                          },
                        ));
                  },
                  child: Text('Go To Meeting'),
                ),
              if (joined)
                ElevatedButton(
                  onPressed: () {
                    jitsiMeet.hangUp();
                    setState(() {
                      joined = false;
                    });
                  },
                  child: Text('leave Meeting'),
                ),
              if (joined)
                ElevatedButton(
                  onPressed: () async {
                    await particleSocialLogin(
                        type: PLoginInfo.LoginType.google);
                  },
                  child: Text(
                    'login with google',
                  ),
                ),
              if (joined && loggedIn)
                ElevatedButton(
                  onPressed: () {},
                  child: Text('test transaction'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
