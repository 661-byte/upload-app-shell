## upload-app-shell

一个用于将 Harmony 应用上传到华为 AppGallery Connect 的 Shell 工具。

### 功能简介
- 自动化上传 Harmony 应用包到华为 AppGallery Connect。
- 支持命令行参数配置。
- 简化发布流程。

#### 详细功能列表
- 支持应用包上传
- 自动获取上传文件的 URL 并上传
- 新建测试版本
- 添加测试版本软件包
- 更新测试包版本（设置测试时间、分组等）
- 提交测试版本到 AppGallery Connect

### 安装方法
1. 克隆本仓库：
   ```bash
   git clone https://github.com/661-byte/upload-app-shell.git
   ```
2. 进入项目目录：
   ```bash
   cd upload-app-shell
   ```
3. 确保 `upload.sh` 有执行权限：
   ```bash
   chmod +x upload.sh
   ```

### 使用方法
```bash
./upload.sh <app_path>
```

> **备注：首次使用前请在 upload.sh 脚本内更新 appId、client_id、authorization 等认证信息为你自己的开发者账号信息。**

参数说明：
- `<app_path>`：Harmony 应用包路径

### 示例
```bash
./upload.sh ./myapp.app
```
