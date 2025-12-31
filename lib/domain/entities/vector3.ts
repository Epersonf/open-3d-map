export class Vector3 {
  constructor(
    public x = 0,
    public y = 0,
    public z = 0,
  ) {}

  clone(): Vector3 {
    return new Vector3(this.x, this.y, this.z)
  }

  toJSON() {
    return { x: this.x, y: this.y, z: this.z }
  }

  static fromJSON(data: any): Vector3 {
    return new Vector3(data.x, data.y, data.z)
  }
}
