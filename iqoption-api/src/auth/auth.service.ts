import { Injectable } from '@nestjs/common';
import IqOption, { type dataResponse } from '@mvh/iqoption';
import { LoginDto, LoginResponseDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  async login({ identifier, password }: LoginDto): Promise<LoginResponseDto> {
    const loginResponse: dataResponse<any> = await IqOption.http.auth.login({
      identifier,
      password,
    });

    // If login succeeded and returned an ssid, fetch session to get expiration and set cookie for subsequent HTTP calls
    if (loginResponse?.success && loginResponse?.data?.ssid) {
      const sessionResponse: dataResponse<any> = await IqOption.http.auth.session().catch(() => ({ success: false } as dataResponse));
      if (sessionResponse?.success && sessionResponse?.data?.expires_at) {
        try {
          IqOption.http.setCookie(loginResponse.data.ssid as string, Number(sessionResponse.data.expires_at));
        } catch {
          // ignore setCookie errors
        }
      }
    }

    return {
      success: Boolean(loginResponse?.success),
      token: null,
      raw: loginResponse ?? null,
    };
  }
}


