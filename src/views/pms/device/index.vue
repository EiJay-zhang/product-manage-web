<template>
  <div class="app-container">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="设备总数" :value="stats.total + ' 台'" type="primary" icon="Monitor" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="在线设备" :value="stats.online + ' 台'" type="success" icon="CircleCheck" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="离线设备" :value="stats.offline + ' 台'" type="danger" icon="CircleClose" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="待对账物流" :value="stats.uncheckedCount + ' 单'" type="info" icon="Document" />
      </el-col>
    </el-row>

    <el-alert v-if="stats.offline" class="mb8" type="error" show-icon :closable="false">
      <template #title>
        检测到 {{ stats.offline }} 台设备离线，请检查网络连接。
        <el-button class="ml10" size="small" type="danger" plain @click="filterOffline">查看详情</el-button>
      </template>
    </el-alert>

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch && (activeTab === 'devices' || activeTab === 'logs')">
      <el-form-item label="设备SN" prop="sn">
        <el-input v-model="queryParams.sn" placeholder="设备SN" clearable style="width: 180px" @keyup.enter="handleQuery" />
      </el-form-item>
      <el-form-item v-if="activeTab === 'devices'" label="在线状态" prop="onlineStatus">
        <el-select v-model="queryParams.onlineStatus" placeholder="全部状态" clearable style="width: 140px">
          <el-option v-for="dict in onlineOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="activeTab === 'logs'" label="同步状态" prop="syncStatus">
        <el-select v-model="queryParams.syncStatus" placeholder="全部" clearable style="width: 140px">
          <el-option v-for="dict in syncOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8" justify="space-between">
      <el-col :xs="24" :sm="12">
        <el-radio-group v-model="activeTab" @change="handleTabChange">
          <el-radio-button value="devices">设备列表</el-radio-button>
          <el-radio-button value="logs">同步日志</el-radio-button>
          <el-radio-button value="template">展示模板</el-radio-button>
          <el-radio-button value="simulator">设备模拟器</el-radio-button>
        </el-radio-group>
      </el-col>
      <el-col :xs="24" :sm="12" class="toolbar-right">
        <template v-if="activeTab === 'devices'">
          <el-button type="success" plain icon="Refresh" :disabled="multiple" @click="handleSync" v-hasPermi="['pms:device:operate']">批量同步</el-button>
          <el-button type="primary" plain icon="Plus" @click="handleBind" v-hasPermi="['pms:device:bind']">绑定设备</el-button>
        </template>
        <el-button v-if="activeTab === 'logs'" type="warning" plain icon="Download" @click="handleExportLog" v-hasPermi="['pms:device:export']">导出</el-button>
        <right-toolbar v-if="activeTab === 'devices' || activeTab === 'logs'" v-model:showSearch="showSearch" @queryTable="getList" />
      </el-col>
    </el-row>

    <el-table v-if="activeTab === 'devices'" v-loading="loading" :data="deviceList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="50" align="center" />
      <el-table-column label="设备SN" align="center" prop="sn" min-width="110">
        <template #default="scope"><span class="link-type">{{ scope.row.sn }}</span></template>
      </el-table-column>
      <el-table-column label="设备编号" align="center" prop="deviceCode" min-width="110" />
      <el-table-column label="绑定商品" min-width="150" :show-overflow-tooltip="true">
        <template #default="scope">{{ scope.row.productName || "未绑定" }}</template>
      </el-table-column>
      <el-table-column label="货架" align="center" prop="shelfNo" width="100" />
      <el-table-column label="在线状态" align="center" prop="onlineStatus" width="100">
        <template #default="scope">
          <dict-tag :options="onlineOptions" :value="scope.row.onlineStatus" />
        </template>
      </el-table-column>
      <el-table-column label="异常" align="center" prop="abnormalFlag" width="80">
        <template #default="scope">
          <el-tag :type="scope.row.abnormalFlag === '1' ? 'danger' : 'info'" size="small">{{ scope.row.abnormalFlag === '1' ? '异常' : '正常' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="电量" min-width="140">
        <template #default="scope">
          <div class="battery-cell">
            <el-progress :percentage="Number(scope.row.battery || 0)" :stroke-width="6" :show-text="false" :status="batteryStatus(scope.row.battery)" />
            <span>{{ scope.row.battery || 0 }}%</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="最后心跳" align="center" prop="lastHeartbeat" width="170">
        <template #default="scope">{{ parseTime(scope.row.lastHeartbeat) }}</template>
      </el-table-column>
      <el-table-column label="最后同步" align="center" prop="lastSyncTime" width="170">
        <template #default="scope">{{ parseTime(scope.row.lastSyncTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="280" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button link type="primary" icon="Refresh" @click="handleSync(scope.row)" v-hasPermi="['pms:device:operate']">刷新</el-button>
          <el-button link type="primary" icon="RefreshRight" @click="handleRestart(scope.row)" v-hasPermi="['pms:device:operate']">重启</el-button>
          <el-button link type="primary" icon="Warning" @click="handleMark(scope.row)" v-hasPermi="['pms:device:operate']">标记</el-button>
          <el-button link type="primary" icon="Monitor" @click="openSimulator(scope.row)">模拟</el-button>
          <el-button link type="primary" icon="Delete" @click="handleUnbind(scope.row)" v-hasPermi="['pms:device:unbind']">解绑</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-table v-else-if="activeTab === 'logs'" v-loading="loading" :data="logList">
      <el-table-column label="设备SN" align="center" prop="sn" min-width="120">
        <template #default="scope"><span class="link-type">{{ scope.row.sn }}</span></template>
      </el-table-column>
      <el-table-column label="同步内容" min-width="220" prop="syncContent" :show-overflow-tooltip="true" />
      <el-table-column label="指令" align="center" prop="commandType" width="110">
        <template #default="scope">{{ commandLabel(scope.row.commandType) }}</template>
      </el-table-column>
      <el-table-column label="同步时间" align="center" prop="createTime" width="170">
        <template #default="scope">{{ parseTime(scope.row.createTime) }}</template>
      </el-table-column>
      <el-table-column label="同步状态" align="center" prop="syncStatus" width="110">
        <template #default="scope">
          <dict-tag :options="syncOptions" :value="scope.row.syncStatus" />
        </template>
      </el-table-column>
    </el-table>

    <el-row v-else-if="activeTab === 'template'" :gutter="16" v-loading="loading">
      <el-col :xs="24" :lg="14">
        <el-card shadow="never">
          <template #header>价签展示模板</template>
          <el-form :model="template" label-width="110px">
            <el-form-item label="同步频率">
              <el-radio-group v-model="template.einkSyncIntervalSec">
                <el-radio-button :value="1">实时同步</el-radio-button>
                <el-radio-button :value="300">每5分钟</el-radio-button>
                <el-radio-button :value="900">每15分钟</el-radio-button>
                <el-radio-button :value="0">手动同步</el-radio-button>
              </el-radio-group>
              <div class="form-tip">选「手动同步」时，设备仍按约 5 秒拉取内容和待执行指令。</div>
            </el-form-item>
            <el-form-item label="字体样式">
              <el-select v-model="template.einkFontStyle" style="width: 220px">
                <el-option label="默认" value="default" />
                <el-option label="加粗" value="bold" />
                <el-option label="大号" value="large" />
              </el-select>
            </el-form-item>
            <el-form-item label="展示字段">
              <div class="switch-row">
                <span>名称</span>
                <el-switch v-model="template.showName" active-value="Y" inactive-value="N" />
                <span>规格</span>
                <el-switch v-model="template.showSpec" active-value="Y" inactive-value="N" />
                <span>售价</span>
                <el-switch v-model="template.showSalePrice" active-value="Y" inactive-value="N" />
                <span>简介</span>
                <el-switch v-model="template.showIntro" active-value="Y" inactive-value="N" />
                <span>库存</span>
                <el-switch v-model="template.showStock" active-value="Y" inactive-value="N" />
                <span>厂家</span>
                <el-switch v-model="template.showSupplier" active-value="Y" inactive-value="N" />
              </div>
            </el-form-item>
            <el-form-item label="预览商品">
              <el-select v-model="previewProductId" placeholder="用商品数据预览价签" filterable clearable style="width: 280px">
                <el-option v-for="item in productOptions" :key="item.productId" :label="item.productName" :value="item.productId" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" @click="submitTemplate" v-hasPermi="['pms:device:edit']">保存模板</el-button>
              <el-button @click="loadTemplate">重新加载</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="10">
        <el-card shadow="never">
          <template #header>价签预览</template>
          <price-tag :content="templatePreview" />
          <div class="form-tip block-tip">预览按当前开关即时变化。保存后，设备下次拉内容才会按此模板下发。</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row v-else :gutter="16">
      <el-col :xs="24" :lg="10">
        <el-card shadow="never">
          <template #header>模拟设备轮询</template>
          <el-form label-width="90px">
            <el-form-item label="设备SN">
              <el-input v-model="sim.sn" placeholder="如 ES-0050，未知 SN 会自动注册" maxlength="30" />
            </el-form-item>
            <el-form-item label="电量">
              <el-input-number v-model="sim.battery" :min="0" :max="100" controls-position="right" />
            </el-form-item>
            <el-form-item label="固件">
              <el-input v-model="sim.firmware" placeholder="1.0.0" maxlength="30" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="sim.busy" @click="runHeartbeat">上报心跳并拉价签</el-button>
              <el-button :loading="sim.busy" @click="pullContent">仅拉内容</el-button>
            </el-form-item>
          </el-form>
          <el-descriptions v-if="sim.heartbeat || sim.content" :column="1" border>
            <el-descriptions-item label="轮询间隔">{{ pending.pollIntervalSec ?? "—" }} 秒</el-descriptions-item>
            <el-descriptions-item label="待执行指令">{{ commandLabel(pending.command) }}</el-descriptions-item>
            <el-descriptions-item label="待确认日志">{{ pending.logId || "—" }}</el-descriptions-item>
            <el-descriptions-item label="在线状态">{{ sim.heartbeat?.data?.onlineStatus === "1" ? "在线" : (sim.heartbeat ? "已上报" : "—") }}</el-descriptions-item>
          </el-descriptions>
          <div v-if="pending.logId" class="sim-actions">
            <el-button type="success" plain :loading="sim.busy" @click="runAck('1')">回执成功</el-button>
            <el-button type="danger" plain :loading="sim.busy" @click="runAck('0')">回执失败</el-button>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="14">
        <el-card shadow="never">
          <template #header>设备屏幕</template>
          <price-tag v-if="sim.content" :content="sim.content" :sn="sim.content.sn || sim.sn" />
          <el-empty v-else description="上报心跳或拉取内容后，这里显示价签" />
        </el-card>
      </el-col>
    </el-row>

    <pagination v-show="total > 0 && (activeTab === 'devices' || activeTab === 'logs')" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog title="绑定设备" v-model="open" width="520px" append-to-body>
      <el-form ref="einkRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="设备SN" prop="sn">
          <el-input v-model="form.sn" placeholder="如 ES-0050" maxlength="30" />
        </el-form-item>
        <el-form-item label="绑定商品" prop="productId">
          <el-select v-model="form.productId" placeholder="请选择商品" filterable clearable style="width: 100%">
            <el-option v-for="item in productOptions" :key="item.productId" :label="item.productName" :value="item.productId" />
          </el-select>
        </el-form-item>
        <el-form-item label="货架位置" prop="shelfNo">
          <el-input v-model="form.shelfNo" placeholder="如 A区-01" maxlength="30" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitBind">确 定</el-button>
          <el-button @click="open = false">取 消</el-button>
        </div>
      </template>
    </el-dialog>

    <el-dialog title="标记异常" v-model="markOpen" width="480px" append-to-body>
      <el-form :model="markForm" label-width="90px">
        <el-form-item label="设备SN">
          <el-input :model-value="markForm.sn" disabled />
        </el-form-item>
        <el-form-item label="异常状态">
          <el-radio-group v-model="markForm.abnormalFlag">
            <el-radio value="1">异常</el-radio>
            <el-radio value="0">正常</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="markForm.abnormalRemark" type="textarea" placeholder="异常说明，可空" maxlength="200" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitMark">确 定</el-button>
        <el-button @click="markOpen = false">取 消</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="PmsDevice">
import StatCard from "@/components/StatCard"
import PriceTag from "./PriceTag.vue"
import { listDevice, bindDevice, unbindDevice, refreshDevice, restartDevice, batchRefreshDevice, listDeviceSyncLog, getDeviceTemplate, saveDeviceTemplate, markDevice, einkHeartbeat, einkContent, einkAck } from "@/api/pms/device"
import { optionProduct } from "@/api/pms/product"
import { getDashboard } from "@/api/pms/dashboard"
import { GOODS_EINK_ONLINE, GOODS_EINK_SYNC, useGoodsDict } from "@/utils/goodsDict"
import { useRoute } from "vue-router"

const { proxy } = getCurrentInstance()
const route = useRoute()
const onlineOptions = useGoodsDict("pms_online_status", GOODS_EINK_ONLINE)
const syncOptions = useGoodsDict("goods_eink_sync", GOODS_EINK_SYNC)

const activeTab = ref("devices")
const deviceList = ref([])
const logList = ref([])
const productOptions = ref([])
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const multiple = ref(true)
const total = ref(0)
const open = ref(false)
const markOpen = ref(false)
const markForm = ref({ deviceId: undefined, sn: "", abnormalFlag: "0", abnormalRemark: "" })
const template = ref({})
const previewProductId = ref()
const sim = reactive({ sn: "", battery: 80, firmware: "1.0.0", busy: false, heartbeat: null, content: null })
const stats = ref({ total: 0, online: 0, offline: 0, uncheckedCount: 0 })

const COMMAND_LABEL = { refresh: "刷新", restart: "重启", unbind: "解绑" }

const sampleProduct = computed(() => productOptions.value.find(item => item.productId === previewProductId.value) || productOptions.value[0] || {
  productName: "示例矿泉水",
  spec: "550ml",
  salePrice: 2.5,
  intro: "饮用天然水",
  stockQty: 36,
  supplierName: "示例厂家"
})

const templatePreview = computed(() => {
  const tpl = template.value || {}
  const product = sampleProduct.value
  const shown = (flag, fallback) => (flag == null || flag === "" ? fallback : flag) === "Y"
  return {
    empty: "N",
    fontStyle: tpl.einkFontStyle || "default",
    productName: shown(tpl.showName, "Y") ? product.productName : null,
    spec: shown(tpl.showSpec, "Y") ? product.spec : null,
    salePrice: shown(tpl.showSalePrice, "Y") ? product.salePrice : null,
    intro: shown(tpl.showIntro, "Y") ? product.intro : null,
    stockQty: shown(tpl.showStock, "N") ? product.stockQty : null,
    supplierName: shown(tpl.showSupplier, "N") ? product.supplierName : null
  }
})

const pending = computed(() => {
  const content = sim.content || {}
  const heartbeat = sim.heartbeat || {}
  return {
    command: content.pendingCommand ?? heartbeat.pendingCommand,
    logId: content.pendingLogId ?? heartbeat.pendingLogId,
    pollIntervalSec: content.pollIntervalSec ?? heartbeat.pollIntervalSec
  }
})

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    sn: undefined,
    onlineStatus: undefined,
    syncStatus: undefined
  },
  rules: {
    sn: [{ required: true, message: "设备SN不能为空", trigger: "blur" }],
    productId: [{ required: true, message: "请选择绑定商品", trigger: "change" }],
    shelfNo: [{ required: true, message: "请填写货架位置", trigger: "blur" }]
  }
})

