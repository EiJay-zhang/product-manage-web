import request from '@/utils/request'

export function listDevice(query, config) {
  return request({
    url: '/pms/device/list',
    method: 'get',
    params: query,
    ...config
  })
}

export function getDevice(deviceId) {
  return request({
    url: '/pms/device/' + deviceId,
    method: 'get'
  })
}

export function bindDevice(data) {
  return request({
    url: '/pms/device/bind',
    method: 'post',
    data: data
  })
}

export function unbindDevice(deviceId) {
  return request({
    url: '/pms/device/unbind/' + deviceId,
    method: 'put'
  })
}

export function refreshDevice(deviceId) {
  return request({
    url: '/pms/device/refresh/' + deviceId,
    method: 'put'
  })
}

export function restartDevice(deviceId) {
  return request({
    url: '/pms/device/restart/' + deviceId,
    method: 'put'
  })
}

export function batchRefreshDevice(data) {
  return request({
    url: '/pms/device/batchRefresh',
    method: 'post',
    data: data
  })
}

export function listDeviceSyncLog(query) {
  return request({
    url: '/pms/device/syncLog/list',
    method: 'get',
    params: query
  })
}

export function getDeviceTemplate() {
  return request({
    url: '/pms/device/template',
    method: 'get'
  })
}

export function saveDeviceTemplate(data) {
  return request({
    url: '/pms/device/template',
    method: 'put',
    data: data
  })
}
