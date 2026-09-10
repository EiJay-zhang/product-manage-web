<template>
  <div class="app-container">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="8">
        <stat-card label="物流商总数" :value="stats.total + ' 家'" type="primary" icon="Van" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="8">
        <stat-card label="合作中" :value="stats.active + ' 家'" type="success" icon="CircleCheck" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="8">
        <stat-card label="已停用" :value="stats.stopped + ' 家'" type="info" icon="Remove" />
      </el-col>
    </el-row>

    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="物流商" prop="carrierName">
        <el-input v-model="queryParams.carrierName" placeholder="物流商名称" clearable style="width: 200px" @keyup.enter="handleQuery" />
      </el-form-item>
      <el-form-item label="状态" prop="status">
        <el-select v-model="queryParams.status" placeholder="全部状态" clearable style="width: 160px">
          <el-option v-for="dict in statusOptions" :key="dict.value" :label="dict.label" :value="dict.value" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="handleQuery">搜索</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8">
      <el-col :span="1.5">
        <el-button type="primary" plain icon="Plus" @click="handleAdd" v-hasPermi="['pms:carrier:add']">新增</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="success" plain icon="Edit" :disabled="single" @click="handleUpdate()" v-hasPermi="['pms:carrier:edit']">修改</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="danger" plain icon="Delete" :disabled="multiple" @click="handleDelete()" v-hasPermi="['pms:carrier:remove']">删除</el-button>
      </el-col>
      <el-col :span="1.5">
        <el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:carrier:export']">导出</el-button>
      </el-col>
      <right-toolbar v-model:showSearch="showSearch" @queryTable="getList" :columns="columns" storageKey="pms-carrier-columns" />
    </el-row>

    <el-table v-loading="loading" :data="carrierList" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="50" align="center" />
      <el-table-column label="物流商" min-width="180" v-if="columns.carrierName.visible">
        <template #default="scope">
          <div class="carrier-name">
            <span class="carrier-avatar">{{ (scope.row.carrierName || "").slice(0, 1) }}</span>
            <a class="link-type" @click="handleView(scope.row)">{{ scope.row.carrierName }}</a>
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
      <el-table-column label="创建时间" align="center" prop="createTime" width="170" v-if="columns.createTime.visible">
        <template #default="scope">{{ parseTime(scope.row.createTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="180" class-name="small-padding fixed-width">
        <template #default="scope">
          <el-button link type="primary" icon="View" @click="handleView(scope.row)" v-hasPermi="['pms:carrier:query']">查看</el-button>
          <el-button link type="primary" icon="Edit" @click="handleUpdate(scope.row)" v-hasPermi="['pms:carrier:edit']">修改</el-button>
          <el-button link type="primary" icon="Delete" @click="handleDelete(scope.row)" v-hasPermi="['pms:carrier:remove']">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-empty v-if="!loading && total === 0" description="还没有物流商，请先新增后再去物流对账开单">
      <el-button type="primary" @click="handleAdd" v-hasPermi="['pms:carrier:add']">新增物流商</el-button>
    </el-empty>

    <pagination v-show="total > 0" :total="total" v-model:page="queryParams.pageNum" v-model:limit="queryParams.pageSize" @pagination="getList" />

    <el-dialog :title="title" v-model="open" width="560px" append-to-body>
      <el-form ref="carrierRef" :model="form" :rules="rules" label-width="90px">
        <el-form-item label="物流商名称" prop="carrierName">
          <el-input v-model="form.carrierName" placeholder="请输入物流商名称" maxlength="50" />
        </el-form-item>
        <el-form-item label="联系人" prop="contactName">
          <el-input v-model="form.contactName" placeholder="选填" maxlength="30" />
        </el-form-item>
        <el-form-item label="联系电话" prop="phone">
          <el-input v-model="form.phone" placeholder="选填" maxlength="20" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio v-for="dict in statusOptions" :key="dict.value" :value="dict.value">{{ dict.label }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" type="textarea" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="submitForm">确 定</el-button>
          <el-button @click="open = false">取 消</el-button>
        </div>
      </template>
    </el-dialog>

    <el-dialog title="物流商详情" v-model="viewOpen" width="720px" append-to-body>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="物流商名称">{{ viewForm.carrierName }}</el-descriptions-item>
        <el-descriptions-item label="联系人">{{ viewForm.contactName || "-" }}</el-descriptions-item>
        <el-descriptions-item label="联系电话">{{ viewForm.phone || "-" }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <dict-tag :options="statusOptions" :value="viewForm.status" />
        </el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ viewForm.remark || "-" }}</el-descriptions-item>
      </el-descriptions>
      <el-divider content-position="left">关联物流单</el-divider>
      <el-table :data="viewBills" size="small" empty-text="暂无关联账单">
        <el-table-column label="物流单号" prop="logisticsNo" min-width="130" />
        <el-table-column label="进货单号" prop="purchaseNo" min-width="130" />
        <el-table-column label="费用" prop="totalFee" width="100" align="center">
          <template #default="scope">¥{{ Number(scope.row.totalFee || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column label="状态" prop="payStatus" width="90" align="center">
          <template #default="scope">
            <dict-tag :options="payStatusOptions" :value="scope.row.payStatus" />
          </template>
        </el-table-column>
      </el-table>
      <template #footer>
        <div class="dialog-footer">
          <el-button type="primary" @click="goLogistics">查看对账</el-button>
          <el-button @click="viewOpen = false">关 闭</el-button>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script setup name="PmsCarrier">
