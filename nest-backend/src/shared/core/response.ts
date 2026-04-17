export interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
  };
}

export interface SuccessResponse<T> {
  success: true;
  data: T;
}

export type ApiResponse<T> = SuccessResponse<T> | ErrorResponse;

export function getFailure(code: string, message: string): ErrorResponse {
  return { success: false, error: { code, message } };
}

export function getResponse<T>(data: T): SuccessResponse<T> {
  return { success: true, data };
}
