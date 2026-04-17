export interface PixChargeRequest {
  correlationID: string;
  value: number;
  comment?: string;
  expiresIn?: number;
  customer: {
    name: string;
    taxID: string;
    email: string;
  };
}

export interface PixChargeResponse {
  id: string;
  status: 'PENDING' | 'COMPLETED' | 'EXPIRED' | 'FAILED';
  pix?: {
    key: string;
    image: string;
    qrCode: string;
  };
}
