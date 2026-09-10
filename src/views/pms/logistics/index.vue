<template>
  <div class="app-container">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="本月物流总费用" :value="formatAmount(stats.totalFee)" type="primary" icon="Van" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="已结清金额" :value="formatAmount(stats.settledFee)" type="success" icon="CircleCheck" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="待对账金额" :value="formatAmount(stats.unsettledFee)" type="warning" icon="Clock" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="待对账单数" :value="stats.pendingCount + ' 条'" type="danger" icon="Document" />
      </el-col>
    </el-row>

    <el-alert v-if="stats.pendingCount" class="mb8" type="warning" show-icon :closable="false">
      <template #title>
        当前有 {{ stats.pendingCount }} 条物流账单待对账，请及时处理，避免账期延误。
        <el-button class="ml10" size="small" @click="filterPending">查看未对账</el-button>
      </template>
    </el-alert>

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch && activeTab === 'bills'">
      <el-form-item label="物流单号" prop="logisticsNo">
        <el-input v-model="queryParams.logisticsNo" placeholder="物流单号" clearable style="width: 180px" @keyup.enter="handleQuery" />
      </el-form-item>
      <el-form-item label="对账状态" prop="payStatus">
        <el-select v-model="queryParams.payStatus" placeholder="全部状态" clearable style="width: 140px">
          <el-option v-for="dict in statusOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="物流商" prop="carrier">
        <el-select v-model="queryParams.carrier" placeholder="全部物流商" clearable style="width: 160px">
          <el-option v-for="dict in carrierOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
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
          <el-radio-button value="bills">物流账单</el-radio-button>
          <el-radio-button value="stats">费用统计</el-radio-button>
        </el-radio-group>
      </el-col>
      <el-col :xs="24" :sm="12" class="toolbar-right">
        <template v-if="activeTab === 'bills'">
          <el-button type="success" plain icon="Finished" :disabled="multiple" @click="handleReconcile()" v-hasPermi="['pms:logistics:edit']">批量对账</el-button>
          <el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:logistics:export']">导出</el-button>
          <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['pms:logistics:add']">新增物流单</el-button>
        </template>
        <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
      </el-col>
    </el-row>

    <el-table v-if="activeTab === 'bills'" v-loading="loading" :data="billList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="50" align="center" />
      <el-table-column label="物流单号" align="center" prop="logisticsNo" min-width="130">
        <template #default="scope"><span class="link-type" @click="handleView(scope.row)">{{ scope.row.logisticsNo }}</span></template>
      </el-table-column>
      <el-table-column label="关联进货单" align="center" prop="purchaseNo" min-width="140">
        <template #default="scope">{{ scope.row.purchaseNo || "—" }}</template>
      </el-table-column>
      <el-table-column label="商品" min-width="140" prop="productName" :show-overflow-tooltip="true" />
      <el-table-column label="供货厂家" min-width="120" prop="supplierName" :show-overflow-tooltip="true" />
      <el-table-column label="物流商" align="center" width="100">
        <template #default="scope">{{ dictLabel(carrierOptions, scope.row.carrier) || scope.row.carrier }}</template>
      </el-table-column>
      <el-table-column label="发货" align="center" prop="shipTime" width="160">
        <template #default="scope">{{ parseTime(scope.row.shipTime) }}</template>
      </el-table-column>
      <el-table-column label="到货" align="center" prop="arriveTime" width="160">
        <template #default="scope">{{ parseTime(scope.row.arriveTime) }}</template>
      </el-table-column>
      <el-table-column label="运费" align="center" width="80">
        <template #default="scope">¥{{ scope.row.freight }}</template>
      </el-table-column>
      <el-table-column label="保价" align="center" width="80">
        <template #default="scope">¥{{ scope.row.insuranceFee }}</template>
      </el-table-column>
      <el-table-column label="杂费" align="center" width="80">
        <template #default="scope">¥{{ scope.row.otherFee }}</template>
      </el-table-column>
      <el-table-column label="合计" align="center" width="90">
        <template #default="scope"><span class="amount-ok">¥{{ scope.row.totalFee }}</span></template>
      </el-table-column>
      <el-table-column label="状态" align="center" prop="payStatus" width="90">
        <template #default="scope">
          <dict-tag :options="statusOptions" :value="scope.row.payStatus" />
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="140" class-name="small-padding fixed-width" fixed="right">
        <template #default="scope">
          <el-button v-if="scope.row.payStatus === '0'" link type="primary" @click="handleReconcile(scope.row)" v-hasPermi="['pms:logistics:edit']">对账</el-button>
          <el-button v-else-if="scope.row.payStatus === '1'" link type="primary" @click="handleSettle(scope.row)" v-hasPermi="['pms:logistics:edit']">结清</el-button>
          <el-button link type="primary" icon="View" @click="handleView(scope.row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <div v-else class="carrier-grid">
      <div v-for="item in carriers" :key="item.name" class="carrier-card">
        <div class="carrier-card__head">
          <span>{{ dictLabel(carrierOptions, item.name) || item.name }}</span>
          <el-tag size="small">{{ item.billCount || 0 }} 单</el-tag>
        </div>
        <div class="carrier-card__amount">{{ formatAmount(item.totalFee) }}</div>
        <el-progress :percentage="carrierPercent(item.totalFee)" :stroke-width="6" :show-text="false" />
      </div>
    </div>

    <pagination v-if="activeTab === 'bills'" v-show="total > 0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog title="新增物流单" v-model="open" width="640px" append-to-body>
      <el-form ref="logisticsRef" :model="form" :rules="rules" label-width="90px">
        <el-row>
          <el-col :span="12">
            <el-form-item label="物流单号" prop="logisticsNo">
              <el-input v-model="form.logisticsNo" placeholder="物流运单号" maxlength="40" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="关联进货" prop="purchaseId">
              <el-select v-model="form.purchaseId" placeholder="请选择进货单" filterable style="width: 100%" @change="onPurchaseChange">
                <el-option v-for="item in purchaseOptions" :key="item.purchaseId" :label="item.purchaseNo + ' · ' + item.productName" :value="item.purchaseId" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="商品">
              <el-input :model-value="selectedPurchase.productName" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="供货厂家">
              <el-input :model-value="selectedPurchase.supplierName" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="物流商" prop="carrier">
              <el-select v-model="form.carrier" placeholder="请选择物流商" style="width: 100%">
                <el-option v-for="dict in carrierOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="发货时间" prop="shipTime">
              <el-date-picker v-model="form.shipTime" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" placeholder="发货时间" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="到货时间" prop="arriveTime">
              <el-date-picker v-model="form.arriveTime" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" placeholder="到货时间" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="运费" prop="freight">
              <el-input-number v-model="form.freight" :min="0" :precision="2" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="保价" prop="insuranceFee">
              <el-input-number v-model="form.insuranceFee" :min="0" :precision="2" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="杂费" prop="otherFee">
              <el-input-number v-model="form.otherFee" :min="0" :precision="2" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="合计">
              <el-input :model-value="formatAmount(formTotal)" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注" prop="remark">
              <el-input v-model="form.remark" type="textarea" placeholder="选填" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitForm">确 定</el-button>
          <el-button @click="open = false">取 消</el-button>
        </div>
      </template>
    </el-dialog>

    <el-dialog title="物流详情" v-model="viewOpen" width="640px" append-to-body>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="物流单号">{{ viewForm.logisticsNo }}</el-descriptions-item>
        <el-descriptions-item label="关联进货单">{{ viewForm.purchaseNo || "—" }}</el-descriptions-item>
        <el-descriptions-item label="商品">{{ viewForm.productName }}</el-descriptions-item>
        <el-descriptions-item label="供货厂家">{{ viewForm.supplierName }}</el-descriptions-item>
        <el-descriptions-item label="物流商">{{ dictLabel(carrierOptions, viewForm.carrier) || viewForm.carrier }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <dict-tag :options="statusOptions" :value="viewForm.payStatus" />
        </el-descriptions-item>
        <el-descriptions-item label="发货时间">{{ parseTime(viewForm.shipTime) }}</el-descriptions-item>
        <el-descriptions-item label="到货时间">{{ parseTime(viewForm.arriveTime) }}</el-descriptions-item>
        <el-descriptions-item label="运费">¥{{ viewForm.freight }}</el-descriptions-item>
        <el-descriptions-item label="保价">¥{{ viewForm.insuranceFee }}</el-descriptions-item>
        <el-descriptions-item label="杂费">¥{{ viewForm.otherFee }}</el-descriptions-item>
        <el-descriptions-item label="合计">{{ formatAmount(viewForm.totalFee) }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewForm.remark || "—" }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <div class="dialog-footer">
          <el-button v-if="viewForm.payStatus === '0'" type="primary" @click="handleReconcile(viewForm)" v-hasPermi="['pms:logistics:edit']">对账</el-button>
          <el-button v-if="viewForm.payStatus === '1'" type="success" @click="handleSettle(viewForm)" v-hasPermi="['pms:logistics:edit']">结清</el-button>
          <el-button v-if="viewForm.payStatus === '0'" type="danger" plain @click="handleAbnormal(viewForm)" v-hasPermi="['pms:logistics:edit']">标记异常</el-button>
          <el-button @click="viewOpen = false">关 闭</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="PmsLogistics">
import StatCard from "@/components/StatCard"
import { listLogistics, getLogistics, addLogistics, updateLogisticsStatus, markLogistics, batchReconcileLogistics, getLogisticsMonthly, getLogisticsCarrier } from "@/api/pms/logistics"
import { listPurchase } from "@/api/pms/purchase"
import { getDashboard } from "@/api/pms/dashboard"
import { GOODS_LOGISTICS_STATUS, GOODS_CARRIER, useGoodsDict, dictLabel } from "@/utils/goodsDict"

const { proxy } = getCurrentInstance()
const statusOptions = useGoodsDict("pms_pay_status", GOODS_LOGISTICS_STATUS)
const carrierOptions = useGoodsDict("goods_carrier", GOODS_CARRIER)

const activeTab = ref("bills")
const billList = ref([])
const purchaseOptions = ref([])
const carriers = ref([])
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const multiple = ref(true)
const total = ref(0)
const open = ref(false)
const viewOpen = ref(false)
const viewForm = ref({})
const stats = ref({ totalFee: 0, settledFee: 0, unsettledFee: 0, pendingCount: 0 })

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    logisticsNo: undefined,
    payStatus: undefined,
    carrier: undefined
  },
  rules: {
    logisticsNo: [{ required: true, message: "请填写物流单号", trigger: "blur" }],
    purchaseId: [{ required: true, message: "请关联进货批次", trigger: "change" }],
    carrier: [{ required: true, message: "请选择物流商", trigger: "change" }],
    freight: [{ required: true, message: "请填写运费", trigger: "blur" }]
  }
})

