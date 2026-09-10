<template>
  <div class="app-container">
    <el-form :model="queryParams" ref="queryRef" :inline="true" v-show="showSearch">
      <el-form-item label="统计周期">
        <el-radio-group v-model="queryParams.range" @change="onRangeChange">
          <el-radio-button value="today">日</el-radio-button>
          <el-radio-button value="week">周</el-radio-button>
          <el-radio-button value="month">月</el-radio-button>
          <el-radio-button value="year">年</el-radio-button>
          <el-radio-button value="custom">自定义</el-radio-button>
        </el-radio-group>
      </el-form-item>
      <el-form-item v-if="queryParams.range === 'custom'" label="日期">
        <el-date-picker v-model="dateRange" type="daterange" value-format="YYYY-MM-DD" range-separator="-" start-placeholder="开始" end-placeholder="结束" style="width: 240px" />
      </el-form-item>
      <el-form-item v-if="activeTab === 'turnover'" label="趋势粒度">
        <el-select v-model="queryParams.dimension" style="width: 120px">
          <el-option label="按日" value="day" />
          <el-option label="按周" value="week" />
          <el-option label="按月" value="month" />
        </el-select>
      </el-form-item>
      <el-form-item label="商品名称" prop="productName">
        <el-input v-model="queryParams.productName" placeholder="商品名称" clearable style="width: 160px" />
      </el-form-item>
      <el-form-item label="分类" prop="categoryId">
        <el-select v-model="queryParams.categoryId" placeholder="全部" clearable style="width: 140px">
          <el-option v-for="item in categoryOptions" :key="item.categoryId" :label="item.categoryName" :value="item.categoryId" />
        </el-select>
      </el-form-item>
      <el-form-item v-if="activeTab === 'purchase' || activeTab === 'supplier'" label="厂家" prop="supplierId">
        <el-select v-model="queryParams.supplierId" placeholder="全部" clearable filterable style="width: 160px">
          <el-option v-for="item in supplierOptions" :key="item.supplierId" :label="item.supplierName" :value="item.supplierId" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" icon="Search" @click="loadData">查询</el-button>
        <el-button icon="Refresh" @click="resetQuery">重置</el-button>
      </el-form-item>
    </el-form>

    <el-row :gutter="10" class="mb8" justify="space-between">
      <el-col :xs="24" :sm="18">
        <el-radio-group v-model="activeTab" @change="loadData">
          <el-radio-button value="overview">经营概览</el-radio-button>
          <el-radio-button value="purchase">进货明细</el-radio-button>
          <el-radio-button value="stock">库存台账</el-radio-button>
          <el-radio-button value="cost">成本统计</el-radio-button>
          <el-radio-button value="supplier">供应商</el-radio-button>
          <el-radio-button value="turnover">营业额</el-radio-button>
        </el-radio-group>
      </el-col>
      <el-col :xs="24" :sm="6" class="toolbar-right">
        <el-button type="warning" plain icon="Download" @click="handleExport" v-hasPermi="['pms:report:export']">导出</el-button>
        <right-toolbar v-model:showSearch="showSearch" @queryTable="loadData" />
      </el-col>
    </el-row>

    <div v-loading="loading">
      <template v-if="activeTab === 'overview'">
        <el-row :gutter="12" class="goods-stat-row">
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="营收" :value="formatAmount(turnover.turnover)" type="primary" icon="TrendCharts" /></el-col>
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="进货成本" :value="formatAmount(overview.purchaseCost)" type="warning" icon="Coin" /></el-col>
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="毛利" :value="formatAmount(grossProfit)" type="success" icon="Wallet" /></el-col>
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="毛利率" :value="grossRateText" type="info" icon="DataAnalysis" /></el-col>
        </el-row>
        <el-row :gutter="12" class="goods-stat-row">
          <el-col :xs="24" :sm="8"><stat-card label="商品总数" :value="(overview.productCount || 0) + ' 件'" type="primary" icon="Goods" /></el-col>
          <el-col :xs="24" :sm="8"><stat-card label="当前总库存" :value="(overview.stockQty || 0) + ' 件'" type="success" icon="Box" /></el-col>
          <el-col :xs="24" :sm="8"><stat-card label="库存预警 / 零库存" :value="(overview.warnCount || 0) + ' / ' + (overview.emptyCount || 0)" type="danger" icon="Warning" /></el-col>
        </el-row>
        <el-row :gutter="12">
          <el-col :xs="24" :lg="14">
            <div ref="chartRef" class="chart-box" />
          </el-col>
          <el-col :xs="24" :lg="10">
            <el-table :data="rankList.slice(0, 5)" empty-text="暂无排行">
              <el-table-column label="热销商品" min-width="160">
                <template #default="scope">
                  <div class="rank-name">{{ scope.row.label }}</div>
                  <el-progress :percentage="rankPercent(scope.row)" :show-text="false" />
                </template>
              </el-table-column>
              <el-table-column label="营收" width="110" align="right">
                <template #default="scope">{{ formatAmount(scope.row.value) }}</template>
              </el-table-column>
            </el-table>
          </el-col>
        </el-row>
        <el-table :data="supplierList" class="mt16">
          <el-table-column label="厂家" prop="supplierName" min-width="160" />
          <el-table-column label="供货次数" prop="purchaseTimes" width="100" align="center" />
          <el-table-column label="供货总量" prop="totalQty" width="100" align="center" />
          <el-table-column label="供货金额" prop="totalAmount" width="120" align="center">
            <template #default="scope">{{ formatAmount(scope.row.totalAmount) }}</template>
          </el-table-column>
          <el-table-column label="金额占比" min-width="180">
            <template #default="scope">
              <el-progress :percentage="supplierShare(scope.row)" :stroke-width="10" />
            </template>
          </el-table-column>
        </el-table>
      </template>

      <template v-if="activeTab === 'purchase'">
        <el-row :gutter="12" class="goods-stat-row">
          <el-col :xs="24" :sm="12" :md="8"><stat-card label="进货数量" :value="(purchaseData.qty || 0) + ' 件'" type="primary" icon="Tickets" /></el-col>
          <el-col :xs="24" :sm="12" :md="8"><stat-card label="进货金额" :value="formatAmount(purchaseData.amount)" type="success" icon="Wallet" /></el-col>
        </el-row>
        <div ref="chartRef" class="chart-box" />
        <el-table :data="purchaseData.rows || []">
          <el-table-column label="进货单号" prop="purchaseNo" min-width="140" />
          <el-table-column label="商品" prop="productName" min-width="140" />
          <el-table-column label="数量" prop="qty" width="80" align="center" />
          <el-table-column label="进价" prop="purchasePrice" width="90" align="center">
            <template #default="scope">¥{{ Number(scope.row.purchasePrice || 0).toFixed(2) }}</template>
          </el-table-column>
          <el-table-column label="金额" prop="amount" width="110" align="center">
            <template #default="scope">{{ formatAmount(scope.row.amount) }}</template>
          </el-table-column>
          <el-table-column label="厂家" prop="supplierName" min-width="120" />
          <el-table-column label="进货日期" prop="purchaseTime" width="120" align="center">
            <template #default="scope">{{ parseTime(scope.row.purchaseTime, "{y}-{m}-{d}") }}</template>
          </el-table-column>
        </el-table>
      </template>

      <template v-if="activeTab === 'stock'">
        <el-row :gutter="12" class="goods-stat-row">
          <el-col :xs="24" :sm="12" :md="8"><stat-card label="入库数量" :value="(stockData.inQty || 0) + ' 件'" type="success" icon="Plus" /></el-col>
          <el-col :xs="24" :sm="12" :md="8"><stat-card label="调整数量" :value="(stockData.adjustQty || 0) + ' 件'" type="warning" icon="Edit" /></el-col>
        </el-row>
        <el-table :data="stockData.rows || []">
          <el-table-column label="商品" prop="productName" min-width="140" />
          <el-table-column label="类型" prop="changeType" width="90" align="center">
            <template #default="scope">
              <dict-tag :options="stockTypeOptions" :value="scope.row.changeType" />
            </template>
          </el-table-column>
          <el-table-column label="变动前" prop="beforeQty" width="80" align="center" />
          <el-table-column label="变动量" prop="changeQty" width="80" align="center" />
          <el-table-column label="结余" prop="afterQty" width="80" align="center" />
          <el-table-column label="时间" prop="createTime" width="170" align="center">
            <template #default="scope">{{ parseTime(scope.row.createTime) }}</template>
          </el-table-column>
        </el-table>
      </template>

      <el-table v-if="activeTab === 'cost'" :data="costList">
        <el-table-column label="商品" prop="productName" min-width="140" />
        <el-table-column label="规格" prop="spec" min-width="120" />
        <el-table-column label="当前库存" prop="stockQty" width="90" align="center" />
        <el-table-column label="当前进价" prop="purchasePrice" width="100" align="center">
          <template #default="scope">¥{{ Number(scope.row.purchasePrice || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column label="库存成本" prop="stockCost" width="110" align="center">
          <template #default="scope">{{ formatAmount(scope.row.stockCost) }}</template>
        </el-table-column>
        <el-table-column label="期间进货量" prop="purchaseQty" width="100" align="center" />
        <el-table-column label="期间进货成本" prop="purchaseCost" width="120" align="center">
          <template #default="scope">{{ formatAmount(scope.row.purchaseCost) }}</template>
        </el-table-column>
        <el-table-column label="平均进价" prop="avgPrice" width="100" align="center">
          <template #default="scope">¥{{ Number(scope.row.avgPrice || 0).toFixed(2) }}</template>
        </el-table-column>
      </el-table>

      <el-table v-if="activeTab === 'supplier'" :data="supplierList">
        <el-table-column label="厂家" prop="supplierName" min-width="160" />
        <el-table-column label="供货次数" prop="purchaseTimes" width="100" align="center" />
        <el-table-column label="供货总量" prop="totalQty" width="100" align="center" />
        <el-table-column label="供货金额" prop="totalAmount" width="120" align="center">
          <template #default="scope">{{ formatAmount(scope.row.totalAmount) }}</template>
        </el-table-column>
        <el-table-column label="金额占比" min-width="180">
          <template #default="scope">
            <el-progress :percentage="supplierShare(scope.row)" :stroke-width="10" />
          </template>
        </el-table-column>
        <el-table-column label="合作商品数" prop="productCount" width="110" align="center" />
      </el-table>

      <template v-if="activeTab === 'turnover'">
        <el-row :gutter="12" class="goods-stat-row">
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="营业额" :value="formatAmount(turnover.turnover)" type="primary" icon="TrendCharts" /></el-col>
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="销售数量" :value="(turnover.qty || 0) + ' 件'" type="info" icon="Goods" /></el-col>
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="动销商品" :value="(turnover.productCount || 0) + ' 种'" type="success" icon="List" /></el-col>
          <el-col :xs="24" :sm="12" :md="6"><stat-card label="日均营收" :value="formatAmount(turnover.avgDaily)" type="warning" icon="Coin" /></el-col>
        </el-row>
        <el-alert class="mb8" type="info" :closable="false" show-icon :title="compareText" />
        <div ref="chartRef" class="chart-box" />
        <el-table :data="rankList" class="mb8">
          <el-table-column label="商品" min-width="180">
            <template #default="scope">
              <div class="rank-name">{{ scope.row.label }}</div>
              <el-progress :percentage="rankPercent(scope.row)" :show-text="false" />
            </template>
          </el-table-column>
          <el-table-column label="营收" prop="value" width="120" align="center">
            <template #default="scope">{{ formatAmount(scope.row.value) }}</template>
          </el-table-column>
          <el-table-column label="销量" prop="qty" width="90" align="center" />
        </el-table>
        <el-table :data="detailList">
          <el-table-column label="销售单号" prop="saleNo" min-width="140" />
          <el-table-column label="商品" prop="productName" min-width="140" />
          <el-table-column label="数量" prop="qty" width="80" align="center" />
          <el-table-column label="金额" prop="amount" width="110" align="center">
            <template #default="scope">{{ formatAmount(scope.row.amount) }}</template>
          </el-table-column>
          <el-table-column label="时间" prop="saleTime" width="170" align="center">
            <template #default="scope">{{ parseTime(scope.row.saleTime) }}</template>
          </el-table-column>
        </el-table>
      </template>
    </div>
  </div>
