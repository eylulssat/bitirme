/**
 * editor.js — Zengin metin editörü, tablo ve görsel yapıştırma
 */

const Editor = (() => {
  let editorEl;
  let editorPanelEl;
  let saveTimer = null;

  function init() {
    editorEl = document.getElementById('editor');
    editorPanelEl = document.querySelector('.editor-panel');

    initToolbar();
    initImagePaste();
    initAutoSave();
  }

  /** Araç çubuğu komutları */
  function initToolbar() {
    document.getElementById('font-family').addEventListener('change', (e) => {
      document.execCommand('fontName', false, e.target.value);
      editorEl.focus();
    });

    document.getElementById('font-size').addEventListener('change', (e) => {
      const selection = window.getSelection();
      if (!selection.rangeCount) return;
      const range = selection.getRangeAt(0);
      if (range.collapsed) {
        editorEl.style.fontSize = e.target.value;
      } else {
        const span = document.createElement('span');
        span.style.fontSize = e.target.value;
        range.surroundContents(span);
      }
      editorEl.focus();
    });

    document.querySelectorAll('.btn-tool[data-cmd]').forEach((btn) => {
      btn.addEventListener('click', () => {
        document.execCommand(btn.dataset.cmd, false, null);
        editorEl.focus();
      });
    });

    document.getElementById('insert-table-btn').addEventListener('click', () => {
      insertTable(3, 3);
    });
  }

  /** Excel benzeri düzenlenebilir tablo ekle */
  function insertTable(rows, cols) {
    let html = '<table><tbody>';
    for (let r = 0; r < rows; r++) {
      html += '<tr>';
      for (let c = 0; c < cols; c++) {
        const tag = r === 0 ? 'th' : 'td';
        html += `<${tag} contenteditable="true">&nbsp;</${tag}>`;
      }
      html += '</tr>';
    }
    html += '</tbody></table><p><br></p>';

    document.execCommand('insertHTML', false, html);
    editorEl.focus();
    saveNow();
  }

  /** Ctrl+V ile görsel yapıştırma */
  function initImagePaste() {
    editorEl.addEventListener('paste', (e) => {
      const items = e.clipboardData?.items;
      if (!items) return;

      for (const item of items) {
        if (item.type.startsWith('image/')) {
          e.preventDefault();
          const blob = item.getAsFile();
          const reader = new FileReader();
          reader.onload = (ev) => {
            const img = `<img src="${ev.target.result}" alt="Yapıştırılan görsel">`;
            document.execCommand('insertHTML', false, img);
            saveNow();
          };
          reader.readAsDataURL(blob);
          return;
        }
      }
    });
  }

  /** Her değişiklikte state'e otomatik kaydet (debounce) */
  function initAutoSave() {
    editorEl.addEventListener('input', () => {
      clearTimeout(saveTimer);
      saveTimer = setTimeout(saveNow, 300);
    });
  }

  function saveNow() {
    if (AppState.state.activePageId) {
      AppState.saveActiveContent(editorEl.innerHTML);
      AppState.persist();
    }
  }

  /** Belirli bir sayfanın içeriğini editöre yükle */
  function loadPage(pageId) {
    if (!pageId) {
      editorEl.innerHTML = '';
      editorPanelEl.classList.add('no-page');
      editorEl.setAttribute('contenteditable', 'false');
      return;
    }

    editorPanelEl.classList.remove('no-page');
    editorEl.setAttribute('contenteditable', 'true');
    editorEl.innerHTML = AppState.getPageContent(pageId);
    editorEl.focus();
  }

  /** Sayfa değişmeden önce mevcut içeriği kaydet */
  function saveBeforeSwitch() {
    saveNow();
  }

  return { init, loadPage, saveBeforeSwitch };
})();