const { queryParams, form, rules } = toRefs(data)
const selectedPurchase = computed(() => purchaseOptions.value.find(item => item.purchaseId === form.value.purchaseId) || {})
const formTotal = computed(() => Number(form.value.freight || 0) + Number(form.value.insuranceFee || 0) + Number(form.value.otherFee || 0))

function formatAmount(value) {
  const amount = Number(value || 0)
  if (amount >= 10000) return "¥" + (amount / 10000).toFixed(1) + "万"
  return "¥" + amount.toLocaleString()
}

function carrierPercent(amount) {
  const max = Math.max(...carriers.value.map(item => Number(item.totalFee || 0)), 1)
  return Math.round((Number(amount || 0) / max) * 100)
}

function loadOptions() {
  listPurchase({ pageNum: 1, pageSize: 200 }).then(res => { purchaseOptions.value = res.rows || [] }).catch(() => { purchaseOptions.value = [] })
}

function loadStats() {
  getLogisticsMonthly({ range: "month" }).then(res => {
    const d = res.data || {}
    stats.value.totalFee = d.totalFee || 0
    stats.value.settledFee = d.settledFee || 0
    stats.value.unsettledFee = d.unsettledFee || 0
  }).catch(() => {})
  getLogisticsCarrier({ range: "month" }).then(res => {
    carriers.value = res.data || []
  }).catch(() => { carriers.value = [] })
  getDashboard().then(res => {
    stats.value.pendingCount = (res.data || {}).uncheckedCount || 0
  }).catch(() => {})
}

