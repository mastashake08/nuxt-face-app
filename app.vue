<template>
  <div class="container mx-auto p-8">
    <h1 class="text-4xl font-bold text-center mb-8 text-gray-800">Face Filter App with Custom SVG Filters and Media Recording</h1>

    <!-- File upload for image or video -->
    <div class="flex justify-center mb-8">
      <input class="file-input" type="file" @change="onFileChange" accept="image/*,video/*" />
    </div>

    <!-- File upload for SVG -->
    <div class="flex justify-center mb-8">
      <input class="file-input" type="file" @change="onSvgUpload" accept=".svg" />
    </div>

    <!-- Dropdown for SVG filter IDs -->
    <div class="text-center mb-8" v-if="filterIds.length > 0">
      <label for="filterDropdown" class="block text-gray-600 font-medium">Select an SVG Filter:</label>
      <select id="filterDropdown" v-model="selectedFilterId" class="border border-gray-300 p-2 w-full rounded-lg shadow-md">
        <option v-for="id in filterIds" :key="id" :value="'#' + id">{{ id }}</option>
      </select>
    </div>

    <!-- Canvas to display image or video with filters -->
    <div class="flex justify-center mb-8">
      <canvas class="border-2 border-gray-400 shadow-lg" ref="canvas" :width="canvasWidth" :height="canvasHeight"></canvas>
    </div>

    <!-- Button to export video -->
    <div v-if="isVideo" class="mt-4 text-center">
      <button @click="exportVideo" class="bg-green-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-green-400 transition duration-200">Export 5s Video</button>
    </div>

    <!-- Injected SVG container -->
    <svg style="display:none;" ref="svgContainer"></svg>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const canvas = ref(null)
const canvasWidth = ref(800)
const canvasHeight = ref(600)
const selectedFilterId = ref('') // Selected filter ID from the SVG
const svgContainer = ref(null) // Hidden SVG container for uploaded SVG filters
const videoElement = ref(null) // Video element for video playback
let animationFrameId = null;
let imageSrc = ref(null); // For handling image upload
let videoSrc = ref(null); // For handling video upload
let isVideo = ref(false); // Flag to check if the upload is a video
const faces = ref([]); // Store detected faces
const filterIds = ref([]); // Store filter IDs from the uploaded SVG

let faceDetector = null; // To initialize the FaceDetector API

// Set up FaceDetector API on mounted (if available)
onMounted(() => {
  if ('FaceDetector' in window) {
    faceDetector = new window.FaceDetector()
  } else {
    console.warn("FaceDetector API is not supported in this browser.")
  }
})

// Handle file change (image or video)
const onFileChange = (event) => {
  const file = event.target.files[0]
  if (file) {
    const fileType = file.type.split('/')[0]
    if (fileType === 'video') {
      isVideo.value = true;
      loadVideo(file)
    } else if (fileType === 'image') {
      isVideo.value = false;
      loadImage(file)
    }
  }
}

// Load video onto the canvas and start playing
const loadVideo = (file) => {
  const video = document.createElement('video')
  video.src = URL.createObjectURL(file)
  video.loop = true
  video.muted = true
  video.play()

  video.onloadeddata = () => {
    videoElement.value = video;
    renderVideoWithFilter()
  }
}

// Load image onto the canvas and detect faces
const loadImage = (file) => {
  imageSrc.value = URL.createObjectURL(file)
  const img = new Image()
  img.src = imageSrc.value

  img.onload = async () => {
    const context = canvas.value.getContext('2d')
    context.clearRect(0, 0, canvasWidth.value, canvasHeight.value)
    context.drawImage(img, 0, 0, canvasWidth.value, canvasHeight.value)
    
    // Detect faces if the FaceDetector API is available
    if (faceDetector) {
      faces.value = await faceDetector.detect(img)
      applyFilterToFaces(img)
    } else {
      console.warn('FaceDetector is not available.')
    }
  }
}

// Apply filter to detected faces
const applyFilterToFaces = (img) => {
  const context = canvas.value.getContext('2d')
  context.clearRect(0, 0, canvasWidth.value, canvasHeight.value)

  // Draw image first
  context.drawImage(img, 0, 0, canvasWidth.value, canvasHeight.value)

  // Draw faces with the selected filter
  faces.value.forEach(face => {
    const { width, height, top, left } = face.boundingBox
    context.save()
    context.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'
    context.drawImage(img, left, top, width, height, left, top, width, height)
    context.restore()
  })
}

// Handle SVG file upload, extract filter IDs, and inject it into the hidden SVG container
const onSvgUpload = (event) => {
  const file = event.target.files[0]
  if (file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      const parser = new DOMParser()
      const svgDoc = parser.parseFromString(e.target.result, 'image/svg+xml')
      const filters = svgDoc.querySelectorAll('filter')

      // Extract filter IDs and populate the dropdown
      filterIds.value = Array.from(filters).map(filter => filter.id)

      // Inject the SVG into the hidden container
      svgContainer.value.outerHTML = e.target.result
    }
    reader.readAsText(file)
  }
}

// Function to render video with the selected SVG filter
const renderVideoWithFilter = () => {
  const context = canvas.value.getContext('2d')

  const renderFrame = () => {
    context.clearRect(0, 0, canvasWidth.value, canvasHeight.value)

    if (videoElement.value) {
      // Apply the selected SVG filter to the video
      context.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'
      context.drawImage(videoElement.value, 0, 0, canvasWidth.value, canvasHeight.value)
    }

    animationFrameId = requestAnimationFrame(renderFrame) // Keep rendering frames
  }

  // Start the animation loop for the video playback
  animationFrameId = requestAnimationFrame(renderFrame)
}

// Export 5-second video with applied filter
const exportVideo = () => {
  const canvasElement = canvas.value
  const stream = canvasElement.captureStream(30) // Capture at 30fps
  const mediaRecorder = new MediaRecorder(stream, { mimeType: 'video/webm' })
  const chunks = []

  mediaRecorder.ondataavailable = (event) => {
    if (event.data.size > 0) {
      chunks.push(event.data)
    }
  }

  mediaRecorder.onstop = () => {
    const blob = new Blob(chunks, { type: 'video/webm' })
    const videoUrl = URL.createObjectURL(blob)

    // Create a download link
    const link = document.createElement('a')
    link.href = videoUrl
    link.download = 'filtered-video.webm'
    link.click()
  }

  // Record for 5 seconds
  mediaRecorder.start()
  setTimeout(() => {
    mediaRecorder.stop()
  }, 5000)
}

// Stop the animation when needed (e.g., when switching files)
const stopAnimation = () => {
  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId)
    animationFrameId = null
  }
}
</script>

<style scoped>
.file-input {
  padding: 0.5rem;
  border: 2px solid #ccc;
  border-radius: 0.5rem;
  cursor: pointer;
}
</style>
