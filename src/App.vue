<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue';
import type { UnlistenFn } from '@tauri-apps/api/event';
import ChannelCard from './components/ChannelCard.vue';
import LogDrawer from './components/LogDrawer.vue';
import QuickSettings from './components/QuickSettings.vue';
import ProjectCenterDrawer from './components/ProjectCenterDrawer.vue';
import SettingsDrawer from './components/SettingsDrawer.vue';
import TaskCenterDrawer from './components/TaskCenterDrawer.vue';
import StartReviewDialog from './components/StartReviewDialog.vue';
import ToastHost from './components/ToastHost.vue';
import { CHANNEL_CATEGORIES } from './config/appearance';
import { registerBackendEvents, registerFileDrop } from './services/tauri';
import { useChannelStore } from './stores/channels';
import { useTaskCenterStore } from './stores/taskCenter';
import { useProjectCenterStore } from './stores/projectCenter';
import type { Channel, ChannelCategory, ChannelStatus } from './types';

const store = useChannelStore();
const taskCenter = useTaskCenterStore();
const projectCenter = useProjectCenterStore();
const unlisteners: UnlistenFn[] = [];
const allExpanded = computed(() => store.channels.length > 0 && store.channels.every((channel) => channel.expanded));
const backendConnected = ref(true);
const searchQuery = ref('');
const categoryFilter = ref<'all' | ChannelCategory>('all');
const statusFilter = ref<'all' | ChannelStatus>('all');
const newChannelCategory = ref<ChannelCategory>(store.appSettings.defaultCategory);
const keywordChannelCount = computed(() => store.channels.filter((channel) => channel.inboxEnabled && channel.inboxDirectory.trim() && channel.inboxKeywords.trim()).length);
const keywordScanning = computed(() => store.inboxScanningIds.length > 0);
let hoveredChannelId: string | null = null;

const categoryMap = new Map(CHANNEL_CATEGORIES.map((item) => [item.id, item]));

const displayedChannels = computed(() => {
  const query = searchQuery.value.trim().toLocaleLowerCase();
  const filtered = store.channels.filter((channel) => {
    const matchesQuery =
      !query ||
      channel.name.toLocaleLowerCase().includes(query) ||
      channel.note.toLocaleLowerCase().includes(query) ||
      channel.inboxKeywords.toLocaleLowerCase().includes(query) ||
      channel.inboxDirectory.toLocaleLowerCase().includes(query) ||
      channel.files.some((file) => file.name.toLocaleLowerCase().includes(query));
    const matchesCategory = categoryFilter.value === 'all' || channel.category === categoryFilter.value;
    const matchesStatus = statusFilter.value === 'all' || store.channelStatus(channel) === statusFilter.value;
    return matchesQuery && matchesCategory && matchesStatus;
  });

  const sorted = [...filtered];
  if (store.appSettings.channelSort === 'name') sorted.sort((a, b) => a.name.localeCompare(b.name, 'zh-CN'));
  if (store.appSettings.channelSort === 'category') sorted.sort((a, b) => a.category.localeCompare(b.category));
  if (store.appSettings.channelSort === 'status') {
    const order: Record<ChannelStatus, number> = { processing: 0, paused: 1, queued: 2, error: 3, idle: 4, done: 5 };
    sorted.sort((a, b) => order[store.channelStatus(a)] - order[store.channelStatus(b)]);
  }
  return sorted;
});

const channelGroups = computed(() => {
  if (!store.appSettings.groupByCategory) return [{ id: 'all', name: '', color: '', channels: displayedChannels.value }];
  return CHANNEL_CATEGORIES.map((category) => ({
    id: category.id,
    name: category.name,
    color: category.color,
    channels: displayedChannels.value.filter((channel) => channel.category === category.id),
  })).filter((group) => group.channels.length > 0);
});

function originalIndex(channel: Channel): number {
  return store.channels.findIndex((item) => item.id === channel.id);
}

function findChannelAt(clientX?: number, clientY?: number): string | null {
  if (clientX === undefined || clientY === undefined) return null;
  const element = document.elementFromPoint(clientX, clientY)?.closest<HTMLElement>('[data-channel-id]');
  return element?.dataset.channelId || null;
}

