<template>
  <div class="container mx-auto p-8">
    <h1 class="text-4xl font-bold text-center mb-8 text-gray-800">Face Filter App with Animated SVG Filters</h1>

    <!-- File upload -->
    <div class="flex justify-center mb-8">
      <input class="file-input" type="file" @change="onFileChange" accept="image/*" />
    </div>

    <!-- Canvas to display image and apply filters -->
    <div class="flex justify-center mb-8">
      <canvas class="border-2 border-gray-400 shadow-lg" ref="canvas" :width="canvasWidth" :height="canvasHeight"></canvas>
    </div>

    <!-- Filter options and controls -->
    <div v-if="faces.length > 0" class="text-center space-y-4">
      <h2 class="text-xl font-semibold text-gray-700">Detected Faces: {{ faces.length }}</h2>

      <!-- Filter control -->
      <div class="space-y-2">
        <label for="filter" class="block text-gray-600 font-medium">Choose Filter:</label>
        <select id="filter" v-model="selectedFilter" class="border border-gray-300 p-2 rounded-lg shadow-md">
          <option value="none">None</option>
          <option value="url">Use Custom SVG Filter</option>
        </select>
      </div>

      <!-- Apply filter to: face or background -->
      <div class="space-y-2">
        <label class="block text-gray-600 font-medium">Apply Filter to:</label>
        <select v-model="applyTo" class="border border-gray-300 p-2 rounded-lg shadow-md">
          <option value="faces">Faces</option>
          <option value="background">Background</option>
        </select>
      </div>

      <!-- Textarea for custom SVG filter -->
      <div class="space-y-2">
        <label for="customSvg" class="block text-gray-600 font-medium">Write Custom SVG Filter:</label>
        <textarea id="customSvg" v-model="customSvgText" class="border border-gray-300 p-2 w-full rounded-lg shadow-md" placeholder="Enter SVG filter code..."></textarea>
        <button @click="injectCustomSvg" class="bg-indigo-600 text-white px-4 py-2 rounded-lg shadow-md hover:bg-indigo-500 transition duration-200">Inject Custom SVG</button>
      </div>

      <!-- Button to apply filters -->
      <div class="mt-4">
        <button @click="applyFilter" class="bg-blue-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-blue-400 transition duration-200">Apply Filter</button>
      </div>

      <!-- Button to export video -->
      <div class="mt-4">
        <button @click="exportVideo" class="bg-green-500 text-white px-4 py-2 rounded-lg shadow-md hover:bg-green-400 transition duration-200">Export 10s Video</button>
      </div>
    </div>

    <!-- Injected SVG container -->
    <svg style="display:none;" xmlns="http://www.w3.org/2000/svg" ref="svgContainer">
      <!-- The user's custom SVG filter will be injected here -->
    </svg>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const canvas = ref(null)
const canvasWidth = ref(800)
const canvasHeight = ref(600)
const imageSrc = ref(null)
const faces = ref([])
const selectedFilter = ref('none')
const applyTo = ref('faces')
const customSvgText = ref('') // Text input for custom SVG filter code
let faceDetector
const svgContainer = ref(null) // Ref for the injected SVG

let animationFrameId = null;
onMounted(() => {
  faceDetector  = new window.FaceDetector()
})
const onFileChange = async (event) => {
  const file = event.target.files[0]
  if (file) {
    imageSrc.value = URL.createObjectURL(file)
    await detectFaces()
  }
}

const detectFaces = async () => {
  const img = new Image()
  img.src = imageSrc.value
  img.onload = async () => {
    const context = canvas.value.getContext('2d')
    context.clearRect(0, 0, canvasWidth.value, canvasHeight.value)
    context.drawImage(img, 0, 0, canvasWidth.value, canvasHeight.value)

    // Detect faces
    faces.value = await faceDetector.detect(img)
    console.log('Detected faces:', faces.value)
  }
}

// Function to inject custom SVG filter into the DOM
const injectCustomSvg = () => {
  svgContainer.value.innerHTML = customSvgText.value // Inject the custom SVG filter into the hidden <svg>
  console.log('Injected custom SVG filter:', customSvgText.value)
}

// Function to apply the custom filter and animate
const applyFilter = () => {
  const context = canvas.value.getContext('2d');
  const img = new Image();
  img.src = imageSrc.value;

  let animationStep = 0;

  const animateCanvas = () => {
    context.clearRect(0, 0, canvasWidth.value, canvasHeight.value);
    const animatedFilterValue = (Math.sin(animationStep / 25) + 1) * 5; // Dynamic value for filters
    animationStep++;
    // Apply animation logic (e.g., oscillate the effect using sine wave)
    const filterUrl = selectedFilter.value === 'url' ?  `url(#customFilter) blur(${animatedFilterValue}px)` : 'none';

    // Draw based on background or faces selection
    if (applyTo.value === 'background') {
      context.save();
      context.filter = filterUrl; // Apply SVG filter to background
      context.drawImage(img, 0, 0, canvasWidth.value, canvasHeight.value);
      context.restore();

      // Draw faces without the filter
      faces.value.forEach((face) => {
        const { width, height, top, left } = face.boundingBox;
        context.save();
        context.filter = 'none'; // No filter for faces
        context.drawImage(img, left, top, width, height, left, top, width, height);
        context.restore();
      });
    } else if (applyTo.value === 'faces') {
      // Draw entire image without filter
      context.drawImage(img, 0, 0, canvasWidth.value, canvasHeight.value);

      // Apply filter to faces only
      faces.value.forEach((face) => {
        const { width, height, top, left } = face.boundingBox;
        context.save();
        context.filter = filterUrl; // Apply SVG filter to faces only
        context.drawImage(img, left, top, width, height, left, top, width, height);
        context.restore();
      });
    }

    // Continue the animation loop
    animationFrameId = requestAnimationFrame(animateCanvas);
  };

  // Load image and start animation
  img.onload = () => {
    cancelAnimationFrame(animationFrameId); // Cancel any existing animation
    animationFrameId = requestAnimationFrame(animateCanvas);
  };
}

// Stop animation when not needed
const stopAnimation = () => {
  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId);
    animationFrameId = null;
  }
}

// Function to export the canvas as a video
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
  }, 10000)
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
