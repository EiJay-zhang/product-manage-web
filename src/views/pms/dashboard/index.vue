<template>
  <div class="app-container" v-loading="loading">
    <el-row :gutter="12" class="goods-stat-row">
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="商品总数" :value="(stats.productCount || 0) + ' 件'" :extra="'预警 ' + (stats.warnCount || 0) + ' / 零库存 ' + (stats.emptyCount || 0)" type="primary" icon="Goods" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="当前总库存" :value="(overview.stockQty || 0) + ' 件'" :extra="'本月进货 ' + (overview.purchaseQty || 0) + ' 件'" type="success" icon="Box" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="本月营业额" :value="formatAmount(monthTurnover.turnover)" :extra="monthCompareText" type="warning" icon="TrendCharts" />
      </el-col>
      <el-col :xs="24" :sm="12" :md="6">
        <stat-card label="本月进货成本" :value="formatAmount(overview.purchaseCost)" :extra="'进货 ' + (overview.purchaseQty || 0) + ' 件'" type="info" icon="Coin" />
      </el-col>
    </el-row>

    <el-alert v-if="stats.turnoverWarn" class="mb8" type="warning" show-icon :closable="false" :title="stats.turnoverWarn" />

    <el-row :gutter="12" class="dash-row">
      <el-col :xs="24" :lg="16">
        <el-card shadow="never">
          <template #header>
            <div class="card-head">
              <span>年度营业额趋势</span>
              <el-radio-group v-model="yearDimension" size="small" @change="loadYearTrend">
                <el-radio-button value="month">按月</el-radio-button>
                <el-radio-button value="week">按周</el-radio-button>
                <el-radio-button value="day">按日</el-radio-button>
              </el-radio-group>
            </div>
          </template>
          <div ref="yearChartRef" class="chart-box" />
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="8">
        <el-card shadow="never">
          <template #header>
            <div class="card-head">
              <span>本周营业额</span>
              <span class="week-amount">{{ formatAmount(weekTurnover.turnover) }}</span>
            </div>
          </template>
          <p class="week-compare">{{ weekCompareText }}</p>
          <div ref="weekChartRef" class="chart-box chart-box--sm" />
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="12" class="dash-row">
      <el-col :xs="24" :lg="12">
        <el-card shadow="never">
          <template #header>
            <div class="card-head">
              <span>系统通知</span>
              <el-button link type="primary" @click="loadData">刷新</el-button>
            </div>
          </template>
          <el-empty v-if="!notices.length" description="暂无待处理事项" :image-size="64" />
          <div v-else class="notice-list">
            <div v-for="(item, index) in notices" :key="index" class="notice-item" @click="goPath(item.to)">
              <el-tag :type="item.type" size="small">{{ item.tag }}</el-tag>
              <div class="notice-body">
                <div class="notice-title">{{ item.title }}</div>
                <div class="notice-desc">{{ item.desc }}</div>
              </div>
              <el-icon class="notice-arrow"><ArrowRight /></el-icon>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :lg="12">
        <el-card shadow="never">
          <template #header>
            <div class="card-head">
              <span>热销 TOP 5</span>
              <el-button link type="primary" @click="goPath('/pms/report')">查看报表</el-button>
            </div>
          </template>
          <el-empty v-if="!rankList.length" description="本月暂无销售数据" :image-size="64" />
          <div v-else class="rank-list">
            <div v-for="(item, index) in rankList.slice(0, 5)" :key="item.label + index" class="rank-item">
              <span class="rank-index">{{ index + 1 }}</span>
              <div class="rank-main">
                <div class="rank-name">{{ item.label }}</div>
                <el-progress :percentage="rankPercent(item)" :show-text="false" />
              </div>
              <div class="rank-value">
                <div>{{ formatAmount(item.value) }}</div>
                <div class="rank-qty">{{ item.qty || 0 }} 件</div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never">
      <template #header>
        <div class="card-head">
          <span>最近进货</span>
          <el-button link type="primary" @click="goPath('/pms/purchase')">全部进货</el-button>
        </div>
      </template>
      <el-table :data="purchaseList" empty-text="暂无进货记录">
        <el-table-column label="进货单号" prop="purchaseNo" min-width="140" />
        <el-table-column label="商品" prop="productName" min-width="140" />
        <el-table-column label="厂家" prop="supplierName" min-width="120" />
        <el-table-column label="数量" prop="qty" width="80" align="center" />
        <el-table-column label="金额" prop="amount" width="120" align="center">
          <template #default="scope">{{ formatAmount(scope.row.amount) }}</template>
        </el-table-column>
        <el-table-column label="进货日期" prop="purchaseTime" width="120" align="center">
          <template #default="scope">{{ parseTime(scope.row.purchaseTime, "{y}-{m}-{d}") }}</template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup name="PmsDashboard">