const { queryParams, form, rules } = toRefs(data)

function commandLabel(value) {
  if (!value) return "无"
  return COMMAND_LABEL[value] || value
}

function normalizeInterval(sec) {
  const n = Number(sec)
  if ([0, 1, 300, 900].includes(n)) return n
  if (n > 0 && n < 60) return 1
  if (n >= 60 && n < 600) return 300
  if (n >= 600) return 900
  return 0
}

function batteryStatus(value) {
  const n = Number(value || 0)
  if (n > 50) return "success"
  if (n > 20) return "warning"
  return "exception"
}

function loadProducts() {
  optionProduct().then(res => { productOptions.value = res.data || [] }).catch(() => { productOptions.value = [] })
}

function loadStats() {
  Promise.all([
    listDevice({ pageNum: 1, pageSize: 1 }),
    listDevice({ pageNum: 1, pageSize: 1, onlineStatus: "1" }),
    getDashboard()
  ]).then(([allRes, onlineRes, dashRes]) => {
    const dash = dashRes.data || {}
    stats.value = {
      total: allRes.total || 0,
      online: onlineRes.total || 0,
      offline: dash.offlineDeviceCount || 0,
      uncheckedCount: dash.uncheckedCount || 0
    }
  }).catch(() => {})
}

function loadTemplate() {
  loading.value = true
  getDeviceTemplate().then(res => {
    const data = Object.assign({
      einkSyncIntervalSec: 0,
      einkFontStyle: "default",
      showName: "Y",
      showSpec: "Y",
      showSalePrice: "Y",
      showIntro: "Y",
      showStock: "N",
      showSupplier: "N"
    }, res.data || {})
    data.einkSyncIntervalSec = normalizeInterval(data.einkSyncIntervalSec)
    template.value = data
  }).finally(() => { loading.value = false })
}

