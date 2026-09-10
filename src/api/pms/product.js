import request from '@/utils/request'

export function listProduct(query, config) {
  return request({
    url: '/pms/product/list',
    method: 'get',
    params: query,
    ...config
  })
}

export function optionProduct(query) {
  return request({
    url: '/pms/product/optionselect',
    method: 'get',
    params: query
  })
}

export function getProduct(productId) {
  return request({
    url: '/pms/product/' + productId,
    method: 'get'
  })
}

export function addProduct(data) {
  return request({
    url: '/pms/product',
    method: 'post',
    data: data
  })
}

export function updateProduct(data) {
  return request({
    url: '/pms/product',
    method: 'put',
    data: data
  })
}

export function delProduct(productId) {
  return request({
    url: '/pms/product/' + productId,
    method: 'delete'
  })
}
