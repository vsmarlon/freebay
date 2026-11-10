export interface MediaRequest {
  headers?: {
    range?: string;
    'x-view-once-opening'?: string;
  };
}

export interface MediaResponse {
  setHeader?(name: string, value: string): void;
  status?(code: number): void;
}
