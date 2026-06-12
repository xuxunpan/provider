# AGENTS.md

## 项目概述

AI Provider - AI图片生成平台。用户上传参考图+文本提示词，系统调用 OpenAI GPT-4o Vision + DALL-E 3 生成新图片。支持用户注册/登录，查看历史记录。

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Vue 3 (Composition API, `<script setup lang="ts">`), TypeScript, Vite, Pinia, Vue Router, Axios |
| 后端 | FastAPI (Python 3.11), Motor (MongoDB async), Pydantic v2, python-jose (JWT) |
| 后端HK | FastAPI (Python 3.11), OpenAI SDK, httpx |
| 基础设施 | Docker Compose (MongoDB 7, Nginx, 3个应用服务) |

## 目录结构

```
frontend/          # Vue 3 + Vite + TypeScript 前端
  src/
    api/           # Axios 实例 (/api/v1)
    router/        # Vue Router 路由配置
    stores/        # Pinia 状态管理
    views/         # 页面组件 (Login, Register, Dashboard)
backend/           # FastAPI 国内后端 (auth, 图片管理, 代理HK)
  app/
    models/        # Pydantic 数据模型
    routes/        # API 路由
    services/      # 业务逻辑层
    utils/         # 工具函数
backend-hk/        # FastAPI HK后端 (调用OpenAI API)
  app/
    routes/        # OpenAI 图像生成路由
script_dev/        # Windows 开发启动脚本 (.bat)
```

## 常用命令

### 前端 (frontend/)
```bash
npm run dev      # 启动 Vite 开发服务器 (http://localhost:5173)
npm run build    # 类型检查 + 生产构建 (vue-tsc -b && vite build)
npm run preview  # 预览生产构建
```

### 后端 (backend/, backend-hk/)
```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000    # 国内后端
uvicorn app.main:app --reload --port 8001    # HK后端
```

### Docker
```bash
docker compose up -d    # 启动全部服务
docker compose down     # 停止全部服务
```

## 代码规范

### 前端
- 必须使用 `<script setup lang="ts">` + Composition API，禁止 Options API
- Pinia store 使用 Composition API 风格 (`defineStore('name', () => { ... })`)
- 路径别名 `@/` 映射到 `src/`
- 使用 scoped CSS (`<style scoped>`)，全局样式在 `style.css`
- JWT 认证：token 存 localStorage，Axios 拦截器自动附加 Bearer token，401 跳转登录页
- 类型检查：`vue-tsc -b`（严格模式），无 ESLint/Prettier

### 后端
- Pydantic v2 模型 + `model_config` 配置
- FastAPI `Depends()` 依赖注入模式
- 路由层薄，业务逻辑在 `services/`
- 异步 MongoDB 操作 (Motor)
- 后端间通信使用 `X-API-Key` 内部认证
- 文件上传存本地 `uploads/` / `generated/`，通过 `StaticFiles` 提供

## 架构

```
浏览器 (Vue 3 SPA)
  └─ /api/v1/images/generate
       └─ Backend :8000
            ├─ 保存上传图片到 uploads/
            ├─ 创建 MongoDB 记录 (status: processing)
            └─ httpx → Backend-HK :8001 (X-API-Key)
                 ├─ GPT-4o Vision 描述参考图
                 ├─ DALL-E 3 生成图片
                 └─ 保存到 generated/
            └─ 更新 MongoDB 记录 (status: completed)
```

开发模式：Vite 代理 `/api` 和 `/uploads` 到 `localhost:8000`。生产模式：Nginx 代理。

## 重要规则

- **禁止提交 apikey 等敏感内容到 git 仓库**
- `.env` 文件已在 `.gitignore` 中，确保各种 key/token/secret 不进入版本控制
- 不要创建不必要的文档文件（README.md、CHANGELOG.md 等）除非明确要求
- 修改文件前先阅读文件内容，理解现有代码风格
- 优先使用 edit 工具修改现有文件，避免不必要的新文件创建
