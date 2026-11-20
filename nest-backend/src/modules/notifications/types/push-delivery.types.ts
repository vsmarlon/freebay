/**
 * Delivery outcome of a push attempt, as reported by Firebase.
 * `submitted` means Firebase accepted the message — never that a device displayed it.
 */
export enum PushDeliveryStatus {
  FcmDisabled = 'fcm_disabled',
  NoTokens = 'no_tokens',
  OptedOut = 'opted_out',
  Submitted = 'submitted',
  Failed = 'failed',
}

export interface PushDeliveryResult {
  status: PushDeliveryStatus;
  deviceCount: number;
  acceptedCount: number;
  rejectedCount: number;
  /** Firebase error codes only; registration tokens never leave the server. */
  errors: string[];
}

/** Request shape for the dev-only push test. */
export interface PushTestInput {
  title?: string;
  body?: string;
  type?: PushTestType;
}

/** Notification types whose push preference a diagnostic test can exercise. */
export enum PushTestType {
  Message = 'MESSAGE',
  Follow = 'FOLLOW',
  Order = 'ORDER',
  Payment = 'PAYMENT',
  Dispute = 'DISPUTE',
}
