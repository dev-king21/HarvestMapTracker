import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class GoogleHttpClient extends IOClient {
  Map<String, String> headerParam;
  GoogleHttpClient(this.headerParam) : super();
  @override
  Future<IOStreamedResponse> send(http.BaseRequest request) async =>
      super.send(request..headers.addAll(headerParam));
  @override
  Future<http.Response> head(Object url, {Map<String, String> headers}) =>
      super.head(url, headers: headers..addAll(headerParam));
}

var signedIn = false;
var storage = FlutterSecureStorage();
var _auth = FirebaseAuth.instance;
GoogleSignInAccount googleSignInAccount;
var googleSignIn =
    GoogleSignIn(scopes: ['https://www.googleapis.com/auth/drive.appdata']);

class GoogleDriveManager {
  static ga.FileList list;

  Future<void> loginWithGoogle() async {
    signedIn = await storage.read(key: 'signedIn') == 'true' ? true : false;
    googleSignIn.onCurrentUserChanged.listen((googleSignInAccount) async {
      if (googleSignInAccount != null) {
        await afterGoogleLogin(googleSignInAccount);
      }
    });
    if (signedIn && googleSignInAccount != null) {
      try {
        await googleSignIn.signInSilently().whenComplete(() => () {});
      } catch (e) {
        await storage.write(key: 'signedIn', value: 'false').then((value) {
          signedIn = false;
        });
      }
    } else {
      final googleSignInAccount = await googleSignIn.signIn();
      //await googleSignInAccount.authHeaders;
      await afterGoogleLogin(googleSignInAccount);
    }
  }

  Future<void> afterGoogleLogin(GoogleSignInAccount gSA) async {
    googleSignInAccount = gSA;
    final googleSignInAuthentication = await googleSignInAccount.authentication;

    final credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final authResult = await _auth.signInWithCredential(credential);
    final user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    print('signInWithGoogle succeeded: $user');
    await storage.write(key: 'signedIn', value: 'true').then((value) {
      signedIn = true;
    });
  }

  Future<void> logoutFromGoogle() async {
    await googleSignIn.signOut().then((value) {
      print('User Sign Out');
      storage.write(key: 'signedIn', value: 'false').then((value) {
        signedIn = true;
      });
    });
  }

  Future<void> uploadFileToGoogleDrive(String mapData) async {
    var client = GoogleHttpClient(await googleSignInAccount.authHeaders);
    var drive = ga.DriveApi(client);
    var fileToUpload = ga.File();
    //var file = await FilePicker.getFile();
    final directory = await getExternalStorageDirectory();
    var file =
        await File('${directory.path}/map_data.json').writeAsString(mapData);

    var list = await drive.files.list(spaces: 'appDataFolder');
    list.files.forEach((element) {
      drive.files.delete(element.id);
    });

    fileToUpload.parents = ['appDataFolder'];
    fileToUpload.name = path.basename(file.absolute.path);
    await drive.files.create(
      fileToUpload,
      uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
    );
    //listGoogleDriveFiles();
    file.deleteSync();
  }

  static Future<List<int>> listGoogleDriveFiles() async {
    var client = GoogleHttpClient(await googleSignInAccount.authHeaders);
    var drive = ga.DriveApi(client);
    var list = await drive.files.list(spaces: 'appDataFolder');
    if (list.files.isNotEmpty) {
      return await restoreFromDrive(list.files[0].name, list.files[0].id);
    }
    return null;
  }

  static Future<List<int>> restoreFromDrive(String fName, String gdID) async {
    var client = GoogleHttpClient(await googleSignInAccount.authHeaders);
    var drive = ga.DriveApi(client);
    var file = (await drive.files
        .get(gdID, downloadOptions: ga.DownloadOptions.FullMedia)) as ga.Media;

    var dataStore = <int>[];
    var streamListen = file.stream.listen((data) {
      dataStore.insertAll(dataStore.length, data);
    }).asFuture<void>();
    await Future.wait<void>([streamListen]);
    return dataStore;
  }
}
