import { Transform } from "./transform"
import { nanoid } from "nanoid"

export interface GameObjectData {
  id?: string
  name: string
  transform?: Transform
  tags?: string[]
  children?: GameObjectData[]
}

export class GameObject {
  id: string
  name: string
  transform: Transform
  tags: string[]
  children: GameObject[]
  parent: GameObject | null = null

  constructor(data: GameObjectData) {
    this.id = data.id || nanoid()
    this.name = data.name
    this.transform = data.transform || new Transform()
    this.tags = data.tags || []
    this.children = (data.children || []).map((child) => new GameObject(child))

    // Set parent references
    this.children.forEach((child) => {
      child.parent = this
    })
  }

  addChild(child: GameObject) {
    this.children.push(child)
    child.parent = this
  }

  removeChild(child: GameObject) {
    const index = this.children.indexOf(child)
    if (index > -1) {
      this.children.splice(index, 1)
      child.parent = null
    }
  }

  findById(id: string): GameObject | null {
    if (this.id === id) return this

    for (const child of this.children) {
      const found = child.findById(id)
      if (found) return found
    }

    return null
  }

  hasTag(tag: string): boolean {
    return this.tags.includes(tag)
  }

  addTag(tag: string) {
    if (!this.tags.includes(tag)) {
      this.tags.push(tag)
    }
  }

  removeTag(tag: string) {
    const index = this.tags.indexOf(tag)
    if (index > -1) {
      this.tags.splice(index, 1)
    }
  }

  toJSON(): GameObjectData {
    return {
      id: this.id,
      name: this.name,
      transform: this.transform.toJSON(),
      tags: [...this.tags],
      children: this.children.map((child) => child.toJSON()),
    }
  }

  static fromJSON(data: GameObjectData): GameObject {
    return new GameObject({
      ...data,
      transform: data.transform ? Transform.fromJSON(data.transform) : new Transform(),
      children: data.children?.map((child) => GameObject.fromJSON(child)),
    })
  }
}
