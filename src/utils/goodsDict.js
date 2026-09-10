import { computed } from "vue"
import { useDict } from "@/utils/dict"

export const GOODS_COOP_STATUS = [
  { label: "正常", value: "0", elTagType: "success" },
  { label: "停用", value: "1", elTagType: "info" }
]

export const GOODS_STOCK_TYPE = [
  { label: "入库", value: "IN", elTagType: "success" },
  { label: "盘点", value: "CHECK", elTagType: "info" },
  { label: "损耗", value: "LOSS", elTagType: "danger" },
  { label: "调拨", value: "TRANSFER", elTagType: "warning" },
  { label: "销售", value: "SALE", elTagType: "primary" },
  { label: "建档", value: "INIT", elTagType: "info" }
]

export const GOODS_STOCK_ADJUST_TYPE = [
  { label: "人工盘点", value: "CHECK", elTagType: "info" },
  { label: "损耗调减", value: "LOSS", elTagType: "danger" },
  { label: "调拨", value: "TRANSFER", elTagType: "warning" }
]

export const GOODS_EINK_ONLINE = [
  { label: "离线", value: "0", elTagType: "danger" },
  { label: "在线", value: "1", elTagType: "success" }
]

export const GOODS_EINK_SYNC = [
  { label: "失败", value: "0", elTagType: "danger" },
  { label: "成功", value: "1", elTagType: "success" },
  { label: "待确认", value: "2", elTagType: "warning" }
]

export const GOODS_LOGISTICS_STATUS = [
  { label: "未对账", value: "0", elTagType: "info" },
  { label: "已对账", value: "1", elTagType: "warning" },
  { label: "已结清", value: "2", elTagType: "success" }
]

export function withDictFallback(dictRef, fallback) {
  return computed(() => (dictRef.value && dictRef.value.length ? dictRef.value : fallback))
}

export function useGoodsDict(dictType, fallback) {
  const dicts = useDict(dictType)
  return withDictFallback(dicts[dictType], fallback)
}

export function dictLabel(options, value) {
  const item = (options || []).find(row => String(row.value) === String(value))
  return item ? item.label : (value || "")
}

export function todayStr() {
  const d = new Date()
  const pad = n => String(n).padStart(2, "0")
  return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate())
}

export function monthRange(offset = 0) {
  const d = new Date()
  d.setDate(1)
  d.setMonth(d.getMonth() + offset)
  const start = new Date(d.getFullYear(), d.getMonth(), 1)
  const end = new Date(d.getFullYear(), d.getMonth() + 1, 0)
  const fmt = date => {
    const pad = n => String(n).padStart(2, "0")
    return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
  }
  return [fmt(start), fmt(end)]
}
