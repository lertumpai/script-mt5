export declare class LoginDto {
    identifier: string;
    password: string;
    twoFactorCode?: string;
}
export declare class LoginResponseDto {
    success: boolean;
    token: string | null;
    raw: unknown;
}
