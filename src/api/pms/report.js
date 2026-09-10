import request from '@/utils/request'

export function getReportOverview(query, config) {
  return request({
    url: '/pms/report/overview',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportPurchase(query, config) {
  return request({
    url: '/pms/report/purchase',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportStock(query, config) {
  return request({
    url: '/pms/report/stock',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportCost(query, config) {
  return request({
    url: '/pms/report/cost',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportSupplier(query, config) {
  return request({
    url: '/pms/report/supplier',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportTurnover(query, config) {
  return request({
    url: '/pms/report/turnover',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportTurnoverTrend(query, config) {
  return request({
    url: '/pms/report/turnover/trend',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportTurnoverRank(query, config) {
  return request({
    url: '/pms/report/turnover/rank',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportTurnoverCompare(query, config) {
  return request({
    url: '/pms/report/turnover/compare',
    method: 'get',
    params: query,
    ...config
  })
}

export function getReportTurnoverDetail(query, config) {
  return request({
    url: '/pms/report/turnover/detail',
    method: 'get',
    params: query,
    ...config
  })
}