import * as echarts from "echarts"
import { useRouter } from "vue-router"
import StatCard from "@/components/StatCard"
import { getDashboard } from "@/api/pms/dashboard"
import { listPurchase } from "@/api/pms/purchase"
import { listProduct } from "@/api/pms/product"
import { listDevice } from "@/api/pms/device"
import { listLogistics } from "@/api/pms/logistics"
import {
  getReportOverview, getReportTurnover, getReportTurnoverTrend,
  getReportTurnoverRank, getReportTurnoverCompare
} from "@/api/pms/report"

const router = useRouter()
const loading = ref(false)
const stats = ref({})
const overview = ref({})
const monthTurnover = ref({})
const monthCompare = ref({})
const weekTurnover = ref({})
const weekCompare = ref({})
const rankList = ref([])
const purchaseList = ref([])
const warnProducts = ref([])
const offlineDevices = ref([])
const unpaidLogistics = ref([])
const yearDimension = ref("month")
const yearChartRef = ref(null)
const weekChartRef = ref(null)
let yearChart = null
let weekChart = null

const monthCompareText = computed(() => formatCompare(monthCompare.value, "上月"))
const weekCompareText = computed(() => formatCompare(weekCompare.value, "上周"))
const rankMax = computed(() => Math.max(...rankList.value.map(item => Number(item.value || 0)), 1))

const notices = computed(() => {
  const list = []
  warnProducts.value.forEach(item => {
    list.push({
      type: "warning",
      tag: "库存预警",
      title: item.productName,
      desc: "当前库存 " + (item.stockQty || 0) + " 件，请及时补货",
      to: { path: "/pms/product", query: { stockStatus: "warning" } }
    })
  })
  offlineDevices.value.forEach(item => {
    list.push({
      type: "info",
      tag: "墨水屏离线",
      title: item.sn || "未命名设备",
      desc: (item.shelfNo ? "货架 " + item.shelfNo + " · " : "") + (item.productName || "未绑定商品"),
      to: { path: "/pms/device", query: { onlineStatus: "0" } }
    })
  })
  unpaidLogistics.value.forEach(item => {
    list.push({
      type: "danger",
      tag: "物流未对账",
      title: item.logisticsNo || item.purchaseNo || "物流单",
      desc: "待付 " + formatAmount(item.totalFee),
      to: { path: "/pms/logistics", query: { payStatus: "0" } }
    })
  })
  if (stats.value.uncheckedCount) {
    list.push({
      type: "warning",
      tag: "待对账",
      title: "有 " + stats.value.uncheckedCount + " 单物流待对账",
      desc: "请核对运费与进货单",
      to: { path: "/pms/logistics", query: { payStatus: "0" } }
    })
  }
  return list.slice(0, 6)
})

function formatAmount(value) {
  const amount = Number(value || 0)
  if (amount >= 10000) return "¥" + (amount / 10000).toFixed(1) + "万"
  return "¥" + amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}

function formatCompare(compare, prevLabel) {
  const rate = compare && compare.growthRate != null ? Number(compare.growthRate) : 0
  const prev = (compare && compare.previous && compare.previous.turnover) || 0
  const sign = rate >= 0 ? "增长" : "下降"
  return prevLabel + " " + formatAmount(prev) + "，本期" + sign + " " + Math.abs(rate).toFixed(1) + "%"
}

function rankPercent(item) {
  return Math.round(Number(item.value || 0) / rankMax.value * 100)
}

function goPath(to) {
  if (to) router.push(to)
}

function disposeChart(chart) {
  if (chart) chart.dispose()
}

function renderChart(el, instanceName, points, title, type) {
  if (!el) return
  if (instanceName === "year") {
    disposeChart(yearChart)
    yearChart = echarts.init(el)
  } else {
    disposeChart(weekChart)
    weekChart = echarts.init(el)
  }
  const chart = instanceName === "year" ? yearChart : weekChart
  chart.setOption({
    title: title ? { text: title, left: 0, textStyle: { fontSize: 13, fontWeight: 500 } } : undefined,
    tooltip: { trigger: "axis" },
    grid: { left: 48, right: 16, top: title ? 36 : 16, bottom: 28 },
    xAxis: { type: "category", data: (points || []).map(item => item.label), axisLabel: { hideOverlap: true } },
    yAxis: { type: "value", splitLine: { lineStyle: { type: "dashed" } } },
    series: [{
      type: type || "line",
      smooth: true,
      barMaxWidth: 28,
      data: (points || []).map(item => Number(item.value || 0)),
      areaStyle: type === "line" ? { opacity: 0.12 } : undefined
    }]
  })
}

