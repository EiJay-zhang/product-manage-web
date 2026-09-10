<template>
  <div class="app-container">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="8">
        <stat-card label="供应商总数" :value="stats.total + ' 家'" type="primary" icon="OfficeBuilding" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="8">
        <stat-card label="合作中" :value="stats.active + ' 家'" type="success" icon="CircleCheck" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="8">
        <stat-card label="已停用" :value="stats.stopped + ' 家'" type="info" icon="Remove" />
      </el-col>
    </el-row>

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="供应商" prop="supplierName">
        <el-input v-model="queryParams.supplierName" placeholder="厂家名称" clearable style="width: 200px" @keyup.enter="handleQuery" />
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="全部状态" clearable style="width: 160px">
          <el-option v-for="dict in coopStatusOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['pms:supplier:add']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="success" plain icon="Edit" :disabled="single" @click="handleUpdate" v-hasPermi="['pms:supplier:edit']">修改</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete" v-hasPermi="['pms:supplier:remove']">删除</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:supplier:export']">导出</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" :columns="columns" storageKey="pms-supplier-columns" />
    </el-row>

    <el-table v-loading="loading" :data="supplierList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="50" align="center" />
      <el-table-column label="供应商" min-width="180" v-if="columns.supplierName.visible">
        <template #default="scope">
          <div class="supplier-name">
            <span class="supplier-avatar">{{ (scope.row.supplierName || "").slice(0, 1) }}</span>
            <a class="link-type" @click="handleView(scope.row)">{{ scope.row.supplierName }}</a>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="联系人" align="center" prop="contactName" min-width="90" v-if="columns.contactName.visible" />
      <el-table-column label="联系电话" align="center" prop="phone" min-width="130" v-if="columns.phone.visible" />
      <el-table-column label="状态" align="center" prop="status" width="110" v-if="columns.status.visible">
        <template #default="scope">
          <el-switch v-model="scope.row.status" active-value="0" inactive-value="1" @change="handleStatusChange(scope.row)" />
        </template>
      </el-table-column>
      <el-table-column label="备注" align="center" prop="remark" min-width="140" v-if="columns.remark.visible" :show-overflow-tooltip="true" />
      <el-table-column label="操作" align="center" width="180" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button link type="primary" icon="View" @click="handleView(scope.row)" v-hasPermi="['pms:supplier:query']">查看</el-button>
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['pms:supplier:edit']">修改</el-button>
          <el-button link type="primary" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['pms:supplier:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <pagination v-show="total > 0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog :title="title" v-model="open" width="560px" append-to-body>
      <el-form ref="supplierRef" :model="form" :rules="rules" label-width="90px">
        <el-row>
          <el-col :span="24">
            <el-form-item label="供应商名称" prop="supplierName">
              <el-input v-model="form.supplierName" placeholder="请输入供应商名称" maxlength="50" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="联系人" prop="contactName">
              <el-input v-model="form.contactName" placeholder="请输入联系人" maxlength="30" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="联系电话" prop="phone">
              <el-input v-model="form.phone" placeholder="请输入联系电话" maxlength="20" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="状态" prop="status">
              <el-radio-group v-model="form.status">
                <el-radio v-for="dict in coopStatusOptions" :key="dict.value" :value="dict.value">{{ dict.label }}</el-radio>
              </el-radio-group>
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

    <el-dialog title="供应商详情" v-model="viewOpen" width="720px" append-to-body>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="供应商名称">{{ viewForm.supplierName }}</el-descriptions-item>
        <el-descriptions-item label="联系人">{{ viewForm.contactName }}</el-descriptions-item>
        <el-descriptions-item label="联系电话">{{ viewForm.phone }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <dict-tag :options="coopStatusOptions" :value="viewForm.status" />
        </el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewForm.remark || "-" }}</el-descriptions-item>
      </el-descriptions>
      <el-divider content-position="left">供货商品</el-divider>
      <el-table :data="viewProducts" size="small">
        <el-table-column label="商品编号" prop="productCode" />
        <el-table-column label="商品名称" prop="productName" />
        <el-table-column label="库存" prop="stockQty" width="80" />
      </el-table>
      <el-divider content-position="left">进货记录</el-divider>
      <el-table :data="viewPurchases" size="small">
        <el-table-column label="进货单号" prop="purchaseNo" />
        <el-table-column label="商品" prop="productName" />
        <el-table-column label="数量" prop="qty" width="80" />
        <el-table-column label="金额" prop="amount" width="100">
          <template #default="scope">¥{{ Number(scope.row.amount || 0).toFixed(2) }}</template>
        </el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup name="PmsSupplier">
import StatCard from "@/components/StatCard"
import { listSupplier, getSupplier, addSupplier, updateSupplier, delSupplier, listSupplierProducts, listSupplierPurchases } from "@/api/pms/supplier"
import { GOODS_COOP_STATUS, useGoodsDict } from "@/utils/goodsDict"

const { proxy } = getCurrentInstance()
const coopStatusOptions = useGoodsDict("sys_normal_disable", GOODS_COOP_STATUS)