</template>

<script setup name="PmsReport">
import * as echarts from "echarts"
import StatCard from "@/components/StatCard"
import { optionCategory } from "@/api/pms/category"
import { optionSupplier } from "@/api/pms/supplier"
import { GOODS_STOCK_TYPE, useGoodsDict } from "@/utils/goodsDict"
import {
  getReportOverview, getReportPurchase, getReportStock, getReportCost, getReportSupplier,
  getReportTurnover, getReportTurnoverTrend, getReportTurnoverRank, getReportTurnoverCompare, getReportTurnoverDetail
} from "@/api/pms/report"

const { proxy } = getCurrentInstance()
const stockTypeOptions = useGoodsDict("pms_stock_change_type", GOODS_STOCK_TYPE)
const activeTab = ref("overview")
const loading = ref(false)
const showSearch = ref(true)
const dateRange = ref([])
const categoryOptions = ref([])
const supplierOptions = ref([])
const overview = ref({})
const purchaseData = ref({ rows: [], qty: 0, amount: 0, chart: [] })
const stockData = ref({ rows: [], inQty: 0, adjustQty: 0 })
const costList = ref([])
const supplierList = ref([])
const turnover = ref({})
const compare = ref({})
const rankList = ref([])
const detailList = ref([])
const chartRef = ref(null)
let chartInstance = null

