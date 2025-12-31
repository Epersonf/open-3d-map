import { Vector3 } from "./vector3"

export class Transform {
  position: Vector3
  rotation: Vector3
  scale: Vector3

  constructor(
    position: Vector3 = new Vector3(),
    rotation: Vector3 = new Vector3(),
    scale: Vector3 = new Vector3(1, 1, 1),
  ) {
    this.position = position
    this.rotation = rotation
    this.scale = scale
  }

  clone(): Transform {
    return new Transform(this.position.clone(), this.rotation.clone(), this.scale.clone())
  }

  toJSON() {
    return {
      position: this.position.toJSON(),
      rotation: this.rotation.toJSON(),
      scale: this.scale.toJSON(),
    }
  }

  static fromJSON(data: any): Transform {
    return new Transform(Vector3.fromJSON(data.position), Vector3.fromJSON(data.rotation), Vector3.fromJSON(data.scale))
  }
}
