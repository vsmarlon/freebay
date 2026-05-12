import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private config: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.config.get('SMTP_HOST'),
      port: Number(this.config.get('SMTP_PORT', '587')),
      auth: {
        user: this.config.get('SMTP_USER'),
        pass: this.config.get('SMTP_PASS'),
      },
    });
  }

  async sendPasswordReset(to: string, token: string): Promise<void> {
    const appUrl = this.config.get('APP_URL', 'http://localhost:3333');
    const resetLink = `${appUrl}/reset-password?token=${token}`;

    const info = await this.transporter.sendMail({
      from: this.config.get('SMTP_FROM', '"Freebay" <no-reply@freebay.com>'),
      to,
      subject: 'Redefinição de senha — Freebay',
      text: `Clique no link para redefinir sua senha:\n\n${resetLink}\n\nO link expira em 15 minutos.\n\nSe você não solicitou isso, ignore este e-mail.`,
      html: `<p>Clique no link abaixo para redefinir sua senha:</p><p><a href="${resetLink}">${resetLink}</a></p><p>O link expira em <strong>15 minutos</strong>.</p><p>Se você não solicitou isso, ignore este e-mail.</p>`,
    });

    this.logger.log(`Password reset email sent to ${to} — messageId: ${info.messageId}`);
  }
}
