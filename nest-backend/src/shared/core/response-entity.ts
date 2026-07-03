export class ResponseEntity<T = unknown> {
  private readonly _ok: boolean;
  private readonly _data?: T;
  private readonly _message?: string;
  private readonly _error?: string;

  private constructor(ok: boolean, data?: T, message?: string, error?: string) {
    this._ok = ok;
    this._data = data;
    this._message = message;
    this._error = error;
  }

  isOk(): boolean {
    return this._ok;
  }

  isError(): boolean {
    return !this._ok;
  }

  getData(): T | undefined {
    return this._data;
  }

  getError(): string | undefined {
    return this._error || this._message;
  }

  static success<T>(data?: T): ResponseEntity<T> {
    return new ResponseEntity<T>(true, data);
  }

  static error(message: string, error?: string): ResponseEntity<never> {
    return new ResponseEntity<never>(false, undefined, message, error);
  }
}