function submitTemplate() {
  saveDeviceTemplate(template.value).then(() => {
    proxy.$modal.msgSuccess("模板已保存")
    loadTemplate()
  })
}

function getList() {
  if (activeTab.value === "template") {
    loadTemplate()
    return
  }
  if (activeTab.value === "simulator") return
  loading.value = true
  const request = activeTab.value === "devices" ? listDevice : listDeviceSyncLog
  request(queryParams.value).then(res => {
    if (activeTab.value === "devices") {
      deviceList.value = res.rows || []
    } else {
      logList.value = res.rows || []
    }
    total.value = res.total || 0
  }).finally(() => {
    loading.value = false
  })
}

function handleTabChange() {
  queryParams.value.pageNum = 1
  getList()
}

function handleQuery() {
  queryParams.value.pageNum = 1
  getList()
}

function resetQuery() {
  proxy.resetForm("queryRef")
  handleQuery()
}

function filterOffline() {
  activeTab.value = "devices"
  queryParams.value.onlineStatus = "0"
  queryParams.value.pageNum = 1
  getList()
}

function handleSelectionChange(selection) {
  ids.value = selection.map(item => item.deviceId)
  multiple.value = !selection.length
}

function handleBind() {
  form.value = { sn: undefined, productId: undefined, shelfNo: undefined }
  proxy.resetForm("einkRef")
  open.value = true
}

