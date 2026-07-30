<script setup lang="ts">
import { useChannelStore } from '../../stores/channels';
import { useTaskCenterStore } from '../../stores/taskCenter';

const store = useChannelStore();
const tasks = useTaskCenterStore();
</script>

<template>
  <section class="settings-section settings-two-column">
    <div class="settings-panel">
      <h3>任务中心</h3>
      <label class="settings-field">
        <span>任务历史保留数量</span>
        <input v-model.number="store.appSettings.taskHistoryRetention" class="option-input" type="number" min="50" max="5000" step="50" />
      </label>
      <label class="switch-row">
        <span><b>失败时自动打开任务中心</b><small>第一时间查看错误、耗时与输出清单</small></span>
        <input v-model="store.appSettings.autoOpenTaskCenterOnFailure" type="checkbox" />
      </label>
      <div class="maintenance-actions">
        <button class="btn btn-primary" type="button" @click="tasks.drawerOpen = true">打开任务中心</button>
        <button class="btn" type="button" :disabled="tasks.activeCount > 0" @click="tasks.clearCompleted">清理已结束记录</button>
        <button class="btn btn-ghost" type="button" :disabled="tasks.records.length === 0" @click="tasks.clearAll">清空全部历史</button>
      </div>
    </div>

    <div class="settings-panel">
      <h3>解压结果删除</h3>
      <label class="switch-row">
        <span><b>删除前确认</b><small>删除按钮会先展示本次写入与替换文件数量</small></span>
        <input v-model="store.appSettings.confirmBeforeDeleteOutput" type="checkbox" />
      </label>
      <label class="switch-row danger-setting">
        <span><b>同时删除曾被替换的文件</b><small>关闭时只删除本次新增文件；建议保持关闭</small></span>
        <input v-model="store.appSettings.deleteReplacedOutputs" type="checkbox" />
      </label>
      <div class="reliability-note">
        <b>安全删除原理</b>
        <p>每次成功解压都会在应用数据目录写入独立清单。删除操作只读取该清单，不会直接清空整个目标目录；本次覆盖过旧内容的文件默认保留。</p>
      </div>
    </div>
  </section>

  <section class="settings-section">
    <div class="settings-section-head">
      <div>
        <h3>可靠性策略</h3>
        <p>适合大批量或重要项目目录的保护选项。</p>
      </div>
    </div>
    <div class="settings-three-column">
      <label class="switch-row"><span><b>覆盖前确认</b><small>批次启动前确认所有覆盖型通道</small></span><input v-model="store.appSettings.confirmBeforeOverwrite" type="checkbox" /></label>
      <label class="switch-row"><span><b>错误时展开通道</b><small>直接显示路径、密码和层级设置</small></span><input v-model="store.appSettings.autoExpandOnError" type="checkbox" /></label>
      <label class="switch-row"><span><b>保留空目录</b><small>新通道默认保留归档内空文件夹</small></span><input v-model="store.appSettings.defaultKeepEmptyDirectories" type="checkbox" /></label>
    </div>
  </section>
</template>
