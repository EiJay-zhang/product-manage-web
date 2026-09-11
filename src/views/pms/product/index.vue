<template>
  <div class="app-container">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="商品总数" :value="stats.productCount + ' 件'" type="primary" icon="Goods" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="库存预警" :value="stats.warnCount + ' 件'" type="warning" icon="Warning" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="零库存商品" :value="stats.emptyCount + ' 件'" type="danger" icon="CircleClose" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="离线墨水屏" :value="stats.offlineDeviceCount + ' 台'" type="success" icon="Monitor" />
      </el-col>
    </el-row>

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="商品名称" prop="productName">
        <el-input v-model="queryParams.productName" placeholder="商品名称" clearable style="width: 200px" @keyup.enter="handleQuery" />
      </el-form-item>
      <el-form-item label="分类" prop="categoryId">
        <el-select v-model="queryParams.categoryId" placeholder="全部分类" clearable style="width: 160px">
          <el-option v-for="item in categoryOptions" :key="item.categoryId" :label="item.categoryName" :value="item.categoryId" />
        </el-select>
      </el-form-item>
      <el-form-item label="进货厂家" prop="supplierId">
        <el-select v-model="queryParams.supplierId" placeholder="全部厂家" clearable filterable style="width: 180px">
          <el-option v-for="item in supplierOptions" :key="item.supplierId" :label="item.supplierName" :value="item.supplierId" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8" justify="space-between">
      <el-col :xs="24" :sm="12">
        <el-radio-group v-model="stockTab" @change="handleStockTab">
          <el-radio-button value="">全部商品</el-radio-button>
          <el-radio-button value="warning">库存预警</el-radio-button>
          <el-radio-button value="empty">零库存</el-radio-button>
        </el-radio-group>
      </el-col>
      <el-col :xs="24" :sm="12" class="toolbar-right">
        <el-button type="info" plain icon="Upload" @click="handleImport" v-hasPermi="['pms:product:import']">导入</el-button>
        <el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:product:export']">导出</el-button>
        <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['pms:product:add']">新增商品</el-button>
        <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" :columns="columns" storageKey="pms-product-columns" />
      </el-col>
    </el-row>

    <el-alert v-if="ids.length" class="mb8" type="info" :closable="false" show-icon>
      <template #title>
        <span>已选 {{ ids.length }} 件商品</span>
        <el-button class="ml10" size="small" @click="handleBatchEdit" v-hasPermi="['pms:product:edit']">批量编辑</el-button>
        <el-button size="small" type="danger" plain @click="handleDelete" v-hasPermi="['pms:product:remove']">批量删除</el-button>
        <el-button size="small" type="primary" plain @click="handleSyncEink" v-hasPermi="['pms:device:operate']">批量同步墨水屏</el-button>
      </template>
    </el-alert>

    <el-table v-loading="loading" :data="productList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="50" align="center" />
      <el-table-column label="商品编号" align="center" prop="productCode" min-width="120" v-if="columns.productCode.visible" />
      <el-table-column label="商品名称" min-width="150" v-if="columns.productName.visible" :show-overflow-tooltip="true">
        <template #default="scope">
          <span class="link-type">{{ scope.row.productName }}</span>
        </template>
      </el-table-column>
      <el-table-column label="规格" align="center" prop="spec" min-width="140" v-if="columns.spec.visible" :show-overflow-tooltip="true" />
      <el-table-column label="分类" align="center" prop="categoryName" width="100" v-if="columns.categoryName.visible" />
      <el-table-column label="进价" align="center" prop="purchasePrice" width="90" v-if="columns.purchasePrice.visible">
        <template #default="scope">¥{{ Number(scope.row.purchasePrice || 0).toFixed(2) }}</template>
      </el-table-column>
      <el-table-column label="售价" align="center" prop="salePrice" width="90" v-if="columns.salePrice.visible">
        <template #default="scope">¥{{ Number(scope.row.salePrice || 0).toFixed(2) }}</template>
      </el-table-column>
      <el-table-column label="库存" align="center" width="120" v-if="columns.stockQty.visible">
        <template #default="scope">
          <span :class="stockClass(scope.row)">{{ scope.row.stockQty }}</span>
          <el-tag v-if="scope.row.stockStatus === 'empty'" type="danger" class="ml5" size="small">无库存</el-tag>
          <el-tag v-else-if="scope.row.stockStatus === 'warning'" type="warning" class="ml5" size="small">预警</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="进货厂家" align="center" prop="supplierName" min-width="120" v-if="columns.supplierName.visible" :show-overflow-tooltip="true" />
      <el-table-column label="墨水屏" align="center" prop="deviceCount" width="90" v-if="columns.deviceCount.visible">
        <template #default="scope">
          <el-tag v-if="scope.row.deviceCount" type="success" size="small">{{ scope.row.deviceCount }} 台</el-tag>
          <span v-else class="text-muted">—</span>
        </template>
      </el-table-column>
      <el-table-column label="更新时间" align="center" prop="updateTime" width="160" v-if="columns.updateTime.visible">
        <template #default="scope">{{ parseTime(scope.row.updateTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="140" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['pms:product:edit']">编辑</el-button>
          <el-button link type="primary" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['pms:product:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog :title="title" v-model="open" width="680px" append-to-body>
      <el-form ref="productRef" :model="form" :rules="rules" label-width="90px">
        <el-row>
          <el-col :span="12">
            <el-form-item label="商品名称" prop="productName">
              <el-input v-model="form.productName" placeholder="请输入商品名称" maxlength="50" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="商品编号" prop="productCode">
              <el-input v-model="form.productCode" placeholder="可留空自动生成" maxlength="30" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="商品规格" prop="spec">
              <el-input v-model="form.spec" placeholder="如 330ml×24罐/箱" maxlength="50" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="分类" prop="categoryId">
              <el-select v-model="form.categoryId" placeholder="请选择分类" style="width: 100%">
                <el-option v-for="item in categoryOptions" :key="item.categoryId" :label="item.categoryName" :value="item.categoryId" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="进价" prop="purchasePrice">
              <el-input-number v-model="form.purchasePrice" :min="0" :precision="2" :step="0.1" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="售价" prop="salePrice">
              <el-input-number v-model="form.salePrice" :min="0" :precision="2" :step="0.1" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="库存" prop="stockQty">
              <el-input-number v-model="form.stockQty" :min="0" :precision="0" controls-position="right" style="width: 100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="进货厂家" prop="supplierId">
              <el-select v-model="form.supplierId" placeholder="请选择厂家" filterable style="width: 100%">
                <el-option v-for="item in supplierOptions" :key="item.supplierId" :label="item.supplierName" :value="item.supplierId" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="简介" prop="intro">
              <el-input v-model="form.intro" type="textarea" placeholder="商品简介，可选" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注" prop="remark">
              <el-input v-model="form.remark" type="textarea" placeholder="请输入备注" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitForm">确 定</el-button>
          <el-button @click="cancel">取 消</el-button>
        </div>
      </template>
    </el-dialog>

    <el-dialog title="批量编辑商品" v-model="batchOpen" width="480px" append-to-body>
      <el-form ref="batchRef" :model="batchForm" label-width="90px">
        <el-form-item label="分类">
          <el-select v-model="batchForm.categoryId" placeholder="不修改则留空" clearable style="width: 100%">
            <el-option v-for="item in categoryOptions" :key="item.categoryId" :label="item.categoryName" :value="item.categoryId" />
          </el-select>
        </el-form-item>
        <el-form-item label="进货厂家">
          <el-select v-model="batchForm.supplierId" placeholder="不修改则留空" clearable filterable style="width: 100%">
            <el-option v-for="item in supplierOptions" :key="item.supplierId" :label="item.supplierName" :value="item.supplierId" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitBatch">确 定</el-button>
          <el-button @click="batchOpen = false">取 消</el-button>
        </div>
      </template>
    </el-dialog>

    <excel-import-dialog ref="importProductRef" title="商品导入" action="/pms/product/importData" template-action="/pms/product/importTemplate" template-file-name="product_template" update-support-label="是否更新已经存在的商品（按编号或名称+规格匹配）" @success="onImportSuccess" />
  </div>
</template>

<script setup name="PmsProduct">
import StatCard from "@/components/StatCard"
import ExcelImportDialog from "@/components/ExcelImportDialog"
import { listProduct, getProduct, addProduct, updateProduct, delProduct } from "@/api/pms/product"
import { optionSupplier } from "@/api/pms/supplier"
import { optionCategory } from "@/api/pms/category"
import { getDashboard } from "@/api/pms/dashboard"
import { batchRefreshDevice } from "@/api/pms/device"
import { useRoute } from "vue-router"

const { proxy } = getCurrentInstance()
const route = useRoute()

const productList = ref([])
const categoryOptions = ref([])
const supplierOptions = ref([])
const open = ref(false)
const batchOpen = ref(false)
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const selectedRows = ref([])
const total = ref(0)
const title = ref("")
const stockTab = ref("")
const stats = ref({ productCount: 0, warnCount: 0, emptyCount: 0, offlineDeviceCount: 0 })
const columns = ref({
  productCode: { label: "商品编号", visible: true },
  productName: { label: "商品名称", visible: true },
  spec: { label: "规格", visible: true },
  categoryName: { label: "分类", visible: true },
  purchasePrice: { label: "进价", visible: true },
  salePrice: { label: "售价", visible: true },
  stockQty: { label: "库存", visible: true },
  supplierName: { label: "进货厂家", visible: true },
  deviceCount: { label: "墨水屏", visible: true },
  updateTime: { label: "更新时间", visible: true }
})

const data = reactive({
  form: {},
  batchForm: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    productName: undefined,
    categoryId: undefined,
    supplierId: undefined,
    stockStatus: undefined
  },
  rules: {
    productName: [{ required: true, message: "商品名称不能为空", trigger: "blur" }],
    spec: [{ required: true, message: "商品规格不能为空", trigger: "blur" }],
    categoryId: [{ required: true, message: "请选择分类", trigger: "change" }],
    purchasePrice: [{ required: true, message: "进价不能为空", trigger: "blur" }],
    salePrice: [{ required: true, message: "售价不能为空", trigger: "blur" }],
    stockQty: [{ required: true, message: "库存不能为空", trigger: "blur" }],
    supplierId: [{ required: true, message: "请选择进货厂家", trigger: "change" }]
  }
})

