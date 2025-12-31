import * as THREE from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js"
import { ThreeSceneAdapter } from "@/lib/infrastructure/adapters/three-scene-adapter"
import type { ViewportStore } from "@/lib/stores/viewport-store"
import type { SelectionStore } from "@/lib/stores/selection-store"

export class ViewportRenderer {
  private renderer: THREE.WebGLRenderer
  private scene: THREE.Scene
  private camera: THREE.PerspectiveCamera
  private orbitControls: OrbitControls
  private transformControls: any | null = null
  private sceneAdapter: ThreeSceneAdapter
  private raycaster: THREE.Raycaster
  private mouse: THREE.Vector2
  private animationId: number | null = null

  constructor(
    canvas: HTMLCanvasElement,
    private viewportStore: ViewportStore,
    private selectionStore: SelectionStore,
  ) {
    // Setup renderer
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true })
    this.renderer.setPixelRatio(window.devicePixelRatio)
    this.renderer.setSize(canvas.clientWidth, canvas.clientHeight)
    this.renderer.shadowMap.enabled = true
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap

    // Setup scene
    this.scene = new THREE.Scene()
    this.scene.background = new THREE.Color(0x1a1a1a)

    // Setup camera
    this.camera = new THREE.PerspectiveCamera(60, canvas.clientWidth / canvas.clientHeight, 0.1, 1000)
    this.camera.position.set(10, 10, 10)
    this.camera.lookAt(0, 0, 0)

    // Setup lighting
    this.setupLighting()

    // Setup grid
    this.setupGrid()

    // Setup orbit controls
    this.orbitControls = new OrbitControls(this.camera, this.renderer.domElement)
    this.orbitControls.enableDamping = true
    this.orbitControls.dampingFactor = 0.05

    // Setup transform controls (dynamically import to avoid bundler/runtime issues)
    this.loadTransformControls()

    // Setup scene adapter
    this.sceneAdapter = new ThreeSceneAdapter()
    this.viewportStore.initializeAdapter(this.sceneAdapter)

    // Setup raycaster for picking
    this.raycaster = new THREE.Raycaster()
    this.mouse = new THREE.Vector2()

    // Event listeners
    this.setupEventListeners(canvas)

    // Observe viewport store changes
    this.observeViewportStore()

    // Handle window resize
    window.addEventListener("resize", this.handleResize)
  }

  private async loadTransformControls() {
    try {
      const mod = await import("three/examples/jsm/controls/TransformControls.js")
      const anyMod = mod as any

      // Handle different module export patterns
      let TransformControls: any = anyMod.TransformControls ?? anyMod.default ?? anyMod

      if (!TransformControls) {
        // eslint-disable-next-line no-console
        console.error("TransformControls not found in module:", Object.keys(mod), mod)
        // Try fallback to our simple implementation
        try {
          const fallback = await import("./simple-transform-controls")
          const SimpleTransformControls = (fallback as any).SimpleTransformControls ?? (fallback as any).default
          if (SimpleTransformControls) {
            const instance = new SimpleTransformControls(this.camera, this.renderer.domElement)
            this.transformControls = instance
            this.transformControls.addEventListener("dragging-changed", (event: any) => {
              this.orbitControls.enabled = !event.value
            })
            this.scene.add(this.transformControls)
            return
          }
        } catch (fallbackErr) {
          // eslint-disable-next-line no-console
          console.warn("Fallback SimpleTransformControls not available:", fallbackErr)
        }

        this.transformControls = null
        return
      }

      let instance: any = null

      // If it's a constructor, try to instantiate it
      if (typeof TransformControls === "function") {
        try {
          instance = new TransformControls(this.camera, this.renderer.domElement)
        } catch (err) {
          // Could not construct — log and fallthrough to treat as instance
          // eslint-disable-next-line no-console
          console.warn("TransformControls constructor threw, will treat export as instance if possible:", err)
          instance = null
        }
      } else if (typeof TransformControls === "object") {
        instance = TransformControls
      }

      const looksLikeObject3D = instance && (typeof instance.add === "function" || typeof instance.attach === "function" || typeof instance.updateMatrixWorld === "function")

      if (looksLikeObject3D) {
        this.transformControls = instance
        this.transformControls.addEventListener("dragging-changed", (event: any) => {
          this.orbitControls.enabled = !event.value
        })
        try {
          this.scene.add(this.transformControls)
        } catch (err) {
          // Adding failed likely due to cross-`three` instanceof checks. Log and continue without controls.
          // eslint-disable-next-line no-console
          console.warn("Could not add TransformControls to scene (possible multiple three instances):", err)
          this.transformControls = null
        }
      } else {
        // eslint-disable-next-line no-console
        console.error("TransformControls is not a recognizable Object3D instance. Module keys:", Object.keys(mod), { TransformControlsType: typeof TransformControls, instance, mod })
        this.transformControls = null
      }
    } catch (err) {
      // Fail gracefully and log for debugging
      // eslint-disable-next-line no-console
      console.error("Failed to load TransformControls:", err)
      this.transformControls = null
    }
  }

  private setupLighting() {
    // Ambient light
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.5)
    this.scene.add(ambientLight)

    // Directional light (sun)
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8)
    directionalLight.position.set(5, 10, 5)
    directionalLight.castShadow = true
    directionalLight.shadow.camera.near = 0.1
    directionalLight.shadow.camera.far = 50
    directionalLight.shadow.camera.left = -10
    directionalLight.shadow.camera.right = 10
    directionalLight.shadow.camera.top = 10
    directionalLight.shadow.camera.bottom = -10
    directionalLight.shadow.mapSize.width = 2048
    directionalLight.shadow.mapSize.height = 2048
    this.scene.add(directionalLight)
  }

  private setupGrid() {
    const gridHelper = new THREE.GridHelper(20, 20, 0x444444, 0x2a2a2a)
    this.scene.add(gridHelper)
  }

  private setupEventListeners(canvas: HTMLCanvasElement) {
    canvas.addEventListener("click", this.handleClick)
    canvas.addEventListener("mousemove", this.handleMouseMove)
  }

  private handleClick = (event: MouseEvent) => {
    const canvas = this.renderer.domElement
    const rect = canvas.getBoundingClientRect()

    this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1
    this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1

    this.raycaster.setFromCamera(this.mouse, this.camera)

    const sceneObjects = this.sceneAdapter.getThreeScene().children.filter((obj) => obj.type === "Group")
    const intersects = this.raycaster.intersectObjects(sceneObjects, true)

    if (intersects.length > 0) {
      // Find the top-level game object
      let selectedObj = intersects[0].object
      while (selectedObj.parent && selectedObj.parent.type !== "Scene") {
        selectedObj = selectedObj.parent
      }

      const domainId = selectedObj.userData.domainId
      if (domainId) {
        this.selectionStore.select(domainId)
        this.updateTransformControls()
      }
    } else {
      this.selectionStore.clearSelection()
      if (this.transformControls) {
        this.transformControls.detach()
      }
    }
  }

  private handleMouseMove = (event: MouseEvent) => {
    const canvas = this.renderer.domElement
    const rect = canvas.getBoundingClientRect()

    this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1
    this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1
  }

  private handleResize = () => {
    const canvas = this.renderer.domElement
    const width = canvas.clientWidth
    const height = canvas.clientHeight

    this.camera.aspect = width / height
    this.camera.updateProjectionMatrix()
    this.renderer.setSize(width, height)
  }

  private observeViewportStore() {
    // React to transform mode changes
    const updateMode = () => {
      if (this.transformControls) {
        this.transformControls.setMode(this.viewportStore.transformMode)
      }
    }

    // React to transform space changes
    const updateSpace = () => {
      if (this.transformControls) {
        this.transformControls.setSpace(this.viewportStore.transformSpace === "global" ? "world" : "local")
      }
    }

    // Set initial values
    updateMode()
    updateSpace()

    // Note: In a real implementation, we'd use MobX reactions here
    // For now, we'll just check on each frame
  }

  private updateTransformControls() {
    const selectedIds = this.selectionStore.selectedObjects
    if (selectedIds.length === 0) {
      if (this.transformControls) {
        this.transformControls.detach()
      }
      return
    }

    const selectedId = selectedIds[0]
    const threeObj = this.sceneAdapter.getThreeObject(selectedId)

    if (threeObj && this.transformControls) {
      this.transformControls.attach(threeObj)
      this.transformControls.setMode(this.viewportStore.transformMode)
      this.transformControls.setSpace(this.viewportStore.transformSpace === "global" ? "world" : "local")
    }
  }

  start() {
    this.animate()
  }

  private animate = () => {
    this.animationId = requestAnimationFrame(this.animate)

    // Update controls
    this.orbitControls.update()

    // Update transform controls mode/space if changed
    if (this.transformControls) {
      this.transformControls.setMode(this.viewportStore.transformMode)
      this.transformControls.setSpace(this.viewportStore.transformSpace === "global" ? "world" : "local")
    }

    // Update transform controls attachment if selection changed
    const selectedIds = this.selectionStore.selectedObjects
    if (selectedIds.length > 0) {
      if (this.transformControls) {
        const currentAttached = this.transformControls.object
        const shouldBeAttached = this.sceneAdapter.getThreeObject(selectedIds[0])

        if (currentAttached !== shouldBeAttached) {
          this.updateTransformControls()
        }
      }
    } else if (this.transformControls && this.transformControls.object) {
      this.transformControls.detach()
    }

    // Add scene adapter objects to scene if not already added
    const adapterScene = this.sceneAdapter.getThreeScene()
    if (adapterScene.parent !== this.scene) {
      this.scene.add(adapterScene)
    }

    // Render
    this.renderer.render(this.scene, this.camera)
  }

  dispose() {
    if (this.animationId !== null) {
      cancelAnimationFrame(this.animationId)
    }

    window.removeEventListener("resize", this.handleResize)
    this.renderer.domElement.removeEventListener("click", this.handleClick)
    this.renderer.domElement.removeEventListener("mousemove", this.handleMouseMove)

    this.orbitControls.dispose()
    if (this.transformControls) {
      this.transformControls.dispose()
    }
    this.renderer.dispose()
  }
}
