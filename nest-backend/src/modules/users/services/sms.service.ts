export abstract class SmsService {
  abstract sendVerificationCode(phone: string, code: string): Promise<string | null>;
}
