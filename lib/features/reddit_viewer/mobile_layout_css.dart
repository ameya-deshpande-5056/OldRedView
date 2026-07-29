/// Provides phone-only layout fixes for old.reddit.com.
///
/// The stylesheet is injected only for phone-sized layouts and keeps the
/// desktop layout unchanged on tablets.
class MobileLayoutCss {
  MobileLayoutCss._();

  /// Returns the full CSS stylesheet as a string.
  static String get stylesheet => '''
  html, body {
    width: 100% !important;
    overflow-x: hidden !important;
  }

  body {
    margin: 0 !important;
    padding: 0 !important;
  }

  #header,
  .header,
  #header-bottom-left,
  #header-bottom-right,
  .tabmenu,
  .content,
  .content[role="main"],
  .sitetable,
  .linklisting,
  .commentarea,
  .side,
  .panestack-title,
  .titlebox,
  .listing-chooser,
  .organic-listing {
    box-sizing: border-box !important;
    max-width: 100% !important;
  }

  #header,
  .header {
    padding: 0 8px !important;
  }

  #header-bottom-left,
  #header-bottom-right,
  .tabmenu {
    width: 100% !important;
    float: none !important;
    display: flex !important;
    flex-wrap: wrap !important;
    align-items: center !important;
    gap: 6px !important;
  }

  .tabmenu li {
    margin: 0 !important;
  }

  .tabmenu a {
    padding: 8px 10px !important;
  }

  .side {
    display: none !important;
  }

  .content {
    margin: 0 !important;
    padding: 0 8px 16px !important;
    width: 100% !important;
  }

  .link,
  .thing,
  .comment,
  .entry,
  .usertext-body,
  .md,
  .md p,
  .md ul,
  .md ol,
  .md blockquote {
    max-width: 100% !important;
    word-break: break-word !important;
  }

  .link {
    padding: 8px 0 !important;
  }

  .link .midcol,
  .comment .midcol {
    width: 32px !important;
    min-width: 32px !important;
  }

  .link .entry {
    margin-left: 0 !important;
  }

  .thumbnail,
  .thumbnail img,
  img,
  video,
  iframe,
  embed,
  object {
    max-width: 100% !important;
    height: auto !important;
  }

  pre,
  code,
  .md pre,
  .md code {
    white-space: pre-wrap !important;
    word-break: break-word !important;
  }

  input,
  textarea,
  select,
  button {
    max-width: 100% !important;
  }

  .nextprev,
  .nav-buttons,
  .bottom,
  .footer,
  .footer-parent {
    width: 100% !important;
  }
}
''';
}