import { useRouter } from "vue-router"
import StatCard from "@/components/StatCard"
import { listCarrier, getCarrier, addCarrier, updateCarrier, delCarrier, listCarrierLogistics } from "@/api/pms/carrier"
import { GOODS_COOP_STATUS, GOODS_LOGISTICS_STATUS, useGoodsDict } from "@/utils/goodsDict"

const { proxy } = getCurrentInstance()
const router = useRouter()
const statusOptions = useGoodsDict("sys_normal_disable", GOODS_COOP_STATUS)
const payStatusOptions = useGoodsDict("pms_pay_status", GOODS_LOGISTICS_STATUS)

const carrierList = ref([])
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
const viewBills = ref([])
const stats = ref({ total: 0, active: 0, stopped: 0 })
const columns = ref({
  carrierName: { label: "物流商", visible: true },
  contactName: { label: "联系人", visible: true },
  phone: { label: "联系电话", visible: true },
  status: { label: "状态", visible: true },
  remark: { label: "备注", visible: true },
  createTime: { label: "创建时间", visible: true }
})

const data = reactive({
  form: {},
  queryParams: {
    pageNum: 1,
    pageSize: 10,
    carrierName: undefined,
    status: undefined
  },
  rules: {
    carrierName: [{ required: true, message: "物流商名称不能为空", trigger: "blur" }],
    phone: [{
      validator: (rule, value, callback) => {
        if (!value) callback()
        else if (!/^[\d\-+\s]{6,20}$/.test(value)) callback(new Error("请输入正确的联系电话"))
        else callback()
      },
      trigger: "blur"
    }]
  }
})
const { queryParams, form, rules } = toRefs(data)

function loadStats() {
  Promise.all([
    listCarrier({ pageNum: 1, pageSize: 1 }),
    listCarrier({ pageNum: 1, pageSize: 1, status: "0" })
  ]).then(([allRes, activeRes]) => {
    const totalCount = allRes.total || 0
    const active = activeRes.total || 0
    stats.value = { total: totalCount, active, stopped: Math.max(totalCount - active, 0) }
  }).catch(() => {})
}

function getList() {
  loading.value = true
  listCarrier(queryParams.value).then(res => {
    carrierList.value = res.rows || []
    total.value = res.total || 0
  }).finally(() => { loading.value = false })
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

function handleSelectionChange(selection) {
  ids.value = selection.map(item => item.carrierId)
  single.value = selection.length !== 1
  multiple.value = !selection.length
}

function reset() {
  form.value = {
    carrierId: undefined,
    carrierName: undefined,
    contactName: undefined,
    phone: undefined,
    status: "0",
    remark: undefined
  }
  proxy.resetForm("carrierRef")
}

function handleAdd() {
  reset()
  open.value = true
  title.value = "新增物流商"
}

function resolveId(row) {
  if (row && row.carrierId) return row.carrierId
  return ids.value.length === 1 ? ids.value[0] : ids.value
}

function handleUpdate(row) {
  reset()
  const carrierId = resolveId(row)
  if (!carrierId) return
  getCarrier(carrierId).then(res => {
    form.value = res.data
    open.value = true
    title.value = "修改物流商"
  })
}

function handleView(row) {
  getCarrier(row.carrierId).then(res => {
    viewForm.value = res.data
    viewOpen.value = true
  })
  listCarrierLogistics(row.carrierId).then(res => { viewBills.value = res.data || [] }).catch(() => { viewBills.value = [] })
}

function goLogistics() {
  viewOpen.value = false
  router.push({ path: "/pms/logistics", query: { carrierId: String(viewForm.value.carrierId || "") } })
}

function submitForm() {
  proxy.$refs["carrierRef"].validate(valid => {
    if (!valid) return
    const payload = Object.assign({}, form.value)
    if (!payload.phone) payload.phone = undefined
    const req = payload.carrierId ? updateCarrier(payload) : addCarrier(payload)
    req.then(() => {
      proxy.$modal.msgSuccess(payload.carrierId ? "修改成功" : "新增成功")
      open.value = false
      getList()
    })
  })
}

function handleDelete(row) {
  const carrierIds = resolveId(row)
  if (!carrierIds || (Array.isArray(carrierIds) && !carrierIds.length)) return
  proxy.$modal.confirm("是否确认删除所选物流商？删除后不可用于新的物流对账单。").then(() => delCarrier(carrierIds)).then(() => {
    proxy.$modal.msgSuccess("删除成功")
    getList()
  }).catch(() => {})
}

function handleStatusChange(row) {
  const text = row.status === "0" ? "启用" : "停用"
  proxy.$modal.confirm("确认要" + text + "「" + row.carrierName + "」吗？").then(() => updateCarrier({
    carrierId: row.carrierId,
    carrierName: row.carrierName,
    contactName: row.contactName,
    phone: row.phone,
    status: row.status,
    remark: row.remark
  })).then(() => {
    proxy.$modal.msgSuccess(text + "成功")
    getList()
  }).catch(() => {
    row.status = row.status === "0" ? "1" : "0"
  })
}

function handleExport() {
  proxy.download("pms/carrier/export", { ...queryParams.value }, `carrier_${new Date().getTime()}.xlsx`)
}

getList()
</script>

<style scoped>
.carrier-name {
  display: flex;
  align-items: center;
  gap: 10px;
}
.carrier-avatar {
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
.goods-stat-row { margin-bottom: 16px; }
.goods-stat-row :deep(.el-col) { margin-bottom: 12px; }
</style>
