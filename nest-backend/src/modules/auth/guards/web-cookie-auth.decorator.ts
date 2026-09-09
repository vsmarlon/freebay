import { SetMetadata } from '@nestjs/common';

export const WEB_COOKIE_AUTH_KEY = 'webCookieAuth';
export const WebCookieAuth = () => SetMetadata(WEB_COOKIE_AUTH_KEY, true);
