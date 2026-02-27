// TODO: Implement ProcessPaymentUseCase — integrates with xx
export class ProcessPaymentUseCase {
  async execute(): Promise<{ transactionId: string; pixQrCode?: string }> {
    throw new Error('Not implemented — requires payment provider integration');
  }
}

// TODO: Implement ReleaseEscrowUseCase — triggered after delivery confirmation
export class ReleaseEscrowUseCase {
  async execute(): Promise<void> {
    throw new Error('Not implemented — requires payment provider integration');
  }
}
