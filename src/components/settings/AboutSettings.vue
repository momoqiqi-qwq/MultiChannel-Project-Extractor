<script setup lang="ts">
import { APP_NAME, APP_VERSION, CONFIG_SCHEMA_VERSION } from '../../config/version';
import { useChannelStore } from '../../stores/channels';

const store = useChannelStore();
const featureChecks = [
  ['断点恢复', '中断任务保存无密码快照，并可一键恢复'],
  ['开始前预检查', '源文件、输出目录、密码提示、冲突和空间'],
  ['树形输出预览', '提交前展示每个任务的最终输出根目录'],
  ['暂停与继续', '内置解压流程支持协作式暂停'],
  ['文件优先级', '高、普通、低三级队列优先级'],
  ['模板导入导出', '通道预设可单独备份与分享'],
  ['剩余时间估算', '任务中心根据进度动态显示 ETA'],
  ['背景焦点', '可用横纵坐标精确调整背景主体位置'],
];
</script>

<template>
  <section class="settings-section about-hero">
    <div class="about-mark" aria-hidden="true"><span /><span /><span /></div>
    <div>
      <h3>{{ APP_NAME }} {{ APP_VERSION }}</h3>
      <p>多通道批量解压、任务恢复与输出预判工作台。</p>
      <div class="about-version-row">
        <span>应用版本 <b>{{ APP_VERSION }}</b></span>
        <span>配置架构 <b>v{{ CONFIG_SCHEMA_VERSION }}</b></span>
        <span>Tauri 2 + Rust + Vue 3</span>
      </div>
    </div>
  </section>

  <section class="settings-section">
    <div class="settings-section-head"><div><h3>0.7.0 功能检查</h3><p>本版本目标逐项对应实现状态。</p></div></div>
    <div class="feature-check-grid">
      <div v-for="item in featureChecks" :key="item[0]" class="feature-check-item">
        <span class="feature-check-icon">✓</span>
        <span><b>{{ item[0] }}</b><small>{{ item[1] }}</small></span>
      </div>
    </div>
  </section>

  <section class="settings-section settings-two-column">
    <div class="settings-panel">
      <h3>当前工作区</h3>
      <div class="settings-info-grid compact-info-grid">
        <span><b>通道</b>{{ store.channels.length }}</span>
        <span><b>文件</b>{{ store.totalFiles }}</span>
        <span><b>完成</b>{{ store.completedFiles }}</span>
        <span><b>失败</b>{{ store.failedFiles }}</span>
      </div>
    </div>
    <div class="settings-panel">
      <h3>兼容性说明</h3>
      <p class="settings-paragraph">ZIP、7Z、TAR 系列和单文件流由内置 Rust 解压器处理；RAR 依赖系统中的 unrar、7z 或 7zz。外部进程运行期间暂停响应受工具本身限制。</p>
    </div>
  </section>
</template>
