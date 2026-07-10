/**
 * sidebar.js — Sol panel: ağaç yapısı, başlık ekleme, yeniden boyutlandırma
 */

const Sidebar = (() => {
  let treeRootEl;
  let sidebarEl;
  let resizeHandleEl;
  let onPageSelectCallback = null;

  function init({ onPageSelect }) {
    treeRootEl = document.getElementById('tree-root');
    sidebarEl = document.getElementById('sidebar');
    resizeHandleEl = document.getElementById('resize-handle');
    onPageSelectCallback = onPageSelect;

    document.getElementById('add-root-btn').addEventListener('click', () => {
      addRootWithPrompt();
    });

    initResize();
    render();
  }

  /** Ağacı DOM'a çiz */
  function render() {
    treeRootEl.innerHTML = '';

    if (AppState.state.tree.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'tree-empty';
      empty.textContent = 'Henüz sayfa yok. Yeni bir sayfa oluşturun.';
      treeRootEl.appendChild(empty);
      return;
    }

    AppState.state.tree.forEach((node) => {
      treeRootEl.appendChild(createTreeItem(node));
    });
    highlightActive();
  }

  /** Tek bir ağaç düğümünü <li> olarak oluştur */
  function createTreeItem(node) {
    const outerLi = document.createElement('li');

    const row = document.createElement('div');
    row.className = 'tree-item';
    row.dataset.id = node.id;

    const label = document.createElement('span');
    label.className = 'tree-label';
    label.textContent = node.title;
    label.addEventListener('click', () => selectPage(node.id));

    const actions = document.createElement('div');
    actions.className = 'tree-actions';

    const addChildBtn = document.createElement('button');
    addChildBtn.className = 'btn-icon';
    addChildBtn.title = 'Alt başlık ekle';
    addChildBtn.textContent = '+';
    addChildBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      addChildWithPrompt(node.id);
    });

    const renameBtn = document.createElement('button');
    renameBtn.className = 'btn-icon';
    renameBtn.title = 'Yeniden adlandır';
    renameBtn.textContent = '✎';
    renameBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      startRename(row, node.id, node.title);
    });

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn-icon danger';
    deleteBtn.title = 'Sil';
    deleteBtn.textContent = '×';
    deleteBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (confirm(`"${node.title}" ve alt başlıkları silinsin mi?`)) {
        AppState.deleteNode(node.id);
        AppState.persist();
        render();
        onPageSelectCallback(AppState.state.activePageId);
      }
    });

    actions.append(addChildBtn, renameBtn, deleteBtn);
    row.append(label, actions);
    outerLi.appendChild(row);

    if (node.children.length > 0) {
      const childUl = document.createElement('ul');
      node.children.forEach((child) => {
        childUl.appendChild(createTreeItem(child));
      });
      outerLi.appendChild(childUl);
    }

    return outerLi;
  }

  /** Sayfa seç — callback ile editöre bildir */
  function selectPage(id) {
    AppState.setActivePage(id);
    highlightActive();
    onPageSelectCallback(id);
    AppState.persist();
  }

  /** Aktif başlığı görsel olarak işaretle */
  function highlightActive() {
    document.querySelectorAll('.tree-item').forEach((el) => {
      el.classList.toggle('active', el.dataset.id === AppState.state.activePageId);
    });
  }

  /** Yeni ana başlık ekle — klavyeden isim gir */
  function addRootWithPrompt() {
    const node = AppState.addRootNode('');
    AppState.persist();
    render();

    const newItem = treeRootEl.querySelector(`[data-id="${node.id}"]`);
    if (newItem) startRename(newItem, node.id, '');
  }

  /** Alt başlık ekle — klavyeden isim gir */
  function addChildWithPrompt(parentId) {
    const node = AppState.addChildNode(parentId, '');
    if (!node) return;
    AppState.persist();
    render();

    const newItem = document.querySelector(`[data-id="${node.id}"]`);
    if (newItem) startRename(newItem, node.id, '');
  }

  /** Başlık adını inline düzenle */
  function startRename(treeItemEl, id, currentTitle) {
    const label = treeItemEl.querySelector('.tree-label');
    if (!label) return;

    const input = document.createElement('input');
    input.className = 'tree-label-input';
    input.type = 'text';
    input.value = currentTitle;
    input.placeholder = 'Başlık adını yazın...';

    label.replaceWith(input);
    input.focus();
    input.select();

    function commit() {
      const title = input.value.trim() || 'Adsız Başlık';
      AppState.updateNodeTitle(id, title);
      AppState.persist();

      const newLabel = document.createElement('span');
      newLabel.className = 'tree-label';
      newLabel.textContent = title;
      newLabel.addEventListener('click', () => selectPage(id));
      input.replaceWith(newLabel);

      if (!AppState.state.activePageId) {
        selectPage(id);
      }
    }

    input.addEventListener('blur', commit);
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        input.blur();
      }
      if (e.key === 'Escape') {
        input.value = currentTitle || 'Adsız Başlık';
        input.blur();
      }
    });
  }

  /** Sidebar yeniden boyutlandırma (drag) */
  function initResize() {
    let isDragging = false;
    let startX = 0;
    let startWidth = 0;

    resizeHandleEl.addEventListener('mousedown', (e) => {
      isDragging = true;
      startX = e.clientX;
      startWidth = sidebarEl.offsetWidth;
      resizeHandleEl.classList.add('dragging');
      document.body.classList.add('resizing');
      e.preventDefault();
    });

    document.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      const delta = e.clientX - startX;
      const newWidth = Math.min(
        parseInt(getComputedStyle(document.documentElement).getPropertyValue('--sidebar-max')),
        Math.max(
          parseInt(getComputedStyle(document.documentElement).getPropertyValue('--sidebar-min')),
          startWidth + delta
        )
      );
      sidebarEl.style.width = newWidth + 'px';
    });

    document.addEventListener('mouseup', () => {
      if (!isDragging) return;
      isDragging = false;
      resizeHandleEl.classList.remove('dragging');
      document.body.classList.remove('resizing');
      localStorage.setItem('docnotes_sidebar_width', sidebarEl.offsetWidth);
    });

    const savedWidth = localStorage.getItem('docnotes_sidebar_width');
    if (savedWidth) {
      sidebarEl.style.width = savedWidth + 'px';
    }
  }

  return { init, render, selectPage, highlightActive };
})();
