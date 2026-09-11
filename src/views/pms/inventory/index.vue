<template>
  <div class="app-container">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="本月进货金额" :value="formatAmount(stats.monthAmount)" type="primary" icon="Wallet" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="本月进货批次" :value="stats.monthBatches + ' 次'" type="info" icon="Tickets" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="库存预警商品" :value="stats.warnCount + ' 件'" type="warning" icon="Warning" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="零库存商品" :value="stats.emptyCount + ' 件'" type="danger" icon="CircleClose" />
      </el-col>
    </el-row>

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="商品名称" prop="productName">
        <el-input v-model="queryParams.productName" placeholder="商品名称" clearable style="width: 200px" @keyup.enter="handleQuery" />
      </el-form-item>
      <el-form-item v-if="activeTab === 'purchase'" label="供货厂家" prop="supplierId">
        <el-select v-model="queryParams.supplierId" placeholder="全部厂家" clearable filterable style="width: 180px">
          <el-option v-for="item in supplierOptions" :key="item.supplierId" :label="item.supplierName" :value="item.supplierId" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="activeTab === 'purchase'" label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="全部状态" clearable style="width: 140px">
          <el-option v-for="dict in purchaseStatusOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="activeTab === 'stock'" label="变动类型" prop="changeType">
        <el-select v-model="queryParams.changeType" placeholder="全部类型" clearable style="width: 160px">
          <el-option v-for="dict in stockTypeOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item label="时间" prop="period">
        <el-select v-model="queryParams.period" style="width: 120px" @change="onPeriodChange">
          <el-option label="本月" value="month" />
          <el-option label="上月" value="lastMonth" />
          <el-option label="全部" value="all" />
          <el-option label="自定义" value="custom" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="queryParams.period === 'custom'" label="日期">
        <el-date-picker v-model="dateRange" type="daterange" value-format="YYYY-MM-DD" range-separator="-" start-placeholder="开始" end-placeholder="结束" style="width: 240px" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8" justify="space-between">
      <el-col :xs="24" :sm="12">
        <el-radio-group v-model="activeTab" @change="handleTabChange">
          <el-radio-button value="purchase">进货台账</el-radio-button>
          <el-radio-button value="stock">库存变动日志</el-radio-button>
        </el-radio-group>
      </el-col>
      <el-col :xs="24" :sm="12" class="toolbar-right">
        <el-button v-if="activeTab === 'purchase'" type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:purchase:export']">导出</el-button>
        <el-button v-else type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:stock:export']">导出</el-button>
        <el-button v-if="activeTab === 'stock'" type="success" plain icon="Edit" @click="handleAdjust" v-hasPermi="['pms:stock:adjust']">库存调整</el-button>
        <el-button v-if="activeTab === 'purchase'" type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['pms:purchase:add']">新增进货</el-button>
        <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
      </el-col>
    </el-row>

    <el-table v-if="activeTab === 'purchase'" v-loading="loading" :data="purchaseList" :row-class-name="purchaseRowClass">
      <el-table-column label="进货单号" align="center" prop="purchaseNo" min-width="150">
        <template #default="scope"><span class="link-type">{{ scope.row.purchaseNo }}</span></template>
      </el-table-column>
      <el-table-column label="商品名称" min-width="150" prop="productName" :show-overflow-tooltip="true" />
      <el-table-column label="规格" align="center" prop="spec" min-width="140" :show-overflow-tooltip="true" />
      <el-table-column label="进货数量" align="center" prop="qty" width="100" />
      <el-table-column label="单品进价" align="center" prop="purchasePrice" width="110">
        <template #default="scope">¥{{ Number(scope.row.purchasePrice || 0).toFixed(2) }}</template>
      </el-table-column>
      <el-table-column label="本次金额" align="center" prop="amount" width="120">
        <template #default="scope"><span class="amount-ok">{{ formatAmount(scope.row.amount) }}</span></template>
      </el-table-column>
      <el-table-column label="供货厂家" align="center" prop="supplierName" min-width="120" :show-overflow-tooltip="true" />
      <el-table-column label="状态" align="center" prop="status" width="90">
        <template #default="scope">
          <dict-tag :options="purchaseStatusOptions" :value="scope.row.status || '0'" />
        </template>
      </el-table-column>
      <el-table-column label="进货时间" align="center" prop="purchaseTime" width="170">
        <template #default="scope">{{ parseTime(scope.row.purchaseTime, "{y}-{m}-{d}") }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="90" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button v-if="scope.row.status !== '1'" link type="danger" icon="CircleClose" @click="handleVoid(scope.row)" v-hasPermi="['pms:purchase:void']">作废</el-button>
          <span v-else class="text-muted">已作废</span>
        </template>
      </el-table-column>
    </el-table>

    <el-table v-else v-loading="loading" :data="stockLogList">
      <el-table-column label="流水ID" align="center" prop="logId" width="90" />
      <el-table-column label="商品名称" min-width="150" prop="productName" :show-overflow-tooltip="true" />
      <el-table-column label="操作类型" align="center" prop="changeType" width="110">
        <template #default="scope">
          <dict-tag :options="stockTypeOptions" :value="scope.row.changeType" />
        </template>
      </el-table-column>
      <el-table-column label="变动前" align="center" prop="beforeQty" width="90" />
      <el-table-column label="变动量" align="center" prop="changeQty" width="90">
        <template #default="scope">
          <span :class="scope.row.changeQty >= 0 ? 'stock-ok' : 'stock-empty'">{{ formatChange(scope.row.changeQty) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="变动后" align="center" prop="afterQty" width="90">
        <template #default="scope"><b>{{ scope.row.afterQty }}</b></template>
      </el-table-column>
      <el-table-column label="操作人" align="center" prop="createBy" width="100" />
      <el-table-column label="操作时间" align="center" prop="createTime" width="170">
        <template #default="scope">{{ parseTime(scope.row.createTime) }}</template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog title="新增进货" v-model="open" width="640px" append-to-body>
      <el-form ref="purchaseRef" :model="form" :rules="rules" label-width="90px">
        <el-row>
          <el-col :span="24">
            <el-form-item label="商品" prop="productId">
              <el-select v-model="form.productId" placeholder="请选择商品" filterable style="width: 100%" @change="onProductChange">
                <el-option v-for="item in productOptions" :key="item.productId" :label="item.productName + '（' + item.productCode + '）'" :value="item.productId" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="规格">
              <el-input :model-value="selectedProduct.spec" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="当前库存">
              <el-input :model-value="selectedProduct.stockQty" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="进货数量" prop="qty">
              <el-input-number v-model="form.qty" :min="1" :precision="0" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="单品进价" prop="purchasePrice">
              <el-input-number v-model="form.purchasePrice" :min="0" :precision="2" :step="0.1" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="本次金额">
              <el-input :model-value="formatAmount(formAmount)" disabled />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="供货厂家" prop="supplierId">
              <el-select v-model="form.supplierId" placeholder="请选择厂家" filterable style="width: 100%">
                <el-option v-for="item in supplierOptions" :key="item.supplierId" :label="item.supplierName" :value="item.supplierId" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="进货日期" prop="purchaseTime">
              <el-date-picker v-model="form.purchaseTime" type="date" value-format="YYYY-MM-DD" placeholder="进货日期" style="width: 100%" />
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
          <el-button type="primary" @click="submitPurchase">确 定</el-button>
          <el-button @click="open = false">取 消</el-button>
        </div>
      </template>
    </el-dialog>

    <el-dialog title="库存调整" v-model="adjustOpen" width="520px" append-to-body>
      <el-form ref="adjustRef" :model="adjustForm" :rules="adjustRules" label-width="90px">
        <el-form-item label="商品" prop="productId">
          <el-select v-model="adjustForm.productId" placeholder="请选择商品" filterable style="width: 100%" @change="onAdjustProductChange">
            <el-option v-for="item in productOptions" :key="item.productId" :label="item.productName + '（库存 ' + item.stockQty + '）'" :value="item.productId" />
          </el-select>
        </el-form-item>
        <el-form-item label="调整类型" prop="changeType">
          <el-radio-group v-model="adjustForm.changeType">
            <el-radio v-for="dict in adjustTypeOptions" :key="dict.value" :value="dict.value">{{ dict.label }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="当前库存">
          <el-input :model-value="adjustStock" disabled />
        </el-form-item>
        <el-form-item v-if="adjustForm.changeType === 'LOSS'" label="损耗数量" prop="lossQty">
          <el-input-number v-model="adjustForm.lossQty" :min="1" :precision="0" controls-position="right" style="width: 100%" />
        </el-form-item>
        <el-form-item v-else label="调整后库存" prop="afterQtyTarget">
          <el-input-number v-model="adjustForm.afterQtyTarget" :min="0" :precision="0" controls-position="right" style="width: 100%" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="adjustForm.remark" type="textarea" placeholder="选填原因" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitAdjust">确 定</el-button>
          <el-button @click="adjustOpen = false">取 消</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="PmsInventory">
import StatCard from "@/components/StatCard"
import { listPurchase, addPurchase, voidPurchase } from "@/api/pms/purchase"
import { listStockLog, adjustStock as submitStockAdjust } from "@/api/pms/stock"
import { optionProduct } from "@/api/pms/product"
import { optionSupplier } from "@/api/pms/supplier"
import { getDashboard } from "@/api/pms/dashboard"
import { GOODS_STOCK_TYPE, GOODS_STOCK_ADJUST_TYPE, GOODS_PURCHASE_STATUS, useGoodsDict, todayStr, monthRange } from "@/utils/goodsDict"

const props = defineProps({
  defaultTab: { type: String, default: "purchase" }
})

const { proxy } = getCurrentInstance()
const stockTypeOptions = useGoodsDict("pms_stock_change_type", GOODS_STOCK_TYPE)
const purchaseStatusOptions = useGoodsDict("pms_bill_status", GOODS_PURCHASE_STATUS)
const adjustTypeOptions = GOODS_STOCK_ADJUST_TYPE

const activeTab = ref(props.defaultTab === "stock" ? "stock" : "purchase")
const purchaseList = ref([])
const stockLogList = ref([])
const productOptions = ref([])
const supplierOptions = ref([])
const loading = ref(true)
const showSearch = ref(true)
const total = ref(0)
const open = ref(false)
const adjustOpen = ref(false)
const dateRange = ref([])
const stats = ref({ monthAmount: 0, monthBatches: 0, warnCount: 0, emptyCount: 0 })

const data = reactive({
  form: {},
  adjustForm: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    productName: undefined,
    supplierId: undefined,
    changeType: undefined,
    status: undefined,
    period: "month",
    beginTime: undefined,
    endTime: undefined
  },
  rules: {
    productId: [{ required: true, message: "请选择商品", trigger: "change" }],
    qty: [{ required: true, message: "请填写进货数量", trigger: "blur" }],
    purchasePrice: [{ required: true, message: "请填写进价", trigger: "blur" }],
    supplierId: [{ required: true, message: "请选择厂家", trigger: "change" }],
    purchaseTime: [{ required: true, message: "请选择进货日期", trigger: "change" }]
  },
  adjustRules: {
    productId: [{ required: true, message: "请选择商品", trigger: "change" }],
    changeType: [{ required: true, message: "请选择调整类型", trigger: "change" }],
    afterQtyTarget: [{ required: true, message: "请填写调整后库存", trigger: "blur" }],
    lossQty: [{ required: true, message: "请填写损耗数量", trigger: "blur" }]
  }
})

const { queryParams, form, adjustForm, rules, adjustRules } = toRefs(data)

const selectedProduct = computed(() => productOptions.value.find(item => item.productId === form.value.productId) || {})
const formAmount = computed(() => Number(form.value.qty || 0) * Number(form.value.purchasePrice || 0))
const adjustStock = computed(() => {
  const item = productOptions.value.find(row => row.productId === adjustForm.value.productId)
  return item ? item.stockQty : ""
})

function formatAmount(value) {
  const amount = Number(value || 0)
  if (amount >= 10000) return "¥" + (amount / 10000).toFixed(1) + "万"
  return "¥" + amount.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 2 })
}