const data = reactive({
  queryParams: {
    range: "month",
    dimension: "day",
    productName: undefined,
    categoryId: undefined,
    supplierId: undefined,
    beginTime: undefined,
    endTime: undefined
  }
})
const { queryParams } = toRefs(data)

const compareText = computed(() => {
  const c = compare.value || {}
  const rate = c.growthRate == null ? 0 : Number(c.growthRate)
  const prev = (c.previous && c.previous.turnover) || 0
  const sign = rate >= 0 ? "增长" : "下降"
  return "对比上期营收 " + formatAmount(prev) + "，本期" + sign + " " + Math.abs(rate).toFixed(2) + "%"
})

const grossProfit = computed(() => Number(turnover.value.turnover || 0) - Number(overview.value.purchaseCost || 0))
const grossRateText = computed(() => {
  const rev = Number(turnover.value.turnover || 0)
  if (!rev) return "0.0%"
  return (grossProfit.value / rev * 100).toFixed(1) + "%"
})
const rankMax = computed(() => Math.max(...rankList.value.map(item => Number(item.value || 0)), 1))
const supplierTotal = computed(() => supplierList.value.reduce((sum, row) => sum + Number(row.totalAmount || 0), 0))

function rankPercent(item) {
  return Math.round(Number(item.value || 0) / rankMax.value * 100)
}

