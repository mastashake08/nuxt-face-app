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

    <!-- Filter options -->
    <div class="flex justify-center space-x-4 mb-8">
      <label class="inline-flex items-center">
        <input type="checkbox" v-model="applyToFaces" />
        <span class="ml-2">Apply to Faces</span>
      </label>
      <label class="inline-flex items-center">
        <input type="checkbox" v-model="applyToBackground" />
        <span class="ml-2">Apply to Background</span>
      </label>
      <label class="inline-flex items-center">
        <input type="checkbox" v-model="applyToFullCanvas" />
        <span class="ml-2">Apply to Full Canvas</span>
      </label>
    </div>

    <!-- Toggle button for landmarks and bounding boxes -->
    <div class="text-center mb-8">
      <button @click="toggleFaceLandmarks" class="bg-gray-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-gray-400 transition duration-200">
        {{ showLandmarks ? 'Hide Landmarks/Bounding Box' : 'Show Landmarks/Bounding Box' }}
      </button>
    </div>

    <!-- Canvas to display image or video with filters -->
    <div class="flex justify-center mb-8">
      <canvas class="border-2 border-gray-400 shadow-lg" ref="mainCanvas"></canvas>
    </div>

    <!-- Hidden face canvas -->
    <canvas ref="faceCanvas" style="display:none;"></canvas>

    <!-- Buttons for downloading and exporting -->
    <div class="text-center space-y-4">
      <button @click="downloadImage" class="bg-blue-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-blue-400 transition duration-200">Download Image</button>
      <button v-if="isVideo" @click="exportVideo" class="bg-green-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-green-400 transition duration-200">Export Video</button>
    </div>

    <!-- Injected SVG container -->
    <svg style="display:none;" ref="svgContainer"></svg>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const mainCanvas = ref(null)
const faceCanvas = ref(null)
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
let mediaRecorder = null; // Store MediaRecorder instance
let recordedChunks = []; // Store video recording chunks
let showLandmarks = ref(true); // To toggle visibility of landmarks and bounding boxes
let applyToFaces = ref(true); // Apply filter to faces
let applyToBackground = ref(false); // Apply filter to background
let applyToFullCanvas = ref(false); // Apply filter to full canvas

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
    resizeCanvas(1024, 1024);
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

    resizeCanvas(img.width, img.height);

    const context = mainCanvas.value.getContext('2d')
    context.clearRect(0, 0, mainCanvas.value.width, mainCanvas.value.height)

    // Detect faces if the FaceDetector API is available
    if (faceDetector) {
      faces.value = await faceDetector.detect(img)
      startImageAnimation()
    } else {
      console.warn('FaceDetector is not available.')
      context.drawImage(img, 0, 0, mainCanvas.value.width, mainCanvas.value.height)
    }
  }
}

// Resize the canvas based on the dimensions of the uploaded media
const resizeCanvas = (width, height) => {
  mainCanvas.value.width = width
  mainCanvas.value.height = height
  faceCanvas.value.width = width
  faceCanvas.value.height = height
}

// Apply the filter and animate the image like a video
const startImageAnimation = () => {
  const mainContext = mainCanvas.value.getContext('2d')
  const faceContext = faceCanvas.value.getContext('2d')

  const animateImage = () => {
    mainContext.clearRect(0, 0, mainCanvas.value.width, mainCanvas.value.height)

    if (applyToFullCanvas.value) {
      // Apply filter to the full canvas
      mainContext.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'
      mainContext.drawImage(currentImage, 0, 0, mainCanvas.value.width, mainCanvas.value.height)
    } else {
      // Draw the image without filter
      mainContext.filter = 'none'
      mainContext.drawImage(currentImage, 0, 0, mainCanvas.value.width, mainCanvas.value.height)

      // Apply filter to the faces only
      if (applyToFaces.value) {
        faces.value.forEach((face) => {
          const { width, height, top, left } = face.boundingBox

          // Clear face canvas before redrawing
          faceContext.clearRect(0, 0, faceCanvas.value.width, faceCanvas.value.height)

          // Draw the face region on the face canvas
          faceContext.drawImage(currentImage, left, top, width, height, left, top, width, height)

          // Apply the filter only on the face canvas
          faceContext.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'

          // Grab face data from face canvas and put it back on the main canvas
          const faceImageData = faceContext.getImageData(left, top, width, height)
          mainContext.putImageData(faceImageData, left, top)
        })
      }

      // Apply filter to the background if selected
      if (applyToBackground.value) {
        mainContext.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'
        mainContext.drawImage(currentImage, 0, 0, mainCanvas.value.width, mainCanvas.value.height)
      }
    }

    // Draw faces and landmarks if enabled
    if (showLandmarks.value) {
      drawFacesAndLandmarks(mainContext)
    }

    animationFrameId = requestAnimationFrame(animateImage) // Loop the animation
  }

  // Start the animation loop for the image
  animationFrameId = requestAnimationFrame(animateImage)
}

// Draw face bounding boxes and landmarks if available
const drawFacesAndLandmarks = (context) => {
  faces.value.forEach((face) => {
    const { width, height, top, left } = face.boundingBox

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
  const context = mainCanvas.value.getContext('2d')

  const renderFrame = () => {
    context.clearRect(0, 0, mainCanvas.value.width, mainCanvas.value.height)

    if (videoElement.value) {
      // Apply the selected SVG filter to the video
      context.filter = selectedFilterId.value ? `url(${selectedFilterId.value})` : 'none'
      context.drawImage(videoElement.value, 0, 0, mainCanvas.value.width, mainCanvas.value.height)
    }

    animationFrameId = requestAnimationFrame(renderFrame) // Keep rendering frames
  }

  // Start the animation loop for the video playback
  animationFrameId = requestAnimationFrame(renderFrame)
}

// Toggle the visibility of face landmarks and bounding boxes
const toggleFaceLandmarks = () => {
  showLandmarks.value = !showLandmarks.value
}

// Export the full video length with applied filter
const exportVideo = () => {
  const canvasElement = mainCanvas.value
  const stream = canvasElement.captureStream(30) // Capture at 30fps
  mediaRecorder = new MediaRecorder(stream, { mimeType: 'video/webm' })

  mediaRecorder.ondataavailable = (event) => {
    if (event.data.size > 0) {
      recordedChunks.push(event.data)
    }
  }

  mediaRecorder.onstop = () => {
    const blob = new Blob(recordedChunks, { type: 'video/webm' })
    const videoUrl = URL.createObjectURL(blob)

    // Create a download link
    const link = document.createElement('a')
    link.href = videoUrl
    link.download = 'filtered-video.webm'
    link.click()

    // Clear recorded chunks after saving the video
    recordedChunks = []
  }

  // Start recording the video
  mediaRecorder.start()

  // Stop recording when the video ends
  videoElement.value.onended = () => {
    mediaRecorder.stop()
  }
}

// Function to download the current canvas as an image
const downloadImage = () => {
  const link = document.createElement('a')
  link.download = 'filtered-image.png'
  link.href = mainCanvas.value.toDataURL('image/png')
  link.click()
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
