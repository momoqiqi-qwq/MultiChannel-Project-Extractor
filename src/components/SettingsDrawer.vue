<script setup lang="ts">
import { computed, ref } from 'vue';
import { useChannelStore } from '../stores/channels';
import { APP_VERSION } from '../config/version';
import GeneralSettings from './settings/GeneralSettings.vue';
import AppearanceSettings from './settings/AppearanceSettings.vue';
import BehaviorSettings from './settings/BehaviorSettings.vue';
import OutputSettings from './settings/OutputSettings.vue';
import ReliabilitySettings from './settings/ReliabilitySettings.vue';
import RecoverySettings from './settings/RecoverySettings.vue';
import InboxSettings from './settings/InboxSettings.vue';
import DeveloperToolsSettings from './settings/DeveloperToolsSettings.vue';
import MaintenanceSettings from './settings/MaintenanceSettings.vue';
import AboutSettings from './settings/AboutSettings.vue';

const store = useChannelStore();
type TabId = 'general' | 'appearance' | 'behavior' | 'output' | 'inbox' | 'reliability' | 'recovery' | 'developer' | 'maintenance' | 'about';
const activeTab = ref<TabId>('general');
const search = ref('');

const tabs: Array<{ id: TabId; label: string; icon: string; keywords: string }> = [
  { id: 'general', label: '常规', icon: '◉', keywords: '常规 默认 基础' },
  { id: 'appearance', label: '界面与字体', icon: '✦', keywords: '界面 字体 主题 背景 图标 彩虹 透明' },
  { id: 'behavior', label: '操作与导航', icon: '↔', keywords: '操作 拖动 窗口 导航 右键 快捷键 体验' },
  { id: 'output', label: '输出默认值', icon: '⇲', keywords: '输出 目录 层级 重名 默认' },
  { id: 'inbox', label: '关键词收件', icon: '⌕', keywords: '下载 目录 关键词 筛选 版本 最新 收件 自动扫描' },
  { id: 'reliability', label: '可靠性', icon: '⌁', keywords: '可靠性 删除 历史 日志' },
  { id: 'recovery', label: '自检与恢复', icon: '⌕', keywords: '自检 预检查 恢复 断点 暂停 优先级 剩余时间' },
  { id: 'developer', label: '项目工具', icon: '⌘', keywords: '项目 Claude BAT 工具' },
  { id: 'maintenance', label: '模板与维护', icon: '▤', keywords: '模板 导入 导出 维护 重置 配置' },
  { id: 'about', label: '说明与版本', icon: '▣', keywords: '说明 版本 关于 检查' },
];

const visibleTabs = computed(() => {
  const query = search.value.trim().toLocaleLowerCase();
  if (!query) return tabs;
  return tabs.filter((tab) => `${tab.label} ${tab.keywords}`.toLocaleLowerCase().includes(query));
});

function selectTab(tab: TabId): void {
  activeTab.value = tab;
}
</script>

<template>
  <div v-if="store.settingsOpen" class="drawer-backdrop" role="presentation" @mousedown.self="store.settingsOpen = false">
    <aside class="settings-drawer settings-drawer-v7" :class="{ compact: store.appSettings.settingsSidebarCompact }" role="dialog" aria-modal="true" aria-labelledby="settings-title">
      <header class="drawer-head">
        <div>
          <div class="settings-title-row"><h2 id="settings-title">总设置</h2><span class="version-chip">v{{ APP_VERSION }}</span></div>
          <p>自检、恢复、输出、界面与项目工具</p>
        </div>
        <button class="btn btn-ghost btn-sm" type="button" @click="store.settingsOpen = false">关闭</button>
      </header>

      <div class="settings-layout-v7">
        <aside class="settings-sidebar-v7">
          <label class="settings-search">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="11" cy="11" r="7" /><path d="M20 20l-4-4" /></svg>
            <input v-model="search" type="search" placeholder="搜索设置" />
          </label>
          <nav class="settings-nav-v7" aria-label="设置分类">
            <button v-for="tab in visibleTabs" :key="tab.id" type="button" :class="{ active: activeTab === tab.id }" :title="tab.label" @click="selectTab(tab.id)">
              <span class="settings-nav-icon">{{ tab.icon }}</span><span>{{ tab.label }}</span>
            </button>
          </nav>
          <div v-if="visibleTabs.length === 0" class="settings-nav-empty">没有匹配的设置</div>
          <footer class="settings-sidebar-footer">
            <label class="switch-row compact-switch"><span><b>紧凑侧栏</b></span><input v-model="store.appSettings.settingsSidebarCompact" type="checkbox" /></label>
            <span>解压台 v{{ APP_VERSION }}</span>
          </footer>
        </aside>

        <div class="settings-scroll settings-content-v7">
          <GeneralSettings v-if="activeTab === 'general'" />
          <AppearanceSettings v-else-if="activeTab === 'appearance'" />
          <BehaviorSettings v-else-if="activeTab === 'behavior'" />
          <OutputSettings v-else-if="activeTab === 'output'" />
          <InboxSettings v-else-if="activeTab === 'inbox'" />
          <ReliabilitySettings v-else-if="activeTab === 'reliability'" />
          <RecoverySettings v-else-if="activeTab === 'recovery'" />
          <DeveloperToolsSettings v-else-if="activeTab === 'developer'" />
          <MaintenanceSettings v-else-if="activeTab === 'maintenance'" />
          <AboutSettings v-else />
        </div>
      </div>
    </aside>
  </div>
</template>