function submitBind() {
  proxy.$refs["einkRef"].validate(valid => {
    if (!valid) return
    bindDevice(form.value).then(() => {
      proxy.$modal.msgSuccess("绑定成功")
      open.value = false
      getList()
      loadStats()
      loadProducts()
    })
  })
}

function handleSync(row) {
  if (row?.deviceId) {
    refreshDevice(row.deviceId).then(res => {
      proxy.$modal.msgSuccess(res.msg || "同步完成")
      getList()
      loadStats()
    })
    return
  }
  if (!ids.value.length) {
    proxy.$modal.msgWarning("请选择要同步的设备")
    return
  }
  batchRefreshDevice({ deviceIds: ids.value }).then(res => {
    proxy.$modal.msgSuccess(res.msg || "同步完成")
    getList()
    loadStats()
  })
}

function handleRestart(row) {
  proxy.$modal.confirm("确认远程重启设备 " + row.sn + " ？").then(function () {
    return restartDevice(row.deviceId)
  }).then(res => {
    proxy.$modal.msgSuccess(res.msg || "已发送重启指令")
    getList()
    loadStats()
  }).catch(() => {})
}

function handleExportLog() {
  proxy.download("pms/device/syncLog/export", {
    sn: queryParams.value.sn,
    syncStatus: queryParams.value.syncStatus
  }, `device_sync_log_${new Date().getTime()}.xlsx`)
}