function clearDragState(): void {
  if (hoveredChannelId) store.setDragActive(hoveredChannelId, false);
  hoveredChannelId = null;
}

function createChannel(): void {
  store.addChannel(newChannelCategory.value);
}

function closeTransientPanels(): void {
  document.querySelector<HTMLDetailsElement>('.quick-settings[open]')?.removeAttribute('open');
  store.settingsOpen = false;
  store.logDrawerOpen = false;
  taskCenter.drawerOpen = false;
  projectCenter.drawerOpen = false;
}

function openSettings(): void {
  closeTransientPanels();
  store.settingsOpen = true;
}

function openLogs(): void {
  closeTransientPanels();
  store.logDrawerOpen = true;
}

function openTaskCenter(): void {
  closeTransientPanels();
  taskCenter.drawerOpen = true;
}

function openProjectCenter(): void {
  closeTransientPanels();
  projectCenter.drawerOpen = true;
}

function handleShortcut(event: KeyboardEvent): void {
  const target = event.target as HTMLElement | null;
  const editing = target?.matches('input, textarea, select, [contenteditable="true"]');
  if (event.key === 'Escape') {
    closeTransientPanels();
    return;
  }
  if (editing) return;
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'n') {
    event.preventDefault();
    createChannel();
  }
  if ((event.ctrlKey || event.metaKey) && event.key === ',') {
    event.preventDefault();
    openSettings();
  }
  if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.key.toLowerCase() === 'f') {
    event.preventDefault();
    void store.scanAllKeywordChannels();
  }
  if ((event.ctrlKey || event.metaKey) && event.shiftKey && event.key.toLowerCase() === 'p') {
    event.preventDefault();
    openProjectCenter();
  }
  if ((event.ctrlKey || event.metaKey) && event.key === 'Enter' && store.hasRunnableFiles && store.processingFiles === 0) {
    event.preventDefault();
    void store.startAll();
  }
}

onMounted(async () => {
  window.addEventListener('keydown', handleShortcut);
  try {
    unlisteners.push(
      ...(await registerBackendEvents({
        onProgress: store.onProgress,
        onJobFinished: store.onJobFinished,
        onBatchFinished: store.onBatchFinished,
      })),
    );
    if (store.appSettings.autoResumeInterrupted && taskCenter.recoverableRecords.length) {
      window.setTimeout(() => void store.resumeInterruptedTasks(true), 350);
    }
    if (store.appSettings.autoScanKeywordChannelsOnLaunch) {
      window.setTimeout(() => void store.scanAllKeywordChannels(true), 650);
    }
    unlisteners.push(
      await registerFileDrop(async (event) => {
        if (event.type === 'leave') {
          clearDragState();
          return;
        }
        const channelId = findChannelAt(event.clientX, event.clientY);
        if (channelId !== hoveredChannelId) {
          clearDragState();
          hoveredChannelId = channelId;
          if (channelId) store.setDragActive(channelId, true);
        }
        if (event.type === 'drop') {
          clearDragState();
          if (channelId && event.paths.length) await store.addPathsToChannel(channelId, event.paths);
        }
      }),
    );
  } catch (error) {
    backendConnected.value = false;
    store.pushToast({
      level: 'warn',
      title: '当前是浏览器预览模式',
      message: '文件与目录选择器需要通过 npm run tauri dev 启动桌面应用；界面设置仍可预览。',
      timeoutMs: 9000,
    });
    console.warn('Tauri API is unavailable. The UI can still be previewed in a browser.', error);
  }
});

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleShortcut);
  clearDragState();
  unlisteners.splice(0).forEach((unlisten) => unlisten());
});
</script>

