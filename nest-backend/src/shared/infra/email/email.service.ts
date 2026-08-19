import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private resend: Resend | null = null;
  private transporter: nodemailer.Transporter | null = null;
  private readonly fromEmail: string;

  constructor(private config: ConfigService) {
    const resendApiKey = this.config.get<string>('RESEND_API_KEY');
    this.fromEmail = this.config.get<string>('EMAIL_FROM') || this.config.get<string>('SMTP_FROM') || 'FreeBay <onboarding@resend.dev>';

    if (resendApiKey) {
      this.resend = new Resend(resendApiKey);
      this.logger.log('📧 Resend email provider initialized');
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
      this.logger.log(`📧 SMTP email provider initialized (${smtpHost})`);
    }

    if (!this.resend && !this.transporter) {
      this.logger.warn('⚠️ No email provider configured (RESEND_API_KEY or SMTP_HOST missing). Emails will be logged to console in dev mode.');
    }
  }

  async sendPasswordReset(to: string, token: string): Promise<void> {
    const appUrl = this.config.get('APP_URL', 'http://localhost:3000');
    const resetLink = `${appUrl}/reset-password?token=${token}`;
    const subject = 'Redefinição de Senha — FreeBay';

    const textContent = `Redefinição de Senha — FreeBay\n\n` +
      `Recebemos uma solicitação para redefinir a senha da sua conta no FreeBay.\n\n` +
      `Clique no link abaixo para criar uma nova senha:\n${resetLink}\n\n` +
      `Código do Token: ${token}\n\n` +
      `Este link expira em 15 minutos.\n` +
      `Se você não solicitou esta alteração, ignore este e-mail.`;

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
            Recebemos uma solicitação para redefinir a senha da sua conta FreeBay. Clique no botão abaixo para prosseguir:
          </div>
          <div class="button-container">
            <a href="${resetLink}" class="button" target="_blank">REDEFINIR SENHA</a>
          </div>
          <div class="text" style="font-size: 12px;">
            Ou cole o link direto no seu navegador:
            <br>
            <span style="color: #8A1083; word-break: break-all;">${resetLink}</span>
          </div>
          <div class="token-box">
            Token: ${token}
          </div>
          <div class="footer">
            Este link é válido por <strong>15 minutos</strong>.<br>
            Se você não solicitou esta redefinição, nenhuma ação é necessária e sua senha permanece segura.
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
          this.logger.error(`❌ Resend email failed to ${to}: ${error.message}`);
        } else {
          this.logger.log(`✅ Password reset email sent via Resend to ${to} (ID: ${data?.id})`);
          return;
        }
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Unknown Resend error';
        this.logger.error(`❌ Resend exception: ${msg}`);
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
        this.logger.log(`✅ Password reset email sent via SMTP to ${to} (MessageId: ${info.messageId})`);
        return;
      } catch (err) {
        const msg = err instanceof Error ? err.message : 'Unknown SMTP error';
        this.logger.error(`❌ SMTP exception: ${msg}`);
      }
    }

    // 3. Dev / local fallback
    this.logger.log(`\n================== 📧 DEV EMAIL PREVIEW ==================`);
    this.logger.log(`To: ${to}`);
    this.logger.log(`Subject: ${subject}`);
    this.logger.log(`Reset Link: ${resetLink}`);
    this.logger.log(`Token: ${token}`);
    this.logger.log(`==========================================================\n`);
  }
}
