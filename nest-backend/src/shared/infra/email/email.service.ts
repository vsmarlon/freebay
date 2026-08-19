import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';
import * as nodemailer from 'nodemailer';
import { Either, left, right } from '@/shared/core/either';
import { AppError } from '@/shared/core/errors';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private resend: Resend | null = null;
  private transporter: nodemailer.Transporter | null = null;
  private readonly fromEmail: string;
  private readonly isProduction: boolean;

  constructor(private config: ConfigService) {
    const resendApiKey = this.config.get<string>('RESEND_API_KEY');
    this.fromEmail = this.config.get<string>('EMAIL_FROM') || this.config.get<string>('SMTP_FROM') || 'FreeBay <onboarding@resend.dev>';
    this.isProduction = this.config.get<string>('NODE_ENV') === 'production';

    if (resendApiKey) {
      this.resend = new Resend(resendApiKey);
      this.logger.log('Resend email provider initialized');
    }

    const smtpHost = this.config.get<string>('SMTP_HOST');
    if (smtpHost) {
      this.transporter = nodemailer.createTransport({
        host: smtpHost,
        port: Number(this.config.get('SMTP_PORT', '587')),
        secure: Number(this.config.get('SMTP_PORT', '587')) === 465,
        auth: {
          user: this.config.get('SMTP_USER'),
          pass: this.config.get('SMTP_PASS'),
        },
      });
      this.logger.log(`SMTP email provider initialized (${smtpHost})`);
    }

    if (!this.resend && !this.transporter && !this.isProduction) {
      this.logger.warn('No email provider configured (RESEND_API_KEY or SMTP_HOST missing).');
    }
  }

  async sendPasswordReset(to: string, token: string): Promise<Either<AppError, void>> {
    const appUrl = this.config.get('APP_URL', 'http://localhost:3000');
    const resetLink = `${appUrl}/reset-password?token=${token}`;
    const subject = 'Redefinicao de Senha — FreeBay';

    const textContent = `Redefinicao de Senha — FreeBay\n\n` +
      `Recebemos uma solicitacao para redefinir a senha da sua conta no FreeBay.\n\n` +
      `Link para criar uma nova senha: ${resetLink}\n\n` +
      `Codigo do Token: ${token}\n\n` +
      `Este link expira em 15 minutos.\n` +
      `Se voce nao solicitou esta alteracao, ignore este e-mail.`;

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0A0A0A; color: #FFFFFF; margin: 0; padding: 24px; }
          .container { max-width: 560px; margin: 0 auto; background-color: #121212; border: 2px solid #222222; padding: 32px; }
          .logo { font-size: 24px; font-weight: 900; letter-spacing: 2px; color: #8A1083; text-transform: uppercase; margin-bottom: 24px; }
          .title { font-size: 20px; font-weight: 800; color: #FFFFFF; margin-bottom: 16px; }
          .text { font-size: 14px; line-height: 1.6; color: #AAAAAA; margin-bottom: 24px; }
          .button-container { margin: 32px 0; }
          .button { background-color: #8A1083; color: #FFFFFF !important; padding: 14px 28px; text-decoration: none; font-weight: 800; font-size: 14px; letter-spacing: 1px; display: inline-block; border: 2px solid #8A1083; text-transform: uppercase; }
          .token-box { background-color: #1A1A1A; border: 1px solid #333333; padding: 12px 16px; font-family: monospace; font-size: 13px; color: #00FF66; word-break: break-all; margin: 16px 0; }
          .footer { font-size: 12px; color: #666666; margin-top: 32px; border-top: 1px solid #222222; padding-top: 16px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="logo">FREEBAY</div>
          <div class="title">REDEFINIR SUA SENHA</div>
          <div class="text">
            Recebemos uma solicitacao para redefinir a senha da sua conta FreeBay. Clique no botao abaixo para prosseguir:
          </div>
          <div class="button-container">
            <a href="${resetLink}" class="button" target="_blank">REDEFINIR SENHA</a>
          </div>
          <div class="token-box">
            Token: ${token}
          </div>
          <div class="footer">
            Este link e valido por <strong>15 minutos</strong>.<br>
            Se voce nao solicitou esta redefinicao, nenhuma acao e necessaria.
          </div>
        </div>
      </body>
      </html>
    `;

    // 1. Try Resend API SDK first
    if (this.resend) {
      try {
        const { data, error } = await this.resend.emails.send({
          from: this.fromEmail,
          to: [to],
          subject,
          text: textContent,
          html: htmlContent,
        });

        if (error) {
          this.logger.error(`Resend email delivery failed to ${to}: ${error.message}`);
        } else {
          this.logger.log(`Password reset email sent via Resend to ${to} (ID: ${data?.id})`);
          return right(undefined);
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Unknown Resend error';
        this.logger.error(`Resend exception: ${msg}`);
      }
    }

    // 2. Try SMTP fallback
    if (this.transporter) {
      try {
        const info = await this.transporter.sendMail({
          from: this.fromEmail,
          to,
          subject,
          text: textContent,
          html: htmlContent,
        });
        this.logger.log(`Password reset email sent via SMTP to ${to} (MessageId: ${info.messageId})`);
        return right(undefined);
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Unknown SMTP error';
        this.logger.error(`SMTP exception: ${msg}`);
      }
    }

    if (this.isProduction) {
      return left(new AppError('EMAIL_DELIVERY_FAILED', 'Falha ao enviar e-mail de recuperação'));
    }

    this.logger.warn(`Email provider not available in dev. Password recovery email to ${to} was not dispatched.`);
    return right(undefined);
  }
}
