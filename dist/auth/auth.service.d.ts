import { LoginDto, LoginResponseDto } from './dto/login.dto';
export declare class AuthService {
    login({ identifier, password }: LoginDto): Promise<LoginResponseDto>;
}