function handleMark(row) {
  markForm.value = {
    deviceId: row.deviceId,
    sn: row.sn,
    abnormalFlag: row.abnormalFlag === "1" ? "1" : "0",
    abnormalRemark: row.abnormalRemark || ""
  }
  markOpen.value = true
}

function submitMark() {
  markDevice(markForm.value.deviceId, {
    abnormalFlag: markForm.value.abnormalFlag,
    abnormalRemark: markForm.value.abnormalRemark
  }).then(() => {
    proxy.$modal.msgSuccess("已更新异常标记")
    markOpen.value = false
    getList()
  })
}

function openSimulator(row) {
  if (row?.sn) sim.sn = row.sn
  if (row?.battery != null) sim.battery = Number(row.battery)
  if (row?.firmware) sim.firmware = row.firmware
  sim.heartbeat = null
  sim.content = null
  activeTab.value = "simulator"
}

function pullContent() {
  const sn = (sim.sn || "").trim()
  if (!sn) {
    proxy.$modal.msgWarning("请填写设备SN")
    return Promise.resolve()
  }
  sim.busy = true
  return einkContent(sn).then(res => {
    sim.content = res.data || {}
  }).finally(() => { sim.busy = false })
}

function runHeartbeat() {
  const sn = (sim.sn || "").trim()
  if (!sn) {
    proxy.$modal.msgWarning("请填写设备SN")
    return
  }
  sim.busy = true
  einkHeartbeat({ sn, battery: sim.battery, firmware: sim.firmware }).then(res => {
    sim.heartbeat = res
    return einkContent(sn)
  }).then(res => {
    if (!res) return
    sim.content = res.data || {}
    proxy.$modal.msgSuccess("心跳已上报，价签已更新")
    loadStats()
  }).finally(() => { sim.busy = false })
}