const { queryParams, form, batchForm, rules } = toRefs(data)

function stockClass(row) {
  if (row.stockStatus === "empty" || row.stockQty === 0) return "stock-empty"
  if (row.stockStatus === "warning") return "stock-warning"
  return "stock-ok"
}

function loadStats() {
  getDashboard().then(res => {
    stats.value = Object.assign({ productCount: 0, warnCount: 0, emptyCount: 0, offlineDeviceCount: 0 }, res.data || {})
  }).catch(() => {})
}

function loadOptions() {
  optionCategory().then(res => { categoryOptions.value = res.data || [] }).catch(() => { categoryOptions.value = [] })
  optionSupplier().then(res => { supplierOptions.value = res.data || [] }).catch(() => { supplierOptions.value = [] })
}

function getList() {
  loading.value = true
  listProduct(queryParams.value).then(res => {
    productList.value = res.rows || []
    total.value = res.total || 0
  }).finally(() => {
    loading.value = false
  })
}

function handleStockTab(value) {
  queryParams.value.stockStatus = value || undefined
  queryParams.value.pageNum = 1
  getList()
}

function handleQuery() {
  queryParams.value.pageNum = 1
  getList()
}

function resetQuery() {
  proxy.resetForm("queryRef")
  stockTab.value = ""
  queryParams.value.stockStatus = undefined
  handleQuery()
}

