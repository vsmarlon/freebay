// ─── API Response Types ─────────────────────────────────
// Standard response shape for all endpoints

export interface ApiResponseSuccess<T> {
  success: true;
  data: T;
}

export interface ApiResponseError {
  success: false;
  error: {
    code: string;
    message: string;
  };
}

export type ApiResponse<T> = ApiResponseSuccess<T> | ApiResponseError;

// ─── Factory Functions ──────────────────────────────────

export const apiSuccess = <T>(data: T): ApiResponseSuccess<T> => ({
  success: true,
  data,
});

export const apiError = (code: string, message: string): ApiResponseError => ({
  success: false,
  error: { code, message },
});