<template>
  <div class="app-shell">
    <header class="topbar">
      <div class="brand">
        <div class="brand-mark" aria-hidden="true"><span /><span /><span /></div>
        <div>
          <div class="brand-title">解压台</div>
          <div class="brand-sub">多通道批量解压 · Tauri 2 + Rust</div>
        </div>
      </div>

      <div class="topbar-right">
        <div v-if="!backendConnected" class="preview-badge" title="请使用 npm run tauri dev 启动完整功能">浏览器预览</div>
        <label class="concurrency" title="全局最大并发解压任务数">
          并发
          <input v-model.number="store.maxConcurrency" type="range" min="1" max="8" />
          <b>{{ store.maxConcurrency }}</b>
        </label>
        <button class="btn btn-ghost" type="button" @click="store.toggleAllChannels(!allExpanded)">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M8 9l4-4 4 4M8 15l4 4 4-4" /></svg>
          {{ allExpanded ? '全部收起' : '全部展开' }}
        </button>
        <QuickSettings />
        <button class="btn btn-ghost task-center-trigger" type="button" title="项目中心（Ctrl+Shift+P）" @click="openProjectCenter">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 7a2 2 0 012-2h4l2 2h6a2 2 0 012 2v8a2 2 0 01-2 2H6a2 2 0 01-2-2V7z" /><path d="M8 12h8M12 9v6" /></svg>
          项目
          <span v-if="projectCenter.pinnedCount" class="nav-count live">{{ projectCenter.pinnedCount }}</span>
          <span v-else-if="projectCenter.activeCount" class="nav-count">{{ projectCenter.activeCount }}</span>
        </button>
        <button class="btn btn-ghost task-center-trigger" type="button" @click="openTaskCenter">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 6h16M4 12h10M4 18h7" /><circle cx="18" cy="15" r="3" /><path d="M18 13.5V15l1 1" /></svg>
          任务
          <span v-if="taskCenter.activeCount" class="nav-count live">{{ taskCenter.activeCount }}</span>
          <span v-else-if="taskCenter.failedCount" class="nav-count error">{{ taskCenter.failedCount }}</span>
        </button>
        <button class="btn btn-ghost" type="button" @click="openLogs">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 6h16M4 12h16M4 18h10" /></svg>
          日志
        </button>
        <button class="btn btn-ghost" type="button" @click="openSettings">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.7 1.7 0 00.34 1.88l.06.06-2.12 2.12-.06-.06a1.7 1.7 0 00-1.88-.34 1.7 1.7 0 00-1.03 1.56V20h-3v-.08a1.7 1.7 0 00-1.03-1.56 1.7 1.7 0 00-1.88.34l-.06.06-2.12-2.12.06-.06A1.7 1.7 0 007 15a1.7 1.7 0 00-1.56-1.03H5v-3h.44A1.7 1.7 0 007 9.94a1.7 1.7 0 00-.34-1.88L6.6 8l2.12-2.12.06.06a1.7 1.7 0 001.88.34A1.7 1.7 0 0011.7 4.7V4h3v.7a1.7 1.7 0 001.03 1.56 1.7 1.7 0 001.88-.34l.06-.06L19.8 8l-.06.06a1.7 1.7 0 00-.34 1.88A1.7 1.7 0 0021 10.97h.1v3H21A1.7 1.7 0 0019.4 15z" /></svg>
          设置
        </button>
        <button class="btn btn-primary" type="button" :disabled="!store.hasRunnableFiles || store.processingFiles > 0" @click="store.startAll">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M6 4l14 8-14 8V4z" /></svg>
          全部开始
        </button>
      </div>
    </header>

    <div class="workspace-toolbar" :class="{ sticky: store.appSettings.stickyToolbar }">
      <label class="search-box">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="11" cy="11" r="7" /><path d="M20 20l-4-4" /></svg>
        <input v-model="searchQuery" type="search" placeholder="搜索通道、备注、关键词或文件名" />
      </label>
      <select v-model="categoryFilter" class="toolbar-select" aria-label="筛选通道分类">
        <option value="all">全部分类</option>
        <option v-for="category in CHANNEL_CATEGORIES" :key="category.id" :value="category.id">{{ category.name }}</option>
      </select>
      <select v-model="statusFilter" class="toolbar-select" aria-label="筛选通道状态">
        <option value="all">全部状态</option>
        <option value="idle">待开始</option>
        <option value="queued">排队中</option>
        <option value="processing">处理中</option>
        <option value="paused">已暂停</option>
        <option value="done">已完成</option>
        <option value="error">有错误</option>
      </select>
      <span class="toolbar-summary">显示 {{ displayedChannels.length }}/{{ store.channels.length }} 个通道</span>
      <div class="toolbar-actions">
        <button class="btn btn-ghost btn-sm inbox-scan-trigger" type="button" :disabled="keywordScanning || keywordChannelCount === 0" title="扫描全部已启用的关键词收件通道（Ctrl+Shift+F）" @click="store.scanAllKeywordChannels()">
          {{ keywordScanning ? `扫描中 ${store.inboxScanningIds.length}` : `扫描收件 ${keywordChannelCount || ''}` }}
        </button>
        <button v-if="store.failedFiles" class="btn btn-ghost btn-sm" type="button" :disabled="store.processingFiles > 0" @click="store.startFailed">重试 {{ store.failedFiles }} 个失败</button>
        <button v-if="store.completedFiles" class="btn btn-ghost btn-sm" type="button" @click="store.clearAllFinished">清理完成</button>
      </div>
      <span class="shortcut-hint">Ctrl+N 新建 · Ctrl+Shift+P 项目 · Ctrl+Shift+F 扫描收件 · Ctrl+, 设置 · Ctrl+Enter 全部开始</span>
    </div>

    <div v-if="store.appSettings.showRecoveryBanner && taskCenter.interruptedCount" class="recovery-banner">
      <div><b>发现 {{ taskCenter.interruptedCount }} 个上次未完成任务</b><span>可恢复 {{ taskCenter.recoverableRecords.length }} 个；密码不会被保存。</span></div>
      <div><button class="btn btn-sm" type="button" @click="openTaskCenter">查看详情</button><button class="btn btn-primary btn-sm" type="button" :disabled="!taskCenter.recoverableRecords.length || store.processingFiles > 0" @click="store.resumeInterruptedTasks(false)">恢复可恢复任务</button><button class="banner-close" type="button" title="隐藏恢复提示" @click="store.appSettings.showRecoveryBanner = false">×</button></div>
    </div>

    <main class="board">
      <div class="col-head" aria-hidden="true">
        <div class="ch-w-id">通道</div>
        <div class="ch-w-files">文件队列</div>
        <div class="ch-w-meter">进度</div>
        <div class="ch-w-actions">操作</div>
      </div>

      <template v-for="group in channelGroups" :key="group.id">
        <div v-if="store.appSettings.groupByCategory" class="channel-group-head">
          <span class="category-dot" :style="{ background: group.color }" />
          <b>{{ group.name }}</b>
          <span>{{ group.channels.length }} 个通道</span>
        </div>
        <ChannelCard v-for="channel in group.channels" :key="channel.id" :channel="channel" :index="originalIndex(channel)" />
      </template>

      <div v-if="displayedChannels.length === 0" class="filter-empty">
        <b>没有匹配的通道</b>
        <span>清除搜索词或筛选条件后再试。</span>
        <button class="btn btn-sm" type="button" @click="searchQuery = ''; categoryFilter = 'all'; statusFilter = 'all'">清除筛选</button>
      </div>

      <div class="add-channel-row">
        <select v-model="newChannelCategory" class="toolbar-select" aria-label="新通道分类">
          <option v-for="category in CHANNEL_CATEGORIES" :key="category.id" :value="category.id">{{ category.name }}</option>
        </select>
        <button class="add-channel" type="button" @click="createChannel">
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M12 5v14M5 12h14" /></svg>
          <span>新建{{ categoryMap.get(newChannelCategory)?.name }}通道</span>
        </button>
      </div>
    </main>

    <footer class="statusbar">
      <div class="statusbar-left">
        <span class="statusbar-item"><span class="dot" />{{ store.channels.length }} 个通道</span>
        <span class="statusbar-item">{{ store.totalFiles }} 个文件</span>
        <span class="statusbar-item">{{ projectCenter.projects.length }} 个项目</span>
        <span class="statusbar-item">{{ store.processingFiles }} 个活动任务</span>
        <span v-if="taskCenter.pausedCount" class="statusbar-item">{{ taskCenter.pausedCount }} 个暂停</span>
        <span class="statusbar-item success-text">{{ store.completedFiles }} 个完成</span>
        <span v-if="store.failedFiles" class="statusbar-item danger-text">{{ store.failedFiles }} 个失败</span>
      </div>
      <button class="statusbar-link" type="button" @click="openLogs">查看完整日志</button>
    </footer>

    <LogDrawer />
    <TaskCenterDrawer />
    <ProjectCenterDrawer />
    <SettingsDrawer />
    <StartReviewDialog />
    <ToastHost />
  </div>
</template>
