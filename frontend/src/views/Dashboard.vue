<template>
  <div class="dashboard">
    <header class="header">
      <h1>AI Image Generator</h1>
      <div class="user-info">
        <span>{{ authStore.user?.email }}</span>
        <button class="btn-logout" @click="handleLogout">退出</button>
      </div>
    </header>

    <main class="main">
      <div class="generate-section">
        <h2>生成图片</h2>
        <div class="form-row">
          <div class="upload-zone" @click="triggerUpload" @dragover.prevent @drop.prevent="handleDrop">
            <input ref="fileInput" type="file" accept="image/*" @change="handleFileChange" hidden />
            <div v-if="!previewUrl" class="upload-placeholder">
              <span class="upload-icon">+</span>
              <p>点击或拖拽上传参考图片（可选）</p>
            </div>
            <img v-else :src="previewUrl" class="preview-image" />
          </div>
          <button v-if="previewUrl" class="btn-remove" @click.stop="removeImage">移除图片</button>
        </div>

        <div class="form-group">
          <label>描述文字</label>
          <textarea
            v-model="prompt"
            placeholder="描述你想生成的图片内容..."
            rows="4"
            required
          ></textarea>
        </div>

        <button class="btn-generate" :disabled="generating || !prompt.trim()" @click="handleGenerate">
          {{ generating ? '生成中...' : '开始生成' }}
        </button>

        <p v-if="error" class="error">{{ error }}</p>

        <div v-if="result" class="result-section">
          <h3>生成结果</h3>
          <img :src="result.generated_image_url" class="result-image" />
        </div>
      </div>

      <div class="history-section">
        <h2>生成历史</h2>
        <div v-if="history.length === 0" class="empty">暂无生成记录</div>
        <div v-else class="history-grid">
          <div v-for="item in history" :key="item._id" class="history-item">
            <img v-if="item.generated_image_url" :src="item.generated_image_url" />
            <div class="history-meta">
              <p class="prompt-text">{{ item.prompt }}</p>
              <span class="status" :class="item.status">{{ item.status }}</span>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api'

const router = useRouter()
const authStore = useAuthStore()

const fileInput = ref<HTMLInputElement>()
const selectedFile = ref<File | null>(null)
const previewUrl = ref('')
const prompt = ref('')
const generating = ref(false)
const error = ref('')
const result = ref<any>(null)
const history = ref<any[]>([])

function triggerUpload() {
  fileInput.value?.click()
}

function handleFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  if (input.files?.[0]) {
    setFile(input.files[0])
  }
}

function handleDrop(e: DragEvent) {
  const file = e.dataTransfer?.files?.[0]
  if (file) setFile(file)
}

function setFile(file: File) {
  selectedFile.value = file
  previewUrl.value = URL.createObjectURL(file)
}

function removeImage() {
  selectedFile.value = null
  previewUrl.value = ''
  if (fileInput.value) fileInput.value.value = ''
}

async function handleGenerate() {
  if (!prompt.value.trim()) return
  error.value = ''
  generating.value = true
  result.value = null

  try {
    const formData = new FormData()
    formData.append('prompt', prompt.value)
    if (selectedFile.value) {
      formData.append('image', selectedFile.value)
    }

    const { data } = await api.post('/images/generate', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    })
    result.value = data
    await loadHistory()
  } catch (e: any) {
    error.value = e.response?.data?.detail || '生成失败，请重试'
  } finally {
    generating.value = false
  }
}

async function loadHistory() {
  try {
    const { data } = await api.get('/images/history')
    history.value = data.items
  } catch {
    // ignore
  }
}

function handleLogout() {
  authStore.logout()
  router.push('/login')
}

onMounted(() => {
  loadHistory()
})
</script>

<style scoped>
.dashboard {
  min-height: 100vh;
  background: #f0f2f5;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 32px;
  background: #fff;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.08);
}

.header h1 {
  font-size: 20px;
  color: #1a1a2e;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 14px;
  color: #666;
}

.btn-logout {
  padding: 6px 16px;
  background: transparent;
  border: 1px solid #ddd;
  border-radius: 6px;
  color: #666;
  font-size: 13px;
}

.btn-logout:hover {
  background: #f5f5f5;
}

.main {
  max-width: 900px;
  margin: 24px auto;
  padding: 0 20px;
}

.generate-section {
  background: #fff;
  padding: 28px;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  margin-bottom: 24px;
}

.generate-section h2 {
  margin-bottom: 20px;
  font-size: 18px;
}

.upload-zone {
  border: 2px dashed #d0d5dd;
  border-radius: 10px;
  padding: 32px;
  text-align: center;
  cursor: pointer;
  transition: border-color 0.2s;
}

.upload-zone:hover {
  border-color: #4f46e5;
}

.upload-placeholder {
  color: #999;
}

.upload-icon {
  font-size: 40px;
  display: block;
  margin-bottom: 8px;
}

.preview-image {
  max-width: 100%;
  max-height: 200px;
  border-radius: 8px;
}

.btn-remove {
  margin-top: 8px;
  padding: 4px 12px;
  background: #fee2e2;
  color: #e53e3e;
  border: none;
  border-radius: 6px;
  font-size: 13px;
}

.form-group {
  margin-top: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  font-size: 14px;
  color: #555;
}

textarea {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 15px;
  resize: vertical;
  font-family: inherit;
}

textarea:focus {
  outline: none;
  border-color: #4f46e5;
}

.btn-generate {
  width: 100%;
  padding: 14px;
  background: #4f46e5;
  color: #fff;
  border: none;
  border-radius: 8px;
  font-size: 16px;
  margin-top: 16px;
  transition: background 0.2s;
}

.btn-generate:hover:not(:disabled) {
  background: #4338ca;
}

.btn-generate:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.error {
  color: #e53e3e;
  font-size: 14px;
  margin-top: 12px;
}

.result-section {
  margin-top: 24px;
}

.result-section h3 {
  margin-bottom: 12px;
}

.result-image {
  max-width: 100%;
  border-radius: 10px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.history-section {
  background: #fff;
  padding: 28px;
  border-radius: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.history-section h2 {
  margin-bottom: 16px;
  font-size: 18px;
}

.empty {
  color: #999;
  text-align: center;
  padding: 32px 0;
}

.history-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
}

.history-item {
  border: 1px solid #eee;
  border-radius: 8px;
  overflow: hidden;
}

.history-item img {
  width: 100%;
  height: 150px;
  object-fit: cover;
}

.history-meta {
  padding: 10px;
}

.prompt-text {
  font-size: 13px;
  color: #555;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 12px;
  margin-top: 4px;
}

.status.completed {
  background: #e6f7e6;
  color: #38a169;
}

.status.failed {
  background: #fee2e2;
  color: #e53e3e;
}

.status.processing {
  background: #fefcbf;
  color: #d69e2e;
}
</style>
