import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';

describe('UsersService', () => {
  let service: UsersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UsersService],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('should return an array of users', () => {
      const result = service.findAll();
      expect(result).toBeInstanceOf(Array);
      expect(result.length).toBeGreaterThan(0);
      expect(result[0]).toHaveProperty('id');
      expect(result[0]).toHaveProperty('name');
      expect(result[0]).toHaveProperty('email');
    });
  });

  describe('findOne', () => {
    it('should return a user by id', () => {
      const result = service.findOne(1);
      expect(result).toBeDefined();
      expect(result?.id).toBe(1);
      expect(result?.name).toBe('John Doe');
    });

    it('should return undefined for non-existing user', () => {
      const result = service.findOne(999);
      expect(result).toBeUndefined();
    });
  });

  describe('create', () => {
    it('should create a new user', () => {
      const createUserDto: CreateUserDto = {
        name: 'Test User',
        email: 'test@example.com',
      };
      const result = service.create(createUserDto);

      expect(result).toBeDefined();
      expect(result?.id).toBeDefined();
      expect(result?.name).toBe(createUserDto.name);
      expect(result?.email).toBe(createUserDto.email);
      expect(result?.createdAt).toBeDefined();
    });

    it('should create a user with avatar', () => {
      const createUserDto: CreateUserDto = {
        name: 'Avatar User',
        email: 'avatar@example.com',
        avatar: 'http://example.com/avatar.jpg',
      };
      const result = service.create(createUserDto);
      expect(result.avatar).toBe(createUserDto.avatar);
    });
  });

  describe('remove', () => {
    it('should remove a user by id', () => {
      const initialCount = service.findAll().length;
      const result = service.remove(1);

      expect(result).toBeDefined();
      expect(result?.id).toBe(1);
      expect(service.findAll().length).toBe(initialCount - 1);
    });

    it('should return undefined for non-existing user', () => {
      const result = service.remove(999);
      expect(result).toBeUndefined();
    });
  });
});
