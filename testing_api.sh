# 引入 upload_api.sh
source "$(dirname "$0")/upload_api.sh"
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


# 主流程入口
if [[ "$filePath" != "" ]]; then
  log "开始处理文件: $filePath"
  fileName="$(basename "$filePath")"
  log "文件名: $fileName"
  contentLength=$(stat -f%z "$filePath")
  log "文件大小: $contentLength 字节"
  log "开始上传文件..."
  objectId=$(upload_file_to_obs "$filePath" "$fileName" "$contentLength" "$appId" "$client_id" "$authorization")
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
# ./testing_api.sh <your_app_file.app>
# 也可单独调用以下函数（需提前设置相关变量）：
# new_test_version
# add_test_version_package <objectId>
# put_test_version <versionId>
# submit_test_version <versionId>
