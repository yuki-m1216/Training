import { Module, OnModuleInit } from '@nestjs/common';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from './entities/user.entity';
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule implements OnModuleInit {
  constructor(private readonly usersService: UsersService) {}

  async onModuleInit() {
    // テスト環境以外で初期データを投入（開発用）
    if (process.env.NODE_ENV !== 'test') {
      const users = await this.usersService.findAll();
      if (users.length === 0) {
        await this.usersService.create({
          name: 'John Doe',
          email: 'john@example.com',
        });

        await this.usersService.create({
          name: 'Jane Smith',
          email: 'jane@example.com',
        });
      }
    }
  }
}
