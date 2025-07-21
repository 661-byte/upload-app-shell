#!/bin/bash
# 全局变量定义

# 应用信息
appId="1000000000000000" # 替换为实际的应用ID

# 认证信息
client_id="********" # 替换为实际的client_id
authorization="*******"

# 备注信息
test_desc="测试-$(date +%m-%d)"

# 分组ID列表
groupIds=("" "")

filePath="$1"
fileName="$(basename "$filePath")"

# 新建测试版本，返回 versionId（如果 code 为 0）
# 用法: new_test_version
new_test_version() {
  log "调用新建测试版本接口..."
  local url="https://connect-api.cloud.huawei.com/api/publish/v2/test/app/version?appId=${appId}"
  local payload="{ \"releaseType\": 6, \"testType\": 3, \"testDesc\": \"${test_desc}\" }"
  log "请求参数: url=$url, payload=$payload"
  local response=$(curl -s -X POST "$url" \
    -H "client_id: $client_id" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $authorization" \
    -d "$payload")
  local code=$(echo "$response" | grep -o '"code"[ ]*:[ ]*[0-9]*' | grep -o '[0-9]*')
  log "新建测试版本接口返回: $response"
  if [ "$code" = "0" ]; then
    local versionId=$(echo "$response" | grep -o '"versionId"[ ]*:[ ]*"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
    echo "$versionId"
  else
    log "Request failed or code != 0"
    return 1
  fi
}

# 添加测试版本软件包，返回 pkgVersion（如果 code 为 0）
# 用法: add_package <objectId>
add_test_version_package() {
    log "调用添加测试版本软件包接口..."
    local objectId="$1"
    local url="https://connect-api.cloud.huawei.com/api/publish/v2/test/version/pkg?appId=${appId}"
    local payload="{ \"distributeMode\": 1, \"file\": { \"fileName\": \"${fileName}\", \"objectId\": \"${objectId}\" } }"
    log "请求参数: url=$url, payload=$payload"
    local response=$(curl -s -X POST "$url" \
        -H "client_id: $client_id" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $authorization" \
        -d "$payload")
    local code=$(echo "$response" | grep -o '"code"[ ]*:[ ]*[0-9]*' | grep -o '[0-9]*')
    log "添加测试版本软件包接口返回: $response"
    if [ "$code" = "0" ]; then
        local pkgVersion=$(echo "$response" | grep -o '"pkgVersion"[ ]*:[ ]*\[.*\]' | sed 's/.*\[\(.*\)\].*/\1/' | tr -d '"' | awk -F, '{print $1}')
        echo "$pkgVersion"
    else
        log "Request failed or code != 0"
        return 1
    fi
}

# 更新测试包版本，PUT请求，返回 code=0 表示成功
# 用法: put_test_version <versionId>
put_test_version() {
  log "调用更新测试包版本接口..."
  local versionId="$1"
  local now=$(date +%s)
  local startTime=$((now * 1000))
  local endTime=$(( (now + 2592000) * 1000 )) # 30天后
  local url="https://connect-api.cloud.huawei.com/api/publish/v2/test/app/version?appId=${appId}"
  local groupInfosJson=""
  for gid in "${groupIds[@]}"; do
    groupInfosJson+="{ \"groupId\": \"$gid\" },"
  done
  groupInfosJson="${groupInfosJson%,}"
  local payload="{ \"versionId\": \"${versionId}\", \"deviceTypes\": [ { \"deviceType\": 4, \"appAdapters\": \"\" } ], \"openTestInfo\": { \"startTime\": ${startTime}, \"endTime\": ${endTime}, \"testDesc\": \"${test_desc}\", \"testTaskInfo\": { \"groupInfos\": [ ${groupInfosJson} ], \"needShareLink\": 1, \"displayArea\": \"1\" } } } }"
  log "请求参数: url=$url, payload=$payload"
  local response=$(curl -s -X PUT "$url" \
    -H "client_id: $client_id" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $authorization" \
    -d "$payload")
  local code=$(echo "$response" | grep -o '"code"[ ]*:[ ]*[0-9]*' | grep -o '[0-9]*')
  log "更新测试包版本接口返回: $response"
  if [ "$code" = "0" ]; then
    echo "success"
  else
    log "Request failed or code != 0"
    return 1
  fi
}

# 提交测试版本，POST请求，返回 code=0 表示成功
# 用法: submit_test_version <versionId>
submit_test_version() {
  log "调用提交测试版本接口..."
  local versionId="$1"
  local url="https://connect-api.cloud.huawei.com/api/publish/v2/test/app/version/submit?appId=${appId}"
  local payload="{ \"versionId\": \"${versionId}\" }"
  log "请求参数: url=$url, payload=$payload"
  local response=$(curl -s -X POST "$url" \
    -H "client_id: $client_id" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $authorization" \
    -d "$payload")
  local code=$(echo "$response" | grep -o '"code"[ ]*:[ ]*[0-9]*' | grep -o '[0-9]*')
  log "提交测试版本接口返回: $response"
  if [ "$code" = "0" ]; then
    echo "success"
  else
    log "Request failed or code != 0"
    return 1
  fi
}

# 获取上传文件URL
# 用法: get_upload_file_url <fileName> <contentLength>
get_upload_file_url() {
  log "调用获取上传文件URL接口..."
  local fileName="$1"
  local contentLength="$2"
  local url="https://connect-api.cloud.huawei.com/api/publish/v2/upload-url/for-obs?appId=${appId}&fileName=${fileName}&contentLength=${contentLength}"
  log "请求参数: url=$url"
  local response=$(curl -s -X GET "$url" \
    -H "client_id: $client_id" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $authorization")
  local code=$(echo "$response" | grep -o '"code"[ ]*:[ ]*[0-9]*' | grep -o '[0-9]*')
  log "获取上传文件URL接口返回: $response"
  if [ "$code" = "0" ]; then
    echo "$response"
  else
    log "Request failed or code != 0"
    return 1
  fi
}

# 使用 get_upload_file_url 返回的信息上传文件
# 用法: upload_file_to_obs <filePath> <fileName> <contentLength>
upload_file_to_obs() {
  log "调用上传文件到OBS接口..."
  local filePath="$1"
  local fileName="$2"
  local contentLength="$3"
  log "请求参数: filePath=$filePath, fileName=$fileName, contentLength=$contentLength"
  local response=$(get_upload_file_url "$fileName" "$contentLength")
  local code=$(echo "$response" | grep -o '"code"[ ]*:[ ]*[0-9]*' | grep -o '[0-9]*')
  log "上传文件到OBS接口获取URL返回: $response"
  if [ "$code" != "0" ]; then
    log "Failed to get upload URL"
    return 1
  fi
  local url=$(echo "$response" | grep -o '"url"[ ]*:[ ]*"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  local objectId=$(echo "$response" | grep -o '"objectId"[ ]*:[ ]*"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  local headers_json=$(echo "$response" | grep -o '"headers"[ ]*:[ ]*{[^}]*}' | sed 's/.*: *{\(.*\)}/\1/')
  local header_args=()
  # 解析 headers_json 为 curl header 参数
  while IFS=, read -ra kvs; do
    for kv in "${kvs[@]}"; do
      key=$(echo "$kv" | awk -F: '{print $1}' | tr -d '" ')
      value=$(echo "$kv" | awk -F: '{print $2}' | tr -d '" ')
      header_args+=("-H" "$key: $value")
    done
  done <<< "$headers_json"
  log "开始上传文件到OBS..."
  curl -s -X PUT "$url" "${header_args[@]}" --data-binary "@$filePath" -H "Content-Length: $contentLength" -H "Content-Type: application/octet-stream"
  echo "$objectId"
}

# 日志记录函数
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 主流程入口
if [[ "$filePath" != "" ]]; then
  log "开始处理文件: $filePath"
  fileName="$(basename "$filePath")"
  log "文件名: $fileName"
  contentLength=$(stat -f%z "$filePath")
  log "文件大小: $contentLength 字节"
  log "开始上传文件..."
  objectId=$(upload_file_to_obs "$filePath" "$fileName" "$contentLength")
  log "上传完成，objectId: $objectId"
  if [[ -z "$objectId" ]]; then
    log "Failed to upload file and get objectId"
    exit 1
  fi
  log "新建测试版本..."
  versionId=$(new_test_version)
  log "新建版本完成，versionId: $versionId"
  if [[ -z "$versionId" ]]; then
    log "Failed to create new test version"
    exit 1
  fi
  log "添加测试版本软件包..."
  pkgVersion=$(add_test_version_package "$objectId")
  log "添加软件包完成，pkgVersion: $pkgVersion"
  if [[ -z "$pkgVersion" ]]; then
    log "Failed to add test version package"
    exit 1
  fi
  log "更新测试版本..."
  if ! put_test_version "$versionId"; then
    log "Failed to update test version"
    exit 1
  fi
  log "测试版本已更新"
  log "提交测试版本..."
  if ! submit_test_version "$versionId"; then
    log "Failed to submit test version"
    exit 1
  fi
  log "测试版本已提交"
else
  log "Usage: $0 <filePath>"
  exit 1
fi

# 示例调用
# new_test_version
# upload_pkg "********.app" "CN/2024052102/********.app"
# put_test_version "1425*********60" "1426********56"
# submit_test_version "1418********32"
# get_upload_file_url "yourfile.app" "123456"
# upload_file_to_obs "/path/to/yourfile.app" "yourfile.app" "123456"
