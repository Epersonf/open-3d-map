import * as THREE from 'three'

export class SimpleTransformControls {
  public isTransformControls = true
  public isObject3D = true
  public type = 'TransformControls'
  public uuid = THREE.MathUtils.generateUUID()
  public children: THREE.Object3D[] = []
  public parent: THREE.Object3D | null = null
  public object: THREE.Object3D | null = null
  private mode: 'translate' | 'rotate' | 'scale' = 'translate'
  private space: 'world' | 'local' = 'world'
  private gizmos: THREE.Object3D
  private raycaster = new THREE.Raycaster()
  private mouse = new THREE.Vector2()
  private selectedAxis: string | null = null
  private isDragging = false

  constructor(private camera: THREE.Camera, private domElement: HTMLElement) {
    this.gizmos = new THREE.Group()
    this.setupGizmos()
    this.setupEventListeners()
  }

  private setupGizmos() {
    const arrowGeometry = new THREE.CylinderGeometry(0, 0.1, 0.8, 8)
    const coneGeometry = new THREE.ConeGeometry(0.2, 0.5, 8)

    const xMaterial = new THREE.MeshBasicMaterial({ color: 0xff0000 })
    const xArrow = new THREE.Mesh(arrowGeometry, xMaterial)
    xArrow.rotation.z = -Math.PI / 2
    xArrow.position.x = 0.5
    xArrow.userData.axis = 'x'

    const xCone = new THREE.Mesh(coneGeometry, xMaterial)
    xCone.rotation.z = -Math.PI / 2
    xCone.position.x = 1
    xCone.userData.axis = 'x'

    const yMaterial = new THREE.MeshBasicMaterial({ color: 0x00ff00 })
    const yArrow = new THREE.Mesh(arrowGeometry, yMaterial)
    yArrow.position.y = 0.5
    yArrow.userData.axis = 'y'

    const yCone = new THREE.Mesh(coneGeometry, yMaterial)
    yCone.position.y = 1
    yCone.userData.axis = 'y'

    const zMaterial = new THREE.MeshBasicMaterial({ color: 0x0000ff })
    const zArrow = new THREE.Mesh(arrowGeometry, zMaterial)
    zArrow.rotation.x = Math.PI / 2
    zArrow.position.z = 0.5
    zArrow.userData.axis = 'z'

    const zCone = new THREE.Mesh(coneGeometry, zMaterial)
    zCone.rotation.x = Math.PI / 2
    zCone.position.z = 1
    zCone.userData.axis = 'z'

    this.gizmos.add(xArrow, xCone, yArrow, yCone, zArrow, zCone)
  }

  private setupEventListeners() {
    this.domElement.addEventListener('mousedown', this.onMouseDown.bind(this))
    this.domElement.addEventListener('mousemove', this.onMouseMove.bind(this))
    this.domElement.addEventListener('mouseup', this.onMouseUp.bind(this))
  }

  attach(object: THREE.Object3D) {
    this.object = object
    this.detach()
    if (object.parent) {
      object.parent.add(this.gizmos)
    }
    this.gizmos.position.copy(object.position)
    this.gizmos.rotation.copy(object.rotation)
    this.gizmos.scale.copy(object.scale)
  }

  detach() {
    if (this.gizmos.parent) {
      this.gizmos.parent.remove(this.gizmos)
    }
    this.object = null
  }

  setMode(mode: 'translate' | 'rotate' | 'scale') {
    this.mode = mode
    this.gizmos.children.forEach(child => {
      child.visible = mode === 'translate'
    })
  }

  setSpace(space: 'world' | 'local') {
    this.space = space
  }

  private onMouseDown(event: MouseEvent) {
    const rect = this.domElement.getBoundingClientRect()
    this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1
    this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1

    this.raycaster.setFromCamera(this.mouse, this.camera)
    const intersects = this.raycaster.intersectObjects((this.gizmos as any).children, true)

    if (intersects.length > 0 && this.object) {
      this.selectedAxis = (intersects[0].object as any).userData.axis
      this.isDragging = true
      this.domElement.style.cursor = 'grabbing'
    }
  }

  private onMouseMove(event: MouseEvent) {
    if (!this.isDragging || !this.object || !this.selectedAxis) return

    const rect = this.domElement.getBoundingClientRect()
    this.mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1
    this.mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1

    const movement = new THREE.Vector3()
    if (this.selectedAxis === 'x') movement.x = this.mouse.x * 0.1
    if (this.selectedAxis === 'y') movement.y = -this.mouse.y * 0.1
    if (this.selectedAxis === 'z') movement.z = this.mouse.y * 0.1

    this.object.position.add(movement)
    this.gizmos.position.copy(this.object.position)

    this.dispatchEvent({ type: 'dragging-changed', value: true })
  }

  private onMouseUp() {
    this.isDragging = false
    this.selectedAxis = null
    this.domElement.style.cursor = ''

    if (this.object) {
      this.dispatchEvent({ type: 'dragging-changed', value: false })
    }
  }

  addEventListener(type: string, listener: EventListener) {
    if (!(this as any)._listeners) (this as any)._listeners = {}
    if (!(this as any)._listeners[type]) (this as any)._listeners[type] = []
    ;(this as any)._listeners[type].push(listener)
  }

  removeEventListener(type: string, listener: EventListener) {
    if (!(this as any)._listeners || !(this as any)._listeners[type]) return
    const index = (this as any)._listeners[type].indexOf(listener)
    if (index > -1) (this as any)._listeners[type].splice(index, 1)
  }

  dispatchEvent(event: any) {
    if (!(this as any)._listeners || !(this as any)._listeners[event.type]) return
    ;(this as any)._listeners[event.type].forEach((listener: EventListener) => {
      listener.call(this, event)
    })
  }

  dispose() {
    this.domElement.removeEventListener('mousedown', this.onMouseDown.bind(this))
    this.domElement.removeEventListener('mousemove', this.onMouseMove.bind(this))
    this.domElement.removeEventListener('mouseup', this.onMouseUp.bind(this))
    ;(this.gizmos as any).clear && (this.gizmos as any).clear()
  }
}
