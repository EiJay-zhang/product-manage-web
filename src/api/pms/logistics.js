import request from '@/utils/request'

export function listLogistics(query, config) {
  return request({
    url: '/pms/logistics/list',
    method: 'get',
    params: query,
    ...config
  })
}

export function getLogistics(logisticsId) {
  return request({
    url: '/pms/logistics/' + logisticsId,
    method: 'get'
  })
}

export function addLogistics(data) {
  return request({
    url: '/pms/logistics',
    method: 'post',
    data: data
  })
}

export function updateLogistics(data) {
  return request({
    url: '/pms/logistics',
    method: 'put',
    data: data
  })
}

export function updateLogisticsStatus(data) {
  return request({
    url: '/pms/logistics/status',
    method: 'put',
    data: data
  })
}

export function markLogistics(data) {
  return request({
    url: '/pms/logistics/mark',
    method: 'put',
    data: data
  })
}

export function batchReconcileLogistics(data) {
  return request({
    url: '/pms/logistics/batchReconcile',
    method: 'post',
    data: data
  })
}

export function getLogisticsMonthly(query) {
  return request({
    url: '/pms/logistics/stats/monthly',
    method: 'get',
    params: query
  })
}

export function getLogisticsCarrier(query) {
  return request({
    url: '/pms/logistics/stats/carrier',
    method: 'get',
    params: query
  })
}
