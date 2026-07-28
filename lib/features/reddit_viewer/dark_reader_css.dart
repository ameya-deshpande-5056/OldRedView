/// Provides a Dark Reader inspired CSS stylesheet for old.reddit.com.
///
/// When the device is in dark mode, this CSS is injected into the WebView
/// to invert colors and provide a comfortable dark browsing experience.
/// The stylesheet is designed to replicate the behavior of the Dark Reader
/// browser extension without depending on any external service.
///
/// Key techniques used:
/// - Dark background with light text for all major elements.
/// - Adjusted link colors for readability on dark backgrounds.
/// - Reduced brightness on images to prevent eye strain.
/// - Custom scrollbar styling for dark mode.
/// - Reddit-specific element overrides for the old.reddit.com DOM.
class DarkReaderCss {
  DarkReaderCss._();

  /// Returns the full CSS stylesheet as a string.
  ///
  /// This CSS is designed specifically for old.reddit.com's DOM structure.
  /// It applies a dark background, light text, and adjusts links, borders,
  /// and images for comfortable night-time reading.
  static String get stylesheet => '''
/* ============================================
   Dark Reader inspired stylesheet
   for old.reddit.com
   ============================================ */

/* ---- Base dark theme ---- */
html {
  background-color: #181a1b !important;
}

body {
  background-color: #181a1b !important;
  color: #e8e6e3 !important;
}

/* ---- Links ---- */
a {
  color: #8db4e2 !important;
}

a:visited {
  color: #c9a0dc !important;
}

a:hover {
  color: #a8c7f0 !important;
}

/* ---- Headers and text ---- */
h1, h2, h3, h4, h5, h6,
.title, .entry, .tagline,
.comment, .usertext-body,
.md, .md p, .md h1, .md h2, .md h3,
.md h4, .md h5, .md h6,
.content, .side, .footer,
.thing, .link, .commentarea,
.panestack-title, .titlebox,
.subscribers, .users-online,
.leavemessage, .bottom,
.nextprev, .next-suggestions,
.help, .report, .hide-button,
.buttons, .buttons li,
.domain, .rank, .score,
.score.unvoted, .score.likes,
.score.dislikes, .arrow,
.arrow.up, .arrow.down,
.arrow.upmod, .arrow.downmod,
.midcol, .midcol .score,
.flat-list, .flat-list li {
  color: #e8e6e3 !important;
}

/* ---- Inputs and text areas ---- */
input, textarea, select, button {
  background-color: #2b2a27 !important;
  color: #e8e6e3 !important;
  border-color: #444 !important;
}

input[type="text"],
input[type="search"],
input[type="url"],
input[type="email"],
input[type="password"],
textarea {
  background-color: #1e1e1e !important;
  color: #e8e6e3 !important;
  border: 1px solid #444 !important;
}

/* ---- Buttons ---- */
.btn, button, input[type="submit"] {
  background-color: #2b2a27 !important;
  color: #e8e6e3 !important;
  border: 1px solid #555 !important;
}

.btn:hover, button:hover {
  background-color: #3a3a37 !important;
}

/* ---- Sidebar ---- */
.side, .sidecontentbox, .titlebox,
.linkinfo, .infobar, .help,
.account-activity-box,
.side .spacer, .sidebox,
.subscribers, .users-online,
.leavemessage, .bottom {
  background-color: #1e1e1e !important;
  border-color: #333 !important;
}

/* ---- Comments ---- */
.comment, .commentarea,
.entry, .usertext,
.usertext-body, .md,
.noncollapsed, .thing {
  background-color: transparent !important;
}

.comment .child, .comment .showreplies {
  border-left-color: #444 !important;
}

/* ---- Separators and borders ---- */
hr, .separator, .border,
.md hr {
  border-color: #444 !important;
}

/* ---- Flair and badges ---- */
.flair, .flairrichtext {
  background-color: #2b2a27 !important;
  color: #e8e6e3 !important;
  border-color: #555 !important;
}

/* ---- Tables ---- */
table, th, td {
  border-color: #444 !important;
  background-color: transparent !important;
}

th {
  background-color: #2b2a27 !important;
}

/* ---- Code blocks ---- */
code, pre, .md code, .md pre {
  background-color: #1e1e1e !important;
  color: #e8e6e3 !important;
  border-color: #444 !important;
}

/* ---- Blockquotes ---- */
blockquote, .md blockquote {
  border-left-color: #555 !important;
  color: #c0bdb8 !important;
}

/* ---- Images and media ---- */
img, video, canvas, svg {
  /* Reduce brightness of bright images in dark mode */
  filter: brightness(0.85) !important;
}

a img:hover, a video:hover {
  filter: brightness(1.0) !important;
}

/* ---- Thumbnails ---- */
.thumbnail img, .thumbnail {
  filter: brightness(0.85) !important;
}

.thumbnail img:hover {
  filter: brightness(1.0) !important;
}

/* ---- Score and vote arrows ---- */
.score, .score.unvoted, .score.likes, .score.dislikes {
  color: #e8e6e3 !important;
}

.arrow {
  filter: brightness(0.8) !important;
}

.arrow.upmod, .arrow.downmod {
  filter: brightness(1.2) !important;
}

/* ---- Header ---- */
#header, .header, .tabmenu,
#header-bottom-left,
#header-bottom-right,
.pagename, .redditname {
  background-color: #1a1a1a !important;
  border-color: #333 !important;
}

#header .tabmenu li a,
#header .tabmenu li.selected a {
  background-color: #2b2a27 !important;
  color: #8db4e2 !important;
  border-color: #444 !important;
}

#header .tabmenu li.selected a {
  background-color: #3a3a37 !important;
  color: #e8e6e3 !important;
}

/* ---- Footer ---- */
.footer, .footer-parent,
.bottom, .debuginfo {
  background-color: #1a1a1a !important;
  color: #888 !important;
}

/* ---- Search ---- */
.search-summary, .search-result,
.search-result-group,
.search-result-header,
.search-result-meta,
.search-result-footer {
  background-color: transparent !important;
  color: #e8e6e3 !important;
}

/* ---- RES (Reddit Enhancement Suite) compatibility ---- */
.res .thing, .res .entry,
.res .comment, .res .link {
  background-color: transparent !important;
}

.res .RES-keyNav-activeElement,
.res .RES-keyNav-activeElement .md-container {
  background-color: #2a2a2a !important;
}

/* ---- Scrollbar ---- */
::-webkit-scrollbar {
  width: 12px !important;
  height: 12px !important;
}

::-webkit-scrollbar-track {
  background: #1a1a1a !important;
}

::-webkit-scrollbar-thumb {
  background: #444 !important;
  border-radius: 6px !important;
}

::-webkit-scrollbar-thumb:hover {
  background: #555 !important;
}

/* ---- Selection ---- */
::selection {
  background-color: #3a5a8a !important;
  color: #e8e6e3 !important;
}

/* ---- Overlay and popups ---- */
.overlay, .popup, .modal,
.hover-bubble, .hoverpane {
  background-color: #1e1e1e !important;
  border-color: #444 !important;
  color: #e8e6e3 !important;
}

/* ---- Gold/Reddit Premium ---- */
.gold-accent, .premium-banner {
  color: #d4af37 !important;
}

/* ---- Error pages ---- */
.error, .error-page, .permission-denied {
  background-color: #1e1e1e !important;
  color: #e8e6e3 !important;
}

/* ---- Loading indicator ---- */
.loading, .spinner, .throbber {
  filter: brightness(0.8) !important;
}
''';
}