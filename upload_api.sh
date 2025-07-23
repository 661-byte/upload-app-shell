#!/bin/bash
# upload_api.sh
# 获取上传文件URL和上传文件到OBS的相关方法

# 获取上传文件URL
# 用法: get_upload_file_url <fileName> <contentLength> <appId> <client_id> <authorization>
get_upload_file_url() {
  local fileName="$1"
  local contentLength="$2"
  local appId="$3"
  local client_id="$4"
  local authorization="$5"
  local url="https://connect-api.cloud.huawei.com/api/publish/v2/upload-url/for-obs?appId=${appId}&fileName=${fileName}&contentLength=${contentLength}"
  local response=$(curl -s -X GET "$url" \
    -H "client_id: $client_id" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $authorization")
  echo "$response"
}

# 使用 get_upload_file_url 返回的信息上传文件
# 用法: upload_file_to_obs <filePath> <fileName> <contentLength> <appId> <client_id> <authorization>
upload_file_to_obs() {
  local filePath="$1"
  local fileName="$2"
  local contentLength="$3"
  local appId="$4"
  local client_id="$5"
  local authorization="$6"
  local response=$(get_upload_file_url "$fileName" "$contentLength" "$appId" "$client_id" "$authorization")
  local code=$(echo "$response" | grep -o '"code"[ ]*:[ ]*[0-9]*' | grep -o '[0-9]*')
  if [ "$code" != "0" ]; then
    echo "Failed to get upload URL"
    return 1
  fi
  local url=$(echo "$response" | grep -o '"url"[ ]*:[ ]*"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  local objectId=$(echo "$response" | grep -o '"objectId"[ ]*:[ ]*"[^"]*"' | sed 's/.*: *"\([^"]*\)".*/\1/')
  local headers_json=$(echo "$response" | grep -o '"headers"[ ]*:[ ]*{[^}]*}' | sed 's/.*: *{\(.*\)}/\1/')
  local header_args=()
  while IFS=, read -ra kvs; do
    for kv in "${kvs[@]}"; do
      key=$(echo "$kv" | awk -F: '{print $1}' | tr -d '" ')
      value=$(echo "$kv" | awk -F: '{print $2}' | tr -d '" ')
      header_args+=("-H" "$key: $value")
    done
  done <<< "$headers_json"
  curl -s -X PUT "$url" "${header_args[@]}" --data-binary "@$filePath" -H "Content-Length: $contentLength" -H "Content-Type: application/octet-stream"
  echo "$objectId"
}

# 允许被其他脚本 source 调用