function getList() {
  if (activeTab.value === "stats") {
    loadStats()
    return
  }
  loading.value = true
  listLogistics(queryParams.value).then(res => {
    billList.value = res.rows || []
    total.value = res.total || 0
  }).finally(() => {
    loading.value = false
  })
}

function handleTabChange() {
  queryParams.value.pageNum = 1
  getList()
  loadStats()
}

function handleQuery() {
  queryParams.value.pageNum = 1
  getList()
}

function resetQuery() {
  proxy.resetForm("queryRef")
  handleQuery()
}

function filterPending() {
  activeTab.value = "bills"
  queryParams.value.payStatus = "0"
  queryParams.value.pageNum = 1
  getList()
}

function handleSelectionChange(selection) {
  ids.value = selection.map(item => item.logisticsId)
  multiple.value = !selection.length
}

function onPurchaseChange(purchaseId) {
  const item = purchaseOptions.value.find(row => row.purchaseId === purchaseId)
  if (!item) return
  form.value.productId = item.productId
  form.value.supplierId = item.supplierId
}

function handleAdd() {
  form.value = { logisticsNo: undefined, purchaseId: undefined, productId: undefined, supplierId: undefined, carrier: undefined, shipTime: undefined, arriveTime: undefined, freight: 0, insuranceFee: 0, otherFee: 0, remark: undefined }
  proxy.resetForm("logisticsRef")
  open.value = true
}

