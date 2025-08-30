import { Module } from '@nestjs/common';
import { UsersModule } from './users/users.module';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './users/entities/user.entity';

@Module({
  imports: [
    UsersModule,
    TypeOrmModule.forRoot({
      type: 'postgres',
      // host: process.env.DB_HOST || 'localhost',
      url: process.env.DATABASE_URL, // Docker環境用にDATABASE_URLを使用
      // port: parseInt(process.env.DB_PORT) || 5432,
      // username: process.env.DB_USERNAME || 'nestjs_user',
      // password: process.env.DB_PASSWORD || 'nestjs_password',
      // database: process.env.DB_NAME || 'nestjs_app',
      entities: [User],
      synchronize: true,
      dropSchema: process.env.NODE_ENV === 'test', // テスト時にスキーマをクリア
      logging: process.env.NODE_ENV === 'development',
    }),
  ],
  controllers: [],
  providers: [],
})
export class AppModule {}

