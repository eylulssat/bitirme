/**
 * app.js — Uygulama başlatıcı ve modüller arası koordinasyon
 */

document.addEventListener('DOMContentLoaded', () => {
  AppState.load();

  Editor.init();

  Sidebar.init({
    onPageSelect(pageId) {
      Editor.saveBeforeSwitch();
      Editor.loadPage(pageId);
    },
  });

  if (AppState.state.activePageId) {
    Editor.loadPage(AppState.state.activePageId);
    Sidebar.highlightActive();
  } else {
    Editor.loadPage(null);
  }
});