function formatChange(value) {
  const num = Number(value || 0)
  return (num > 0 ? "+" : "") + num
}

function applyDateRange() {
  if (queryParams.value.period === "custom" && dateRange.value && dateRange.value.length === 2) {
    queryParams.value.beginTime = dateRange.value[0]
    queryParams.value.endTime = dateRange.value[1]
  } else if (queryParams.value.period === "month") {
    const range = monthRange(0)
    queryParams.value.beginTime = range[0]
    queryParams.value.endTime = range[1]
  } else if (queryParams.value.period === "lastMonth") {
    const range = monthRange(-1)
    queryParams.value.beginTime = range[0]
    queryParams.value.endTime = range[1]
  } else {
    queryParams.value.beginTime = undefined
    queryParams.value.endTime = undefined
  }
}

function onPeriodChange() {
  if (queryParams.value.period !== "custom") dateRange.value = []
}

function loadOptions() {
  optionProduct().then(res => { productOptions.value = res.data || [] }).catch(() => { productOptions.value = [] })
  optionSupplier().then(res => { supplierOptions.value = res.data || [] }).catch(() => { supplierOptions.value = [] })
}

function loadStats() {
  applyDateRange()
  getDashboard().then(res => {
    const d = res.data || {}
    stats.value.warnCount = d.warnCount || 0
    stats.value.emptyCount = d.emptyCount || 0
  }).catch(() => {})
  const month = monthRange(0)
  listPurchase({ pageNum: 1, pageSize: 1, beginTime: month[0], endTime: month[1], status: "0" }).then(res => {
    stats.value.monthBatches = res.total || 0
  }).catch(() => {})
  listPurchase({ pageNum: 1, pageSize: 200, beginTime: month[0], endTime: month[1], status: "0" }).then(res => {
    stats.value.monthAmount = (res.rows || []).reduce((sum, row) => sum + Number(row.amount || 0), 0)
  }).catch(() => {})
}

