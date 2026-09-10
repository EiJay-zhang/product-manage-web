<template>
  <div class="stat-card" :class="'is-' + type">
    <div class="stat-card__icon">
      <el-icon :size="22"><component :is="icon" /></el-icon>
    </div>
    <div class="stat-card__body">
      <div class="stat-card__label">{{ label }}</div>
      <div class="stat-card__value">{{ value }}</div>
      <div v-if="extra" class="stat-card__extra">{{ extra }}</div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  label: {
    type: String,
    default: ""
  },
  value: {
    type: [String, Number],
    default: "-"
  },
  type: {
    type: String,
    default: "primary"
  },
  icon: {
    type: String,
    default: "Goods"
  },
  extra: {
    type: String,
    default: ""
  }
})
</script>

<style lang="scss" scoped>
.stat-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 8px;
  border: 1px solid var(--el-border-color-light);
  background: var(--el-fill-color-blank);
}

.stat-card__icon {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-card__label {
  font-size: 12px;
  color: var(--el-text-color-secondary);
  margin-bottom: 4px;
}

.stat-card__value {
  font-size: 20px;
  font-weight: 700;
  line-height: 1.2;
  color: var(--el-text-color-primary);
}
.stat-card__extra {
  margin-top: 4px;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}

.stat-card.is-primary {
  background: var(--el-color-primary-light-9);
  border-color: var(--el-color-primary-light-7);
  .stat-card__icon { background: var(--el-color-primary-light-7); color: var(--el-color-primary); }
  .stat-card__value { color: var(--el-color-primary); }
}
.stat-card.is-success {
  background: var(--el-color-success-light-9);
  border-color: var(--el-color-success-light-7);
  .stat-card__icon { background: var(--el-color-success-light-7); color: var(--el-color-success); }
  .stat-card__value { color: var(--el-color-success); }
}
.stat-card.is-warning {
  background: var(--el-color-warning-light-9);
  border-color: var(--el-color-warning-light-7);
  .stat-card__icon { background: var(--el-color-warning-light-7); color: var(--el-color-warning); }
  .stat-card__value { color: var(--el-color-warning); }
}
.stat-card.is-danger {
  background: var(--el-color-danger-light-9);
  border-color: var(--el-color-danger-light-7);
  .stat-card__icon { background: var(--el-color-danger-light-7); color: var(--el-color-danger); }
  .stat-card__value { color: var(--el-color-danger); }
}
.stat-card.is-info {
  background: var(--el-color-info-light-9);
  border-color: var(--el-color-info-light-7);
  .stat-card__icon { background: var(--el-color-info-light-7); color: var(--el-color-info); }
  .stat-card__value { color: var(--el-color-info); }
}
</style>
