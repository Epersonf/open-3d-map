import { Scene } from "./scene"
import { nanoid } from "nanoid"

export interface ProjectData {
  id?: string
  name: string
  version: string
  scenes: Scene[]
  activeSceneId?: string
  tags?: string[]
}

export class Project {
  id: string
  name: string
  version: string
  scenes: Scene[]
  activeSceneId: string | null
  tags: string[]

  constructor(data: ProjectData) {
    this.id = data.id || nanoid()
    this.name = data.name
    this.version = data.version || "1.0.0"
    this.scenes = data.scenes || []
    this.activeSceneId = data.activeSceneId || (this.scenes.length > 0 ? this.scenes[0].id : null)
    this.tags = data.tags || []
  }

  getActiveScene(): Scene | null {
    if (!this.activeSceneId) return null
    return this.scenes.find((scene) => scene.id === this.activeSceneId) || null
  }

  setActiveScene(sceneId: string) {
    const scene = this.scenes.find((s) => s.id === sceneId)
    if (scene) {
      this.activeSceneId = sceneId
    }
  }

  addScene(scene: Scene) {
    this.scenes.push(scene)
    if (!this.activeSceneId) {
      this.activeSceneId = scene.id
    }
  }

  removeScene(sceneId: string) {
    const index = this.scenes.findIndex((s) => s.id === sceneId)
    if (index > -1) {
      this.scenes.splice(index, 1)
      if (this.activeSceneId === sceneId) {
        this.activeSceneId = this.scenes.length > 0 ? this.scenes[0].id : null
      }
    }
  }

  getAllTags(): string[] {
    return [...this.tags]
  }

  toJSON(): any {
    return {
      id: this.id,
      name: this.name,
      version: this.version,
      scenes: this.scenes.map((scene) => scene.toJSON()),
      activeSceneId: this.activeSceneId,
      tags: [...this.tags],
    }
  }

  static fromJSON(data: any): Project {
    return new Project({
      id: data.id,
      name: data.name,
      version: data.version,
      scenes: data.scenes?.map((scene: any) => Scene.fromJSON(scene)) || [],
      activeSceneId: data.activeSceneId,
      tags: data.tags || [],
    })
  }
}