function handleSelectionChange(selection) {
  selectedRows.value = selection
  ids.value = selection.map(item => item.productId)
}

function reset() {
  form.value = {
    productId: undefined,
    productCode: undefined,
    productName: undefined,
    spec: undefined,
    categoryId: undefined,
    purchasePrice: 0,
    salePrice: 0,
    stockQty: 0,
    supplierId: undefined,
    intro: undefined,
    remark: undefined
  }
  proxy.resetForm("productRef")
}

function cancel() {
  open.value = false
  reset()
}

function handleAdd() {
  reset()
  open.value = true
  title.value = "新增商品"
}

function handleUpdate(row) {
  reset()
  getProduct(row.productId).then(res => {
    form.value = res.data
    open.value = true
    title.value = "修改商品"
  })
}

function submitForm() {
  proxy.$refs["productRef"].validate(valid => {
    if (!valid) return
    const request = form.value.productId != undefined ? updateProduct(form.value) : addProduct(form.value)
    request.then(() => {
      proxy.$modal.msgSuccess(form.value.productId != undefined ? "修改成功" : "新增成功")
      open.value = false
      getList()
      loadStats()
    })
  })
}

function handleDelete(row) {
  const productIds = row?.productId || ids.value
  proxy.$modal.confirm('是否确认删除商品编号为"' + productIds + '"的数据项？').then(function () {
    return delProduct(productIds)
  }).then(() => {
    getList()
    loadStats()
    proxy.$modal.msgSuccess("删除成功")
  }).catch(() => {})
}

function handleBatchEdit() {
  batchForm.value = { categoryId: undefined, supplierId: undefined }
  batchOpen.value = true
}

function submitBatch() {
  if (batchForm.value.categoryId == null && batchForm.value.supplierId == null) {
    proxy.$modal.msgWarning("请至少选择一项要修改的内容")
    return
  }
  const jobs = selectedRows.value.map(row => {
    const payload = { ...row }
    if (batchForm.value.categoryId != null) payload.categoryId = batchForm.value.categoryId
    if (batchForm.value.supplierId != null) payload.supplierId = batchForm.value.supplierId
    return updateProduct(payload)
  })
  Promise.all(jobs).then(() => {
    proxy.$modal.msgSuccess("批量修改成功")
    batchOpen.value = false
    getList()
    loadStats()
  })
}

function handleSyncEink() {
  proxy.$modal.confirm("确认将已选商品同步到绑定的墨水屏？").then(function () {
    return batchRefreshDevice({ productIds: ids.value })
  }).then(res => {
    proxy.$modal.msgSuccess(res.msg || "同步成功")
    getList()
  }).catch(() => {})
}

function handleExport() {
  proxy.download("pms/product/export", { ...queryParams.value }, `product_${new Date().getTime()}.xlsx`)
}

function handleImport() {
  proxy.$refs["importProductRef"].open()
}

function onImportSuccess() {
  getList()
  loadStats()
}

if (route.query.stockStatus) {
  stockTab.value = String(route.query.stockStatus)
  queryParams.value.stockStatus = stockTab.value
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
.stock-ok {
  color: var(--el-color-success);
  font-weight: 700;
}
.stock-warning {
  color: var(--el-color-warning);
  font-weight: 700;
}
.stock-empty {
  color: var(--el-color-danger);
  font-weight: 700;
}
.text-muted {
  color: var(--el-text-color-placeholder);
}
.goods-stat-row {
  margin-bottom: 16px;
}
.goods-stat-row :deep(.el-col) {
  margin-bottom: 12px;
}
</style>
