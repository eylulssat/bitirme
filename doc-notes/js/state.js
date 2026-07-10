/**
 * state.js — Merkezi veri yönetimi
 *
 * Tüm başlık ağacı ve sayfa içerikleri tek bir state objesinde tutulur.
 * Sayfa geçişlerinde içerik kaybolmaz; editor HTML'i buraya yazılır/okunur.
 */

const AppState = (() => {
  const state = {
    activePageId: null,
    tree: [],
    pageContents: {},
  };

  function generateId() {
    return 'page_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2, 7);
  }

  function findNode(id, nodes = state.tree) {
    for (const node of nodes) {
      if (node.id === id) return node;
      const found = findNode(id, node.children);
      if (found) return found;
    }
    return null;
  }

  function findParent(id, nodes = state.tree, parent = null) {
    for (let i = 0; i < nodes.length; i++) {
      if (nodes[i].id === id) return { parent, siblings: nodes, index: i };
      const found = findParent(id, nodes[i].children, nodes[i]);
      if (found) return found;
    }
    return null;
  }

  function createNode(title = 'Yeni Başlık') {
    const id = generateId();
    const node = { id, title, children: [] };
    state.pageContents[id] = '';
    return node;
  }

  function addRootNode(title) {
    const node = createNode(title);
    state.tree.push(node);
    return node;
  }

  function addChildNode(parentId, title) {
    const parent = findNode(parentId);
    if (!parent) return null;
    const node = createNode(title);
    parent.children.push(node);
    return node;
  }

  function updateNodeTitle(id, title) {
    const node = findNode(id);
    if (node) node.title = title;
  }

  function deleteNode(id) {
    const location = findParent(id);
    if (!location) return;

    const node = location.siblings[location.index];
    collectIds(node).forEach((nid) => {
      delete state.pageContents[nid];
    });

    location.siblings.splice(location.index, 1);

    if (state.activePageId === id) {
      state.activePageId = null;
    }
  }

  function collectIds(node) {
    const ids = [node.id];
    node.children.forEach((child) => ids.push(...collectIds(child)));
    return ids;
  }

  function setActivePage(id) {
    state.activePageId = id;
  }

  function savePageContent(id, html) {
    if (Object.prototype.hasOwnProperty.call(state.pageContents, id)) {
      state.pageContents[id] = html;
    }
  }

  function getPageContent(id) {
    return state.pageContents[id] ?? '';
  }

  function saveActiveContent(html) {
    if (state.activePageId) {
      savePageContent(state.activePageId, html);
    }
  }

  function getActiveContent() {
    return state.activePageId ? getPageContent(state.activePageId) : '';
  }

  function persist() {
    try {
      localStorage.setItem('docnotes_state', JSON.stringify({
        tree: state.tree,
        pageContents: state.pageContents,
        activePageId: state.activePageId,
      }));
    } catch (_) { /* depolama dolu olabilir */ }
  }

  function load() {
    try {
      const raw = localStorage.getItem('docnotes_state');
      if (!raw) return false;
      const data = JSON.parse(raw);
      state.tree = data.tree || [];
      state.pageContents = data.pageContents || {};
      state.activePageId = data.activePageId || null;
      return true;
    } catch (_) {
      return false;
    }
  }

  return {
    get state() { return state; },
    generateId,
    findNode,
    addRootNode,
    addChildNode,
    updateNodeTitle,
    deleteNode,
    setActivePage,
    savePageContent,
    getPageContent,
    saveActiveContent,
    getActiveContent,
    persist,
    load,
  };
})();
