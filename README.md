Here's a **README** file for your Nuxt 3 app that uses face detection and applies dynamic SVG filters:

---

# Face Filter App with Custom SVG Filters and Video Export

This project is a Nuxt 3 web application that allows users to upload images, detect faces using the **FaceDetector API**, and apply animated or custom SVG filters to the detected faces or background. Users can also export the resulting canvas as a 5-second video.

## Features

- **Face Detection**: Automatically detects faces in the uploaded image using the **FaceDetector API**.
- **SVG Filters**: Apply custom SVG filters via `url()` or predefined filters like blur, sepia, grayscale, etc.
- **Real-time Animation**: Filters are dynamically animated using `requestAnimationFrame` to update the canvas in real-time.
- **Canvas Drawing**: Users can apply filters to the entire image, just the faces, or just the background.
- **Video Export**: Export the filtered canvas as a 5-second video in **WebM** format.

## Technologies Used

- **Nuxt 3**: Modern framework for Vue 3 with enhanced features.
- **Tailwind CSS**: Utility-first CSS framework for styling.
- **FaceDetector API**: Native browser API for detecting faces in images.
- **Canvas API**: For drawing and manipulating images and applying filters.
- **SVG Filters**: Custom SVG filters that can be injected into the DOM and applied using `url(#filter-id)`.
- **requestAnimationFrame**: For animating the canvas in real-time.
- **MediaRecorder API**: For capturing canvas frames and exporting them as a video.

## Getting Started

### Prerequisites

- **Node.js** (v14 or later)
- **NPM** or **Yarn**

### Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/your-username/face-filter-app.git
   cd face-filter-app
   ```

2. **Install dependencies**:

   ```bash
   npm install
   ```

   or

   ```bash
   yarn install
   ```

3. **Run the development server**:

   ```bash
   npm run dev
   ```

   or

   ```bash
   yarn dev
   ```

   The app should be running locally at `http://localhost:3000`.

### Building for Production

To create a production build of the app, run:

```bash
npm run build
npm run start
```

or

```bash
yarn build
yarn start
```

### Usage

1. **Upload an Image**: Click the upload button to select an image file. The app will detect faces in the image using the **FaceDetector API**.
   
2. **Apply Filters**:
   - Select whether to apply a predefined filter (e.g., blur, sepia, grayscale, etc.) or a **custom SVG filter**.
   - Choose whether to apply the filter to the **faces** or the **background**.
   
3. **Custom SVG Filters**:
   - Write your own custom SVG filter in the provided textarea.
   - Click **Inject Custom SVG** to apply your filter.
   - Example SVG filter:

     ```xml
     <filter id="customFilter">
       <feGaussianBlur stdDeviation="10" />
     </filter>
     ```

4. **Animate the Canvas**: The filter effect is animated using `requestAnimationFrame`, continuously updating the canvas.

5. **Export a 5-Second Video**:
   - Click **Export 5s Video** to capture the current animation and save it as a **WebM** video file.

## Customization

### Adding More Filters

You can easily add more predefined filters by updating the `getFilter()` function in the `applyFilter` method:

```javascript
const getFilter = (filterType) => {
  switch (filterType) {
    case 'blur':
      return 'blur(5px)';
    case 'grayscale':
      return 'grayscale(1)';
    case 'sepia':
      return 'sepia(1)';
    case 'invert':
      return 'invert(1)';
    case 'glow':
      return 'drop-shadow(0px 0px 10px rgba(255, 255, 0, 1))';
    case 'customSVG':
      return 'url(#customFilter)';
    default:
      return 'none';
  }
};
```

### Modifying the Canvas Animation

The animation loop is controlled via `requestAnimationFrame`. You can modify the animation logic inside the `animateCanvas()` function:

```javascript
const animateCanvas = () => {
  context.clearRect(0, 0, canvasWidth.value, canvasHeight.value);
  
  // Add your custom animation logic here

  animationFrameId = requestAnimationFrame(animateCanvas);
};
```

## Folder Structure

```bash
.
├── components        # Reusable Vue components
├── layouts           # Application layouts
├── pages             # Nuxt 3 page components
├── assets
│   └── css           # Tailwind CSS setup
├── static            # Static files
├── nuxt.config.ts    # Nuxt 3 configuration
└── package.json      # NPM dependencies and scripts
```

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for more details.

---

### Future Improvements

- **WebCam Support**: Allow users to apply filters in real-time via their webcam.
- **Filter Tweaks**: Add sliders for adjusting the intensity of filters dynamically.
- **Additional Export Formats**: Support for exporting in other video formats (e.g., MP4) or as GIFs.

---

Enjoy using the Face Filter App! If you have any questions or run into issues, feel free to create an issue on GitHub.

---

This **README** provides comprehensive instructions for installing, running, and using the Face Filter App, along with details about its key features and customization options.