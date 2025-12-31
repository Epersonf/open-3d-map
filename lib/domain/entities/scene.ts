import { GameObject } from "./game-object"
import { nanoid } from "nanoid"

export interface SceneData {
  id?: string
  name: string
  rootObjects: GameObject[]
}

export class Scene {
  id: string
  name: string
  rootObjects: GameObject[]

  constructor(data: SceneData) {
    this.id = data.id || nanoid()
    this.name = data.name
    this.rootObjects = data.rootObjects || []
  }

  addObject(object: GameObject) {
    this.rootObjects.push(object)
  }

  removeObject(object: GameObject) {
    const index = this.rootObjects.indexOf(object)
    if (index > -1) {
      this.rootObjects.splice(index, 1)
    }
  }

  findObjectById(id: string): GameObject | null {
    for (const obj of this.rootObjects) {
      const found = obj.findById(id)
      if (found) return found
    }
    return null
  }

  getAllObjects(): GameObject[] {
    const result: GameObject[] = []

    const traverse = (obj: GameObject) => {
      result.push(obj)
      obj.children.forEach(traverse)
    }

    this.rootObjects.forEach(traverse)
    return result
  }

  toJSON(): any {
    return {
      id: this.id,
      name: this.name,
      rootObjects: this.rootObjects.map((obj) => obj.toJSON()),
    }
  }

  static fromJSON(data: any): Scene {
    return new Scene({
      id: data.id,
      name: data.name,
      rootObjects: data.rootObjects?.map((obj: any) => GameObject.fromJSON(obj)) || [],
    })
  }
}
