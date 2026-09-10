import request from '@/utils/request'

export function listCarrier(query) {
  return request({
    url: '/pms/carrier/list',
    method: 'get',
    params: query
  })
}

export function optionCarrier(query) {
  return request({
    url: '/pms/carrier/optionselect',
    method: 'get',
    params: query
  })
}

export function getCarrier(carrierId) {
  return request({
    url: '/pms/carrier/' + carrierId,
    method: 'get'
  })
}

export function listCarrierLogistics(carrierId) {
  return request({
    url: '/pms/carrier/' + carrierId + '/logistics',
    method: 'get'
  })
}

export function addCarrier(data) {
  return request({
    url: '/pms/carrier',
    method: 'post',
    data: data
  })
}

export function updateCarrier(data) {
  return request({
    url: '/pms/carrier',
    method: 'put',
    data: data
  })
}

export function delCarrier(carrierId) {
  return request({
    url: '/pms/carrier/' + carrierId,
    method: 'delete'
  })
}
