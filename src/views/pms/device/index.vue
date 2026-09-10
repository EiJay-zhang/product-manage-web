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

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
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
        </el-radio-group>
      </el-col>
      <el-col :xs="24" :sm="12" class="toolbar-right">
        <template v-if="activeTab === 'devices'">
          <el-button type="success" plain icon="Refresh" :disabled="multiple" @click="handleSync" v-hasPermi="['pms:device:operate']">批量同步</el-button>
          <el-button type="primary" plain icon="Plus" @click="handleBind" v-hasPermi="['pms:device:bind']">绑定设备</el-button>
        </template>
        <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
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
      <el-table-column label="电量" min-width="140">
        <template #default="scope">
          <div class="battery-cell">
            <el-progress :percentage="Number(scope.row.battery || 0)" :stroke-width="6" :show-text="false" :status="batteryStatus(scope.row.battery)" />
            <span>{{ scope.row.battery || 0 }}%</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="最后同步" align="center" prop="lastSyncTime" width="170">
        <template #default="scope">{{ parseTime(scope.row.lastSyncTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="200" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button link type="primary" icon="Refresh" @click="handleSync(scope.row)" v-hasPermi="['pms:device:operate']">刷新</el-button>
          <el-button link type="primary" icon="RefreshRight" @click="handleRestart(scope.row)" v-hasPermi="['pms:device:operate']">重启</el-button>
          <el-button link type="primary" icon="Delete" @click="handleUnbind(scope.row)" v-hasPermi="['pms:device:unbind']">解绑</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-table v-else v-loading="loading" :data="logList">
      <el-table-column label="设备SN" align="center" prop="sn" min-width="120">
        <template #default="scope"><span class="link-type">{{ scope.row.sn }}</span></template>
      </el-table-column>
      <el-table-column label="同步内容" min-width="220" prop="syncContent" :show-overflow-tooltip="true" />
      <el-table-column label="指令" align="center" prop="commandType" width="110" />
      <el-table-column label="同步时间" align="center" prop="createTime" width="170">
        <template #default="scope">{{ parseTime(scope.row.createTime) }}</template>
      </el-table-column>
      <el-table-column label="同步状态" align="center" prop="syncStatus" width="110">
        <template #default="scope">
          <dict-tag :options="syncOptions" :value="scope.row.syncStatus" />
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

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
  </div>
</template>

<script setup name="PmsDevice">
import StatCard from "@/components/StatCard"
import { listDevice, bindDevice, unbindDevice, refreshDevice, restartDevice, batchRefreshDevice, listDeviceSyncLog } from "@/api/pms/device"
import { optionProduct } from "@/api/pms/product"
import { getDashboard } from "@/api/pms/dashboard"
import { GOODS_EINK_ONLINE, GOODS_EINK_SYNC, useGoodsDict } from "@/utils/goodsDict"

const { proxy } = getCurrentInstance()
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
const stats = ref({ total: 0, online: 0, offline: 0, uncheckedCount: 0 })

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

function getList() {
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
</style>