const supplierList = ref([])
const open = ref(false)
const viewOpen = ref(false)
const loading = ref(true)
const showSearch = ref(true)
const ids = ref([])
const single = ref(true)
const multiple = ref(true)
const total = ref(0)
const title = ref("")
const viewForm = ref({})
const viewProducts = ref([])
const viewPurchases = ref([])
const stats = ref({ total: 0, active: 0, stopped: 0 })
const columns = ref({
  supplierName: { label: "供应商", visible: true },
  contactName: { label: "联系人", visible: true },
  phone: { label: "联系电话", visible: true },
  status: { label: "状态", visible: true },
  remark: { label: "备注", visible: true }
})

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    supplierName: undefined,
    status: undefined
  },
  rules: {
    supplierName: [{ required: true, message: "供应商名称不能为空", trigger: "blur" }],
    contactName: [{ required: true, message: "联系人不能为空", trigger: "blur" }],
    phone: [
      { required: true, message: "联系电话不能为空", trigger: "blur" },
      { pattern: /^[\d\-+\s]{6,20}$/, message: "请输入正确的联系电话", trigger: "blur" }
    ]
  }
})

const { queryParams, form, rules } = toRefs(data)

function refreshStats(rows, totalCount) {
  const active = (rows || []).filter(item => item.status === "0").length
  stats.value = {
    total: totalCount || 0,
    active,
    stopped: Math.max((totalCount || 0) - active, 0)
  }
}

function getList() {
  loading.value = true
  listSupplier(queryParams.value).then(res => {
    supplierList.value = res.rows || []
    total.value = res.total || 0
    refreshStats(supplierList.value, total.value)
  }).finally(() => {
    loading.value = false
  })
}

function handleQuery() {
  queryParams.value.pageNum = 1
  getList()
}

function resetQuery() {
  proxy.resetForm("queryRef")
  handleQuery()
}

function handleSelectionChange(selection) {
  ids.value = selection.map(item => item.supplierId)
  single.value = selection.length !== 1
  multiple.value = !selection.length
}

function reset() {
  form.value = {
    supplierId: undefined,
    supplierName: undefined,
    contactName: undefined,
    phone: undefined,
    status: "0",
    remark: undefined
  }
  proxy.resetForm("supplierRef")
}

function cancel() {
  open.value = false
  reset()
}

function handleAdd() {
  reset()
  open.value = true
  title.value = "新增供应商"
}

function handleUpdate(row) {
  reset()
  const supplierId = row.supplierId || ids.value
  getSupplier(supplierId).then(res => {
    form.value = res.data
    open.value = true
    title.value = "修改供应商"
  })
}

function handleView(row) {
  getSupplier(row.supplierId).then(res => {
    viewForm.value = res.data
    viewOpen.value = true
  })
  listSupplierProducts(row.supplierId).then(res => { viewProducts.value = res.data || [] }).catch(() => { viewProducts.value = [] })
  listSupplierPurchases(row.supplierId).then(res => { viewPurchases.value = res.data || [] }).catch(() => { viewPurchases.value = [] })
}

function submitForm() {
  proxy.$refs["supplierRef"].validate(valid => {
    if (!valid) return
    const request = form.value.supplierId != undefined ? updateSupplier(form.value) : addSupplier(form.value)
    request.then(() => {
      proxy.$modal.msgSuccess(form.value.supplierId != undefined ? "修改成功" : "新增成功")
      open.value = false
      getList()
    })
  })
}

function handleDelete(row) {
  const supplierIds = row.supplierId || ids.value
  proxy.$modal.confirm('是否确认删除供应商编号为"' + supplierIds + '"的数据项？').then(function () {
    return delSupplier(supplierIds)
  }).then(() => {
    getList()
    proxy.$modal.msgSuccess("删除成功")
  }).catch(() => {})
}

function handleStatusChange(row) {
  const text = row.status === "0" ? "启用" : "停用"
  proxy.$modal.confirm('确认要' + text + '「' + row.supplierName + '」吗？').then(function () {
    return updateSupplier({
      supplierId: row.supplierId,
      supplierName: row.supplierName,
      contactName: row.contactName,
      phone: row.phone,
      status: row.status,
      remark: row.remark
    })
  }).then(() => {
    proxy.$modal.msgSuccess(text + "成功")
    getList()
  }).catch(() => {
    row.status = row.status === "0" ? "1" : "0"
  })
}

function handleExport() {
  proxy.download("pms/supplier/export", { ...queryParams.value }, `supplier_${new Date().getTime()}.xlsx`)
}

getList()
</script>

<style scoped>
.supplier-name {
  display: flex;
  align-items: center;
  gap: 10px;
}
.supplier-avatar {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  background: var(--el-color-primary);
  color: #fff;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  flex-shrink: 0;
}
.goods-stat-row {
  margin-bottom: 16px;
}
.goods-stat-row :deep(.el-col) {
  margin-bottom: 12px;
}
</style>
