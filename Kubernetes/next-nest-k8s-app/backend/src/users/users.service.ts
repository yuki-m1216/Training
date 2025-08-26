import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { User } from './entities/user.entity';

@Injectable()
export class UsersService {
  private users: User[] = [
    { id: 1, name: 'John Doe', email: 'john@example.com', createdAt: new Date() },
    { id: 2, name: 'Jane Doe', email: 'jane@example.com', createdAt: new Date() },
  ];

  findAll(): User[] {
    return this.users;
  }

  findOne(id: number): User | undefined {
    return this.users.find((user) => user.id === id);
  }

  create(createUserDto: CreateUserDto): User {
    const newUser = new User({
      id: this.users.length + 1,
      ...createUserDto,
      createdAt: new Date(),
    });

    this.users.push(newUser);
    return newUser;
  }

  remove(id: number): User | undefined {
    const index = this.users.findIndex((user) => user.id === id);
    if (index === -1) return undefined;

    return this.users.splice(index, 1)[0];
  }
}
