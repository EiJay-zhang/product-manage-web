import request from '@/utils/request'

export function listPurchase(query, config) {
  return request({
    url: '/pms/purchase/list',
    method: 'get',
    params: query,
    ...config
  })
}

export function getPurchase(purchaseId) {
  return request({
    url: '/pms/purchase/' + purchaseId,
    method: 'get'
  })
}

export function addPurchase(data) {
  return request({
    url: '/pms/purchase',
    method: 'post',
    data: data
  })
}

export function voidPurchase(purchaseId) {
  return request({
    url: '/pms/purchase/' + purchaseId + '/void',
    method: 'put'
  })
}
