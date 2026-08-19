import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class ResendService {
  private readonly logger = new Logger(ResendService.name);

  constructor(private config: ConfigService) {}

  async sendRecoveryCode(email: string, code: string): Promise<string | null> {
    const apiKey = this.config.get<string>('RESEND_API_KEY');
    const fromEmail = this.config.get<string>('RESEND_FROM_EMAIL') || this.config.get<string>('EMAIL_FROM') || 'FreeBay <onboarding@resend.dev>';
    const appUrl = this.config.get<string>('APP_URL', 'http://localhost:3000');
    const deepLinkScheme = this.config.get<string>('DEEP_LINK_SCHEME', 'freebay');
    
    const webResetLink = `${appUrl}/reset-password?token=${code}&email=${encodeURIComponent(email)}`;
    const appDeepLink = `${deepLinkScheme}://reset-password?token=${code}&email=${encodeURIComponent(email)}`;

    if (!apiKey) {
      this.logger.warn('Recovery email not sent: RESEND_API_KEY is not configured');
      return null;
    }

    const htmlContent = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Redefinição de Senha — FreeBay</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0A0A0A; color: #FFFFFF; margin: 0; padding: 24px; }
          .container { max-width: 560px; margin: 0 auto; background-color: #121212; border: 2px solid #222222; padding: 32px; box-sizing: border-box; }
          .logo { font-size: 24px; font-weight: 900; letter-spacing: 3px; color: #8A1083; text-transform: uppercase; margin-bottom: 24px; border-bottom: 2px solid #1F1F1F; padding-bottom: 12px; }
          .title { font-size: 18px; font-weight: 800; color: #FFFFFF; margin-bottom: 16px; letter-spacing: 0.5px; text-transform: uppercase; }
          .text { font-size: 14px; line-height: 1.6; color: #BBBBBB; margin-bottom: 20px; }
          .code-container { background-color: #161616; border: 2px solid #8A1083; padding: 18px; text-align: center; margin: 24px 0; }
          .code-label { font-size: 11px; font-weight: 800; color: #8A1083; letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 8px; }
          .code-value { font-family: 'Space Mono', monospace, Courier; font-size: 26px; font-weight: 900; letter-spacing: 4px; color: #00FF66; word-break: break-all; }
          .button-container { margin: 28px 0; text-align: center; }
          .button { background-color: #8A1083; color: #FFFFFF !important; padding: 14px 32px; text-decoration: none; font-weight: 800; font-size: 13px; letter-spacing: 1.5px; display: inline-block; border: 2px solid #8A1083; text-transform: uppercase; }
          .direct-link { font-size: 12px; color: #777777; margin-top: 20px; line-height: 1.6; word-break: break-all; }
          .footer { font-size: 11px; color: #555555; margin-top: 32px; border-top: 1px solid #222222; padding-top: 16px; line-height: 1.5; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="logo">FREEBAY</div>
          <div class="title">RECUPERAÇÃO DE SENHA</div>
          <div class="text">
            Recebemos uma solicitação para redefinir a senha da sua conta no FreeBay. Utilize o código de verificação abaixo no aplicativo:
          </div>
          <div class="code-container">
            <div class="code-label">CÓDIGO DE VERIFICAÇÃO</div>
            <div class="code-value">${code}</div>
          </div>
          <div class="button-container">
            <a href="${appDeepLink}" class="button">ABRIR NO APP FREEBAY</a>
          </div>
          <div class="direct-link">
            Caso o aplicativo não abra automaticamente, utilize o link de navegação:
            <br>
            <a href="${webResetLink}" style="color: #8A1083; text-decoration: underline;">${webResetLink}</a>
          </div>
          <div class="footer">
            Este código é válido por <strong>10 minutos</strong>.<br>
            Se você não solicitou este código, ignore esta mensagem. Sua conta permanece segura.
          </div>
        </div>
      </body>
      </html>
    `;

    const textContent = `FREEBAY - RECUPERAÇÃO DE SENHA\n\n` +
      `Seu código de recuperação é: ${code}\n\n` +
      `Link para abrir no App: ${appDeepLink}\n` +
      `Link direto web: ${webResetLink}\n\n` +
      `Este código expira em 10 minutos.\n` +
      `Se você não solicitou este código, ignore esta mensagem.`;

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromEmail,
        to: email,
        subject: 'Código de Recuperação de Senha — FreeBay',
        text: textContent,
        html: htmlContent,
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`Recovery email failed: Resend API responded ${response.status} - ${body}`);
      return null;
    }

    const payload = await response.json() as { id?: string };
    this.logger.log(`[ResendService] Recovery email dispatched to ${email} (ID: ${payload.id})`);
    return payload.id ?? null;
  }
}
