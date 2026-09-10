<template>
  <div class="app-container">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="今日营业额" :value="formatAmount(stats.todayTurnover)" type="primary" icon="TrendCharts" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="销售单数" :value="total + ' 单'" type="info" icon="Tickets" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="库存预警" :value="(stats.warnCount || 0) + ' 件'" type="warning" icon="Warning" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="零库存" :value="(stats.emptyCount || 0) + ' 件'" type="danger" icon="CircleClose" />
      </el-col>
    </el-row>

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="商品名称" prop="productName">
        <el-input v-model="queryParams.productName" placeholder="商品名称" clearable style="width: 180px" @keyup.enter="handleQuery" />
      </el-form-item>
      <el-form-item label="分类" prop="categoryId">
        <el-select v-model="queryParams.categoryId" placeholder="全部分类" clearable style="width: 160px">
          <el-option v-for="item in categoryOptions" :key="item.categoryId" :label="item.categoryName" :value="item.categoryId" />
        </el-select>
      </el-form-item>
      <el-form-item label="销售时间">
        <el-date-picker v-model="dateRange" type="daterange" value-format="YYYY-MM-DD" range-separator="-" start-placeholder="开始" end-placeholder="结束" style="width: 240px" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['pms:sale:add']">销售出库</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:sale:export']">导出</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" />
    </el-row>

    <el-table v-loading="loading" :data="saleList">
      <el-table-column label="销售单号" align="center" prop="saleNo" min-width="150">
        <template #default="scope"><span class="link-type" @click="handleView(scope.row)">{{ scope.row.saleNo }}</span></template>
      </el-table-column>
      <el-table-column label="商品名称" min-width="150" prop="productName" :show-overflow-tooltip="true" />
      <el-table-column label="规格" align="center" prop="spec" min-width="140" :show-overflow-tooltip="true" />
      <el-table-column label="数量" align="center" prop="qty" width="80" />
      <el-table-column label="售价" align="center" prop="salePrice" width="100">
        <template #default="scope">¥{{ Number(scope.row.salePrice || 0).toFixed(2) }}</template>
      </el-table-column>
      <el-table-column label="金额" align="center" prop="amount" width="110">
        <template #default="scope"><span class="amount-ok">{{ formatAmount(scope.row.amount) }}</span></template>
      </el-table-column>
      <el-table-column label="销售时间" align="center" prop="saleTime" width="170">
        <template #default="scope">{{ parseTime(scope.row.saleTime) }}</template>
      </el-table-column>
      <el-table-column label="操作人" align="center" prop="createBy" width="100" />
      <el-table-column label="操作" align="center" width="90">
        <template #default="scope">
          <el-button link type="primary" icon="View" @click="handleView(scope.row)" v-hasPermi="['pms:sale:query']">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog title="销售出库" v-model="open" width="560px" append-to-body>
      <el-form ref="saleRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="商品" prop="productId">
          <el-select v-model="form.productId" placeholder="请选择商品" filterable style="width: 100%" @change="onProductChange">
            <el-option v-for="item in productOptions" :key="item.productId" :label="item.productName + '（库存 ' + (item.stockQty || 0) + '）'" :value="item.productId" />
          </el-select>
        </el-form-item>
        <el-form-item label="规格">
          <el-input :model-value="selectedProduct.spec" disabled />
        </el-form-item>
        <el-form-item label="当前库存">
          <el-input :model-value="selectedProduct.stockQty" disabled />
        </el-form-item>
        <el-form-item label="销售数量" prop="qty">
          <el-input-number v-model="form.qty" :min="1" :precision="0" controls-position="right" style="width: 100%" />
        </el-form-item>
        <el-form-item label="成交售价" prop="salePrice">
          <el-input-number v-model="form.salePrice" :min="0" :precision="2" :step="0.1" controls-position="right" style="width: 100%" />
        </el-form-item>
        <el-form-item label="金额">
          <el-input :model-value="formatAmount(formAmount)" disabled />
        </el-form-item>
        <el-form-item label="销售时间" prop="saleTime">
          <el-date-picker v-model="form.saleTime" type="datetime" value-format="YYYY-MM-DD HH:mm:ss" placeholder="销售时间" style="width: 100%" />
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" placeholder="选填" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="submitForm">确 定</el-button>
        <el-button @click="open = false">取 消</el-button>
      </template>
    </el-dialog>

    <el-dialog title="销售详情" v-model="viewOpen" width="560px" append-to-body>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="销售单号">{{ viewForm.saleNo }}</el-descriptions-item>
        <el-descriptions-item label="商品">{{ viewForm.productName }}</el-descriptions-item>
        <el-descriptions-item label="规格">{{ viewForm.spec }}</el-descriptions-item>
        <el-descriptions-item label="数量">{{ viewForm.qty }}</el-descriptions-item>
        <el-descriptions-item label="售价">¥{{ Number(viewForm.salePrice || 0).toFixed(2) }}</el-descriptions-item>
        <el-descriptions-item label="金额">{{ formatAmount(viewForm.amount) }}</el-descriptions-item>
        <el-descriptions-item label="销售时间">{{ parseTime(viewForm.saleTime) }}</el-descriptions-item>
        <el-descriptions-item label="操作人">{{ viewForm.createBy }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewForm.remark || "—" }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup name="PmsSale">