function submitForm() {
  proxy.$refs["logisticsRef"].validate(valid => {
    if (!valid) return
    addLogistics(form.value).then(() => {
      proxy.$modal.msgSuccess("新增成功")
      open.value = false
      getList()
      loadStats()
    })
  })
}

function handleView(row) {
  getLogistics(row.logisticsId).then(res => {
    viewForm.value = res.data
    viewOpen.value = true
  })
}

function changeStatus(logisticsIds, payStatus, confirmText) {
  const idsArr = Array.isArray(logisticsIds) ? logisticsIds : [logisticsIds]
  proxy.$modal.confirm(confirmText).then(function () {
    if (payStatus === "1") {
      return batchReconcileLogistics({ ids: idsArr })
    }
    return updateLogisticsStatus({ ids: idsArr, payStatus })
  }).then(res => {
    proxy.$modal.msgSuccess(res.msg || "操作成功")
    viewOpen.value = false
    getList()
    loadStats()
  }).catch(() => {})
}

function handleReconcile(row) {
  const selected = row?.logisticsId ? [row.logisticsId] : ids.value
  if (!selected.length) {
    proxy.$modal.msgWarning("请选择要对账的账单")
    return
  }
  changeStatus(selected, "1", "确认将选中账单标记为已对账？")
}

function handleSettle(row) {
  changeStatus(row.logisticsId, "2", "确认将账单 " + row.logisticsNo + " 结清？")
}

function handleAbnormal(row) {
  proxy.$modal.confirm("确认将账单 " + row.logisticsNo + " 标记为异常？").then(function () {
    return markLogistics({ logisticsId: row.logisticsId })
  }).then(res => {
    proxy.$modal.msgSuccess(res.msg || "已标记异常")
    viewOpen.value = false
    getList()
    loadStats()
  }).catch(() => {})
}

function handleExport() {
  proxy.download("pms/logistics/export", { ...queryParams.value }, `logistics_${new Date().getTime()}.xlsx`)
}

loadOptions()
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
.amount-ok {
  color: var(--el-color-success);
  font-weight: 700;
}
.carrier-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}
.carrier-card {
  padding: 16px 18px;
  border: 1px solid var(--el-border-color-light);
  border-radius: 8px;
  background: var(--el-fill-color-blank);
}
.carrier-card__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  font-weight: 700;
}
.carrier-card__amount {
  font-size: 22px;
  font-weight: 700;
  margin-bottom: 10px;
  color: var(--el-color-primary);
}
.goods-stat-row {
  margin-bottom: 16px;
}
.goods-stat-row :deep(.el-col) {
  margin-bottom: 12px;
}
@media (max-width: 768px) {
  .carrier-grid {
    grid-template-columns: 1fr;
  }
}
</style>
