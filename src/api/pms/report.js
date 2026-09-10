import request from '@/utils/request'

export function getReportOverview(query) {
  return request({
    url: '/pms/report/overview',
    method: 'get',
    params: query
  })
}

export function getReportPurchase(query) {
  return request({
    url: '/pms/report/purchase',
    method: 'get',
    params: query
  })
}

export function getReportStock(query) {
  return request({
    url: '/pms/report/stock',
    method: 'get',
    params: query
  })
}

export function getReportCost(query) {
  return request({
    url: '/pms/report/cost',
    method: 'get',
    params: query
  })
}

export function getReportSupplier(query) {
  return request({
    url: '/pms/report/supplier',
    method: 'get',
    params: query
  })
}

export function getReportTurnover(query) {
  return request({
    url: '/pms/report/turnover',
    method: 'get',
    params: query
  })
}

export function getReportTurnoverTrend(query) {
  return request({
    url: '/pms/report/turnover/trend',
    method: 'get',
    params: query
  })
}

export function getReportTurnoverRank(query) {
  return request({
    url: '/pms/report/turnover/rank',
    method: 'get',
    params: query
  })
}

export function getReportTurnoverCompare(query) {
  return request({
    url: '/pms/report/turnover/compare',
    method: 'get',
    params: query
  })
}

export function getReportTurnoverDetail(query) {
  return request({
    url: '/pms/report/turnover/detail',
    method: 'get',
    params: query
  })
}
