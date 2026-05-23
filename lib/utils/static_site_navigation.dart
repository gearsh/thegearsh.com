import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Marketing-site URLs served outside the Flutter shell (/app/).
class StaticSiteUrls {
  static const signIn = '/sign-in';
  static const joinGig = '/join-gig.html';
  static const artistDashboard = '/artist-dashboard.html';
}

Future<void> openStaticPage(String path) async {
  if (!kIsWeb) return;
  final uri = Uri.parse(path);
  await launchUrl(uri, webOnlyWindowName: '_self');
}

Future<void> openStaticSignIn() => openStaticPage(StaticSiteUrls.signIn);

Future<void> openStaticJoinGig() => openStaticPage(StaticSiteUrls.joinGig);

Future<void> openStaticArtistDashboard() =>
    openStaticPage(StaticSiteUrls.artistDashboard);