function runAck(syncStatus) {
  if (!pending.value.logId && !sim.sn) return
  sim.busy = true
  const payload = pending.value.logId
    ? { logId: pending.value.logId, syncStatus, remark: syncStatus === "1" ? "ok" : "fail" }
    : { sn: sim.sn.trim(), syncStatus, remark: syncStatus === "1" ? "ok" : "fail" }
  einkAck(payload).then(() => {
    proxy.$modal.msgSuccess(syncStatus === "1" ? "已回执成功" : "已回执失败")
    return einkContent(sim.sn.trim())
  }).then(res => {
    if (res) sim.content = res.data || {}
    if (sim.heartbeat) {
      sim.heartbeat.pendingCommand = sim.content?.pendingCommand
      sim.heartbeat.pendingLogId = sim.content?.pendingLogId
    }
  }).finally(() => { sim.busy = false })
}

function handleUnbind(row) {
  proxy.$modal.confirm("确认解绑设备 " + row.sn + " ？解绑后将清除商品绑定。").then(function () {
    return unbindDevice(row.deviceId)
  }).then(() => {
    proxy.$modal.msgSuccess("已解绑")
    getList()
    loadStats()
    loadProducts()
  }).catch(() => {})
}

if (route.query.onlineStatus) queryParams.value.onlineStatus = String(route.query.onlineStatus)
loadProducts()
getList()
loadStats()
</script>

<style scoped>
.toolbar-right {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.battery-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}
.battery-cell .el-progress {
  flex: 1;
}
.battery-cell span {
  width: 40px;
  text-align: right;
  font-size: 12px;
  color: var(--el-text-color-secondary);
}
.goods-stat-row {
  margin-bottom: 16px;
}
.goods-stat-row :deep(.el-col) {
  margin-bottom: 12px;
}
.form-tip {
  color: var(--el-text-color-secondary);
  font-size: 12px;
}
.block-tip {
  margin-top: 12px;
}
.switch-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px 16px;
}
.sim-actions {
  margin-top: 12px;
  display: flex;
  gap: 8px;
}
</style>
