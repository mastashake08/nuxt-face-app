<template>
  <div class="container mx-auto p-8">
    <h1 class="text-4xl font-bold text-center mb-8 text-gray-800">Face Filter App with Custom SVG Filters and Media Recording</h1>

    <!-- How To Use Section -->
    <div class="mb-8 p-6 bg-blue-100 border-l-4 border-blue-500 text-blue-700">
      <h2 class="text-2xl font-semibold mb-2">How to Use</h2>
      <ol class="list-decimal pl-6">
        <li>Upload an <strong>Image</strong> or <strong>Video</strong> by clicking the "Choose File" button under "Upload Image or Video."</li>
        <li>If you want to apply custom filters, upload an <strong>SVG file</strong> with filters by clicking the "Choose File" button under "Upload SVG."</li>
        <li>Once the SVG is uploaded, select a filter from the dropdown list to apply to the image or video.</li>
        <li>For images, detected faces will be highlighted, and the filter will be applied only to the detected faces.</li>
        <li>For videos, the filter will be applied to the entire video in real time.</li>
        <li>If you've uploaded a video, you can export the video with the applied filter by clicking the "Export 5s Video" button.</li>
      </ol>
    </div>

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
      <select id="filterDropdown" v-model="selectedFilterId" @change="applyFilter" class="border border-gray-300 p-2 w-full rounded-lg shadow-md">
        <option v-for="id in filterIds" :key="id" :value="'#' + id">{{ id }}</option>
      </select>
    </div>

    <!-- Display the number of detected faces -->
    <div v-if="faces.length > 0" class="text-center mb-4 text-xl font-semibold text-green-700">
      {{ faces.length }} face(s) detected.
    </div>

    <!-- Display the coordinates of detected faces and landmarks -->
    <div v-if="faces.length > 0" class="text-center text-gray-700 mb-4">
      <div v-for="(face, index) in faces" :key="index">
        Face {{ index + 1 }}: ({{ Math.round(face.boundingBox.left) }}, {{ Math.round(face.boundingBox.top) }})
        <ul class="mt-2">
          <li v-for="(landmark, lIndex) in face.landmarks" :key="lIndex">
            Landmark {{ lIndex + 1 }}: ({{ Math.round(landmark.locations[0].x) }}, {{ Math.round(landmark.locations[0].y) }})
          </li>
        </ul>
      </div>
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
let currentImage = null; // Store current image in memory for re-drawing

let faceDetector = null; // To initialize the FaceDetector API

// Set up FaceDetector API on mounted (if available)
onMounted(() => {
  if ('FaceDetector' in window) {
    faceDetector = new window.FaceDetector({ fastMode: true, maxDetectedFaces: 10 })
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
    currentImage = img; // Store the current image in memory

    const context = canvas.value.getContext('2d')
    context.clearRect(0, 0, canvasWidth.value, canvasHeight.value)

    // Detect faces if the FaceDetector API is available
    if (faceDetector) {
      faces.value = await faceDetector.detect(img)

      // Apply the filter to the image and start animation
      startImageAnimation()
    } else {
      console.warn('FaceDetector is not available.')
      context.drawImage(img, 0, 0, canvasWidth.value, canvasHeight.value)
    }
  }
}

// Apply the filter and animate the image like a video
const startImageAnimation = () => {
  const context = canvas.value.getContext('2d')

  const animateImage = () => {
    context.clearRect(0, 0, canvasWidth.value, canvasHeight.value)

    // Check if faces are detected
    if (faces.value.length > 0) {
      // Draw the image without the filter first
      context.drawImage(currentImage, 0, 0, canvasWidth.value, canvasHeight.value)

      // Apply the selected filter to the faces only
      faces.value.forEach((face) => {
        const { width, height, top, left, x, y } = face.boundingBox
        //context.save()
        context.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'
        context.drawImage(currentImage, x,y)
       // context.restore()
      })
    } else {
      // No faces detected, apply filter to the whole image
      context.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'
      context.drawImage(currentImage, 0, 0, canvasWidth.value, canvasHeight.value)
    }

    // Draw faces and landmarks
    drawFacesAndLandmarks(context)

    animationFrameId = requestAnimationFrame(animateImage) // Loop the animation
  }

  // Start the animation loop for the image
  animationFrameId = requestAnimationFrame(animateImage)
}

// Draw face bounding boxes and landmarks if available
const drawFacesAndLandmarks = (context) => {
  faces.value.forEach((face) => {
    const { width, height, top, left } = face.boundingBox
    //context.save()

    // Draw face bounding box
    context.strokeStyle = 'red'
    context.lineWidth = 2
    context.strokeRect(left, top, width, height)

    // Draw landmarks (eyes, nose, mouth) if available
    if (face.landmarks) {
      face.landmarks.forEach((landmark) => {
        context.fillStyle = 'blue'
        context.beginPath()
        context.arc(landmark.locations[0].x, landmark.locations[0].y, 4, 0, 2 * Math.PI)
        context.fill()
      })
    }

    //context.restore()
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
      svgContainer.value.innerHTML = e.target.result
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
