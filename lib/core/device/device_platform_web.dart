import 'dart:html' as html;

bool _isMobileUserAgent() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  if (ua.contains('iphone') ||
      ua.contains('ipod') ||
      ua.contains('ipad') ||
      ua.contains('android') ||
      ua.contains('mobile')) {
    return true;
  }

  // Some tablets report as desktop; use coarse pointer + narrow viewport as hint.
  final mq = html.window.matchMedia('(max-width: 768px) and (pointer: coarse)');
  return mq.matches;
}

/// True when the site is opened in a phone/tablet browser (not desktop web).
bool isMobileWebBrowser() => _isMobileUserAgent();

/// Admin dashboard is for desktop/laptop browsers only.
bool shouldShowAdminPanel() => !_isMobileUserAgent();