import StatCard from "@/components/StatCard"
import { listSale, getSale, addSale } from "@/api/pms/sale"
import { optionProduct } from "@/api/pms/product"
import { optionCategory } from "@/api/pms/category"
import { getDashboard } from "@/api/pms/dashboard"

const { proxy } = getCurrentInstance()
const saleList = ref([])
const productOptions = ref([])
const categoryOptions = ref([])
const loading = ref(true)
const showSearch = ref(true)
const total = ref(0)
const open = ref(false)
const viewOpen = ref(false)
const viewForm = ref({})
const dateRange = ref([])
const stats = ref({})

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    productName: undefined,
    categoryId: undefined,
    beginTime: undefined,
    endTime: undefined
  },
  rules: {
    productId: [{ required: true, message: "请选择商品", trigger: "change" }],
    qty: [{ required: true, message: "请填写销售数量", trigger: "blur" }],
    salePrice: [{ required: true, message: "请填写售价", trigger: "blur" }]
  }
})
const { queryParams, form, rules } = toRefs(data)
const selectedProduct = computed(() => productOptions.value.find(item => item.productId === form.value.productId) || {})
const formAmount = computed(() => Number(form.value.qty || 0) * Number(form.value.salePrice || 0))

function formatAmount(value) {
  const amount = Number(value || 0)
  if (amount >= 10000) return "¥" + (amount / 10000).toFixed(1) + "万"
  return "¥" + amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function nowStr() {
  const d = new Date()
  const pad = n => String(n).padStart(2, "0")
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) + " " + pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
}

function applyDateRange() {
  if (dateRange.value && dateRange.value.length === 2) {
    queryParams.value.beginTime = dateRange.value[0] + " 00:00:00"
    queryParams.value.endTime = dateRange.value[1] + " 23:59:59"
  } else {
    queryParams.value.beginTime = undefined
    queryParams.value.endTime = undefined
  }
}

function loadOptions() {
  optionProduct().then(res => { productOptions.value = res.data || [] }).catch(() => { productOptions.value = [] })
  optionCategory().then(res => { categoryOptions.value = res.data || [] }).catch(() => { categoryOptions.value = [] })
}

function loadStats() {
  getDashboard().then(res => { stats.value = res.data || {} }).catch(() => {})
}

function getList() {
  loading.value = true
  applyDateRange()
  listSale(queryParams.value).then(res => {
    saleList.value = res.rows || []
    total.value = res.total || 0
  }).finally(() => { loading.value = false })
}

function handleQuery() {
  queryParams.value.pageNum = 1
  getList()
}

function resetQuery() {
  dateRange.value = []
  proxy.resetForm("queryRef")
  handleQuery()
}

function onProductChange(productId) {
  const item = productOptions.value.find(row => row.productId === productId)
  if (item) form.value.salePrice = Number(item.salePrice || 0)
}

function handleAdd() {
  form.value = { productId: undefined, qty: 1, salePrice: 0, saleTime: nowStr(), remark: undefined }
  proxy.resetForm("saleRef")
  open.value = true
}

function submitForm() {
  proxy.$refs["saleRef"].validate(valid => {
    if (!valid) return
    addSale(form.value).then(() => {
      proxy.$modal.msgSuccess("出库成功")
      open.value = false
      loadOptions()
      getList()
      loadStats()
    })
  })
}

function handleView(row) {
  getSale(row.saleId).then(res => {
    viewForm.value = res.data || {}
    viewOpen.value = true
  })
}

function handleExport() {
  applyDateRange()
  proxy.download("pms/sale/export", { ...queryParams.value }, `sale_${new Date().getTime()}.xlsx`)
}

loadOptions()
getList()
loadStats()
</script>

<style scoped>
.amount-ok { color: var(--el-color-success); font-weight: 700; }
.goods-stat-row { margin-bottom: 16px; }
.goods-stat-row :deep(.el-col) { margin-bottom: 12px; }
</style>
