import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { VerifyFirebaseTokenDto } from './dto/verify-firebase-token.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('firebase/verify')
  verify(@Body() dto: VerifyFirebaseTokenDto) {
    return this.auth.verifyFirebaseToken(dto.idToken);
  }

  @Post('demo')
  demo() {
    return this.auth.loginAsDemo();
  }

  @Get('demo-users')
  demoUsers() {
    return this.auth.listDemoUsers();
  }

  @Post('demo-login/:userId')
  demoLogin(@Param('userId') userId: string) {
    return this.auth.demoLoginAs(userId);
  }
}
