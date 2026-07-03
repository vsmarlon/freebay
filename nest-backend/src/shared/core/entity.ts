export class Entity {
  constructor(props: Record<string, unknown>) {
    Object.assign(this as Record<string, unknown>, props);
  }

  toPlain(): Record<string, unknown> {
    const result: Record<string, unknown> = {};
    for (const key of Object.getOwnPropertyNames(this)) {
      const value = (this as Record<string, unknown>)[key];
      if (value !== undefined && typeof value !== 'function') {
        result[key] = value;
      }
    }
    return result;
  }
}