function buildQuery() {
  applyDateRange()
  const q = { ...queryParams.value }
  delete q.period
  if (activeTab.value === "purchase") delete q.changeType
  if (activeTab.value === "stock") {
    delete q.supplierId
    delete q.status
  }
  return q
}

function getList() {
  loading.value = true
  const request = activeTab.value === "purchase" ? listPurchase : listStockLog
  request(buildQuery()).then(res => {
    if (activeTab.value === "purchase") {
      purchaseList.value = res.rows || []
    } else {
      stockLogList.value = res.rows || []
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
  loadStats()
}

function resetQuery() {
  dateRange.value = []
  proxy.resetForm("queryRef")
  queryParams.value.period = "month"
  handleQuery()
}

function onProductChange(productId) {
  const item = productOptions.value.find(row => row.productId === productId)
  if (!item) return
  form.value.purchasePrice = Number(item.purchasePrice)
  form.value.supplierId = item.supplierId
}

function handleAdd() {
  form.value = { productId: undefined, qty: 1, purchasePrice: 0, supplierId: undefined, purchaseTime: todayStr(), remark: undefined }
  proxy.resetForm("purchaseRef")
  open.value = true
}

function submitPurchase() {
  proxy.$refs["purchaseRef"].validate(valid => {
    if (!valid) return
    addPurchase(form.value).then(() => {
      proxy.$modal.msgSuccess("进货成功")
      open.value = false
      loadOptions()
      getList()
      loadStats()
    })
  })
}

function onAdjustProductChange() {
  const item = productOptions.value.find(row => row.productId === adjustForm.value.productId)
  if (item && adjustForm.value.changeType !== "LOSS") {
    adjustForm.value.afterQtyTarget = Number(item.stockQty || 0)
  }
}

function handleAdjust() {
  adjustForm.value = { productId: undefined, changeType: "CHECK", afterQtyTarget: 0, lossQty: 1, remark: undefined }
  proxy.resetForm("adjustRef")
  adjustOpen.value = true
}

function submitAdjust() {
  proxy.$refs["adjustRef"].validate(valid => {
    if (!valid) return
    const item = productOptions.value.find(row => row.productId === adjustForm.value.productId) || {}
    const afterQtyTarget = adjustForm.value.changeType === "LOSS"
      ? Math.max(Number(item.stockQty || 0) - Number(adjustForm.value.lossQty || 0), 0)
      : adjustForm.value.afterQtyTarget
    submitStockAdjust({
      productId: adjustForm.value.productId,
      changeType: adjustForm.value.changeType,
      afterQtyTarget,
      remark: adjustForm.value.remark
    }).then(() => {
      proxy.$modal.msgSuccess("库存已更新")
      adjustOpen.value = false
      loadOptions()
      getList()
      loadStats()
    })
  })
}

function handleVoid(row) {
  proxy.$modal.confirm("确认作废进货单「" + row.purchaseNo + "」？将回滚库存 " + row.qty + " 件。").then(() => {
    return voidPurchase(row.purchaseId)
  }).then(() => {
    proxy.$modal.msgSuccess("已作废")
    loadOptions()
    getList()
    loadStats()
  }).catch(() => {})
}

function purchaseRowClass({ row }) {
  return row.status === "1" ? "row-void" : ""
}

function handleExport() {
  const url = activeTab.value === "purchase" ? "pms/purchase/export" : "pms/stock/log/export"
  proxy.download(url, buildQuery(), `inventory_${new Date().getTime()}.xlsx`)
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
.amount-ok, .stock-ok {
  color: var(--el-color-success);
  font-weight: 700;
}
.stock-empty {
  color: var(--el-color-danger);
  font-weight: 700;
}
.text-muted {
  color: var(--el-text-color-placeholder);
}
.row-void {
  color: var(--el-text-color-placeholder);
}
.goods-stat-row {
  margin-bottom: 16px;
}
.goods-stat-row :deep(.el-col) {
  margin-bottom: 12px;
}
</style>
