import * as THREE from "three"
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js"
import { TransformControls } from "three/examples/jsm/controls/TransformControls.js"
import { ThreeSceneAdapter } from "@/lib/infrastructure/adapters/three-scene-adapter"
import type { ViewportStore } from "@/lib/stores/viewport-store"
import type { SelectionStore } from "@/lib/stores/selection-store"

export class ViewportRenderer {
  private renderer: THREE.WebGLRenderer
  private scene: THREE.Scene
  private camera: THREE.PerspectiveCamera
  private orbitControls: OrbitControls
  private transformControls: TransformControls
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

    // Setup transform controls
    this.transformControls = new TransformControls(this.camera, this.renderer.domElement)
    this.transformControls.addEventListener("dragging-changed", (event) => {
      this.orbitControls.enabled = !event.value
    })
    this.scene.add(this.transformControls)

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
      this.transformControls.detach()
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
      this.transformControls.setMode(this.viewportStore.transformMode)
    }

    // React to transform space changes
    const updateSpace = () => {
      this.transformControls.setSpace(this.viewportStore.transformSpace === "global" ? "world" : "local")
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
      this.transformControls.detach()
      return
    }

    const selectedId = selectedIds[0]
    const threeObj = this.sceneAdapter.getThreeObject(selectedId)

    if (threeObj) {
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
    this.transformControls.setMode(this.viewportStore.transformMode)
    this.transformControls.setSpace(this.viewportStore.transformSpace === "global" ? "world" : "local")

    // Update transform controls attachment if selection changed
    const selectedIds = this.selectionStore.selectedObjects
    if (selectedIds.length > 0) {
      const currentAttached = this.transformControls.object
      const shouldBeAttached = this.sceneAdapter.getThreeObject(selectedIds[0])

      if (currentAttached !== shouldBeAttached) {
        this.updateTransformControls()
      }
    } else if (this.transformControls.object) {
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
    this.transformControls.dispose()
    this.renderer.dispose()
  }
}