const quiet = { silent: true }

function loadYearTrend() {
  getReportTurnoverTrend({ range: "year", dimension: yearDimension.value }, quiet).then(res => {
    renderChart(yearChartRef.value, "year", res.data || [], "", "bar")
  }).catch(() => {
    renderChart(yearChartRef.value, "year", [], "", "bar")
  })
}

function onResize() {
  if (yearChart) yearChart.resize()
  if (weekChart) weekChart.resize()
}

function loadData() {
  loading.value = true
  Promise.allSettled([
    getDashboard().then(res => { stats.value = res.data || {} }),
    getReportOverview({ range: "month" }, quiet).then(res => { overview.value = res.data || {} }),
    getReportTurnover({ range: "month" }, quiet).then(res => { monthTurnover.value = res.data || {} }),
    getReportTurnoverCompare({ range: "month" }, quiet).then(res => { monthCompare.value = res.data || {} }),
    getReportTurnover({ range: "week" }, quiet).then(res => { weekTurnover.value = res.data || {} }),
    getReportTurnoverCompare({ range: "week" }, quiet).then(res => { weekCompare.value = res.data || {} }),
    getReportTurnoverRank({ range: "month" }, quiet).then(res => { rankList.value = res.data || [] }),
    getReportTurnoverTrend({ range: "week", dimension: "day" }, quiet).then(res => {
      nextTick(() => renderChart(weekChartRef.value, "week", res.data || [], "", "line"))
    }),
    getReportTurnoverTrend({ range: "year", dimension: yearDimension.value }, quiet).then(res => {
      nextTick(() => renderChart(yearChartRef.value, "year", res.data || [], "", "bar"))
    }),
    listPurchase({ pageNum: 1, pageSize: 5 }, quiet).then(res => { purchaseList.value = res.rows || [] }),
    listProduct({ stockStatus: "warning", pageNum: 1, pageSize: 3 }, quiet).then(res => { warnProducts.value = res.rows || [] }),
    listDevice({ onlineStatus: "0", pageNum: 1, pageSize: 3 }, quiet).then(res => { offlineDevices.value = res.rows || [] }),
    listLogistics({ payStatus: "0", pageNum: 1, pageSize: 3 }, quiet).then(res => { unpaidLogistics.value = res.rows || [] })
  ]).finally(() => { loading.value = false })
}

onMounted(() => {
  window.addEventListener("resize", onResize)
  loadData()
})
onUnmounted(() => {
  window.removeEventListener("resize", onResize)
  disposeChart(yearChart)
  disposeChart(weekChart)
  yearChart = null
  weekChart = null
})
</script>

<style scoped>
.goods-stat-row { margin-bottom: 8px; }
.goods-stat-row :deep(.el-col),
.dash-row :deep(.el-col) { margin-bottom: 12px; }
.dash-row { margin-bottom: 4px; }
.card-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.chart-box { height: 280px; }
.chart-box--sm { height: 220px; }
.week-amount { font-weight: 700; color: var(--el-color-warning); }
.week-compare {
  margin: 0 0 8px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}
.notice-list { display: flex; flex-direction: column; gap: 8px; }
.notice-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 8px;
  border-radius: 8px;
  cursor: pointer;
}
.notice-item:hover { background: var(--el-fill-color-light); }
.notice-body { flex: 1; min-width: 0; }
.notice-title { font-size: 14px; font-weight: 600; }
.notice-desc { margin-top: 2px; font-size: 12px; color: var(--el-text-color-secondary); }
.notice-arrow { color: var(--el-text-color-placeholder); }
.rank-list { display: flex; flex-direction: column; gap: 12px; }
.rank-item { display: flex; align-items: center; gap: 10px; }
.rank-index {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 700;
  background: var(--el-color-primary-light-8);
  color: var(--el-color-primary);
}
.rank-main { flex: 1; min-width: 0; }
.rank-name { margin-bottom: 4px; font-size: 13px; }
.rank-value { text-align: right; font-size: 13px; font-weight: 600; white-space: nowrap; }
.rank-qty { font-size: 12px; font-weight: 400; color: var(--el-text-color-secondary); }
</style>
