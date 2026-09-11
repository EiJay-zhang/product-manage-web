<template>
  <div class="app-container" v-loading="loading">
    <el-row :gutter="16">
      <el-col :xs="24" :lg="12">
        <el-card shadow="never" class="mb16">
          <template #header>库存与营收预警</template>
          <el-form ref="settingRef" :model="form" :rules="rules" label-width="120px">
            <el-form-item label="库存预警阈值" prop="stockWarnThreshold">
              <el-input-number v-model="form.stockWarnThreshold" :min="0" :precision="0" controls-position="right" />
              <span class="form-tip">库存低于该数量时标记为预警</span>
            </el-form-item>
            <el-form-item label="营收下限" prop="turnoverWarnMin">
              <el-input-number v-model="form.turnoverWarnMin" :min="0" :precision="2" controls-position="right" />
            </el-form-item>
            <el-form-item label="营收上限" prop="turnoverWarnMax">
              <el-input-number v-model="form.turnoverWarnMax" :min="0" :precision="2" controls-position="right" />
              <span class="form-tip">看板按该区间提示营收异常</span>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="12">
        <el-card shadow="never" class="mb16">
          <template #header>墨水屏展示</template>
          <el-form :model="form" label-width="120px">
            <el-form-item label="同步频率">
              <el-radio-group v-model="form.einkSyncIntervalSec">
                <el-radio-button :value="1">实时同步</el-radio-button>
                <el-radio-button :value="300">每5分钟</el-radio-button>
                <el-radio-button :value="900">每15分钟</el-radio-button>
                <el-radio-button :value="0">手动同步</el-radio-button>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="字体样式" prop="einkFontStyle">
              <el-select v-model="form.einkFontStyle" style="width: 220px">
                <el-option label="默认" value="default" />
                <el-option label="加粗" value="bold" />
                <el-option label="大号" value="large" />
              </el-select>
            </el-form-item>
            <el-form-item label="必选字段">
              <div class="switch-row">
                <span>商品名称</span>
                <el-switch model-value="Y" active-value="Y" inactive-value="N" disabled />
                <span>规格</span>
                <el-switch model-value="Y" active-value="Y" inactive-value="N" disabled />
                <span>售价</span>
                <el-switch model-value="Y" active-value="Y" inactive-value="N" disabled />
              </div>
            </el-form-item>
            <el-form-item label="可选字段">
              <div class="switch-row">
                <span>简介</span>
                <el-switch v-model="form.showIntro" active-value="Y" inactive-value="N" />
                <span>库存</span>
                <el-switch v-model="form.showStock" active-value="Y" inactive-value="N" />
                <span>厂家</span>
                <el-switch v-model="form.showSupplier" active-value="Y" inactive-value="N" />
              </div>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
    </el-row>

    <div class="toolbar">
      <el-button type="primary" @click="submitForm" v-hasPermi="['pms:setting:edit']">保存设置</el-button>
      <el-button @click="loadSetting">重新加载</el-button>
    </div>

    <el-card shadow="never">
      <template #header>
        <div class="card-head">
          <span>操作日志</span>
          <span class="form-tip">来自系统操作记录，筛选商品进销存相关模块</span>
        </div>
      </template>
      <el-table :data="operList" empty-text="暂无操作记录或无日志权限">
        <el-table-column label="模块" prop="title" min-width="140" />
        <el-table-column label="类型" prop="businessType" width="90" align="center">
          <template #default="scope">
            <dict-tag :options="sys_oper_type" :value="scope.row.businessType" />
          </template>
        </el-table-column>
        <el-table-column label="操作人" prop="operName" width="110" />
        <el-table-column label="状态" prop="status" width="80" align="center">
          <template #default="scope">
            <el-tag :type="scope.row.status === 0 ? 'success' : 'danger'" size="small">{{ scope.row.status === 0 ? '成功' : '失败' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="时间" prop="operTime" width="170" align="center">
          <template #default="scope">{{ parseTime(scope.row.operTime) }}</template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup name="PmsSetting">
import { getSetting, updateSetting } from "@/api/pms/setting"
import { list as listOperlog } from "@/api/monitor/operlog"

const { proxy } = getCurrentInstance()
const { sys_oper_type } = useDict("sys_oper_type")
const loading = ref(false)
const operList = ref([])
const data = reactive({
  form: {},
  rules: {
    stockWarnThreshold: [{ required: true, message: "请填写库存预警阈值", trigger: "blur" }]
  }
})
const { form, rules } = toRefs(data)

const defaults = {
  stockWarnThreshold: 5,
  turnoverWarnMin: 0,
  turnoverWarnMax: 0,
  einkSyncIntervalSec: 0,
  einkFontStyle: "default",
  showName: "Y",
  showSpec: "Y",
  showSalePrice: "Y",
  showIntro: "Y",
  showStock: "N",
  showSupplier: "N"
}

function normalizeInterval(sec) {
  const n = Number(sec)
  if ([0, 1, 300, 900].includes(n)) return n
  if (n > 0 && n < 60) return 1
  if (n >= 60 && n < 600) return 300
  if (n >= 600) return 900
  return 0
}

function loadSetting() {
  loading.value = true
  getSetting().then(res => {
    form.value = Object.assign({}, defaults, res.data || {})
    form.value.einkSyncIntervalSec = normalizeInterval(form.value.einkSyncIntervalSec)
    form.value.showName = "Y"
    form.value.showSpec = "Y"
    form.value.showSalePrice = "Y"
  }).finally(() => { loading.value = false })
}

const PMS_LOG_TITLES = ["商品信息", "商品分类", "供应商", "进货", "库存", "销售出库", "销售退货", "物流对账", "物流商", "墨水屏", "报表", "业务设置"]

function loadOperlog() {
  listOperlog({ pageNum: 1, pageSize: 50 }).then(res => {
    const rows = res.rows || []
    operList.value = rows.filter(row => PMS_LOG_TITLES.some(title => (row.title || "").includes(title))).slice(0, 8)
  }).catch(() => { operList.value = [] })
}

function submitForm() {
  proxy.$refs["settingRef"].validate(valid => {
    if (!valid) return
    const payload = Object.assign({}, form.value, {
      showName: "Y",
      showSpec: "Y",
      showSalePrice: "Y"
    })
    updateSetting(payload).then(() => {
      proxy.$modal.msgSuccess("保存成功")
      loadSetting()
      loadOperlog()
    })
  })
}

loadSetting()
loadOperlog()
</script>

<style scoped>
.mb16 { margin-bottom: 16px; }
.form-tip {
  margin-left: 12px;
  color: var(--el-text-color-secondary);
  font-size: 12px;
}
.switch-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px 16px;
}
.toolbar { margin: 0 0 16px; }
.card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
</style>