function supplierShare(row) {
  if (!supplierTotal.value) return 0
  return Math.round(Number(row.totalAmount || 0) / supplierTotal.value * 100)
}

function formatAmount(value) {
  const amount = Number(value || 0)
  if (amount >= 10000) return "¥" + (amount / 10000).toFixed(1) + "万"
  return "¥" + amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function buildQuery() {
  const q = { ...queryParams.value }
  if (q.range === "custom" && dateRange.value && dateRange.value.length === 2) {
    q.beginTime = dateRange.value[0] + " 00:00:00"
    q.endTime = dateRange.value[1] + " 23:59:59"
  } else {
    q.beginTime = undefined
    q.endTime = undefined
  }
  return q
}

function trendQuery(q) {
  const t = { ...q }
  if (activeTab.value === "overview") {
    t.dimension = q.range === "year" ? "month" : "day"
  }
  return t
}

function onRangeChange() {
  if (queryParams.value.range !== "custom") dateRange.value = []
  loadData()
}

function disposeChart() {
  if (chartInstance) {
    chartInstance.dispose()
    chartInstance = null
  }
}

function renderLine(points, title, type) {
  nextTick(() => {
    if (!chartRef.value) return
    disposeChart()
    chartInstance = echarts.init(chartRef.value)
    chartInstance.setOption({
      title: { text: title, left: 0, textStyle: { fontSize: 14 } },
      tooltip: { trigger: "axis" },
      grid: { left: 48, right: 20, top: 40, bottom: 30 },
      xAxis: { type: "category", data: (points || []).map(item => item.label) },
      yAxis: { type: "value", splitLine: { lineStyle: { type: "dashed" } } },
      series: [{
        type: type || "line",
        smooth: true,
        barMaxWidth: 28,
        data: (points || []).map(item => Number(item.value || 0)),
        areaStyle: type === "bar" ? undefined : {}
      }]
    })
  })
}

function loadData() {
  loading.value = true
  disposeChart()
  const q = buildQuery()
  const jobs = []
  if (activeTab.value === "overview") {
    jobs.push(getReportOverview(q).then(res => { overview.value = res.data || {} }))
    jobs.push(getReportTurnover(q).then(res => { turnover.value = res.data || {} }))
    jobs.push(getReportTurnoverRank(q).then(res => { rankList.value = res.data || [] }))
    jobs.push(getReportSupplier(q).then(res => { supplierList.value = res.data || [] }))
    jobs.push(getReportTurnoverTrend(trendQuery(q)).then(res => { renderLine(res.data || [], "营收趋势", "bar") }))
  } else if (activeTab.value === "purchase") {
    jobs.push(getReportPurchase(q).then(res => {
      purchaseData.value = Object.assign({ rows: [], qty: 0, amount: 0, chart: [] }, res.data || {})
      renderLine(purchaseData.value.chart, "进货金额趋势")
    }))
  } else if (activeTab.value === "stock") {
    jobs.push(getReportStock(q).then(res => { stockData.value = Object.assign({ rows: [], inQty: 0, adjustQty: 0 }, res.data || {}) }))
  } else if (activeTab.value === "cost") {
    jobs.push(getReportCost(q).then(res => { costList.value = res.data || [] }))
  } else if (activeTab.value === "supplier") {
    jobs.push(getReportSupplier(q).then(res => { supplierList.value = res.data || [] }))
  } else {
    jobs.push(getReportTurnover(q).then(res => { turnover.value = res.data || {} }))
    jobs.push(getReportTurnoverCompare(q).then(res => { compare.value = res.data || {} }))
    jobs.push(getReportTurnoverRank(q).then(res => { rankList.value = res.data || [] }))
    jobs.push(getReportTurnoverDetail(q).then(res => { detailList.value = res.data || [] }))
    jobs.push(getReportTurnoverTrend(q).then(res => { renderLine(res.data || [], "营收趋势") }))
  }
  Promise.all(jobs).catch(() => {}).finally(() => { loading.value = false })
}

function resetQuery() {
  dateRange.value = []
  proxy.resetForm("queryRef")
  queryParams.value.range = "month"
  queryParams.value.dimension = "day"
  loadData()
}

function handleExport() {
  proxy.download("pms/report/export/" + activeTab.value, buildQuery(), `report_${activeTab.value}_${new Date().getTime()}.xlsx`)
}

function onResize() {
  if (chartInstance) chartInstance.resize()
}

optionCategory().then(res => { categoryOptions.value = res.data || [] }).catch(() => {})
optionSupplier().then(res => { supplierOptions.value = res.data || [] }).catch(() => {})
loadData()
onMounted(() => window.addEventListener("resize", onResize))
onUnmounted(() => {
  window.removeEventListener("resize", onResize)
  disposeChart()
})
</script>

<style scoped>
.toolbar-right {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.goods-stat-row { margin-bottom: 16px; }
.goods-stat-row :deep(.el-col) { margin-bottom: 12px; }
.chart-box { height: 280px; margin-bottom: 16px; }
.mt16 { margin-top: 16px; }
.rank-name { margin-bottom: 4px; }
</style>
