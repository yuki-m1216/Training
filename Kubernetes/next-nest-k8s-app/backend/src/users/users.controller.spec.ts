import { Test, TestingModule } from '@nestjs/testing';
import { HttpException } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { User } from './entities/user.entity';

describe('UsersController', () => {
  let controller: UsersController;
  let service: UsersService;

  const mockUsersService = {
    findAll: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    remove: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
    service = module.get<UsersService>(UsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('findAll', () => {
    it('should return an array of users', () => {
      const result: User[] = [
        { id: 1, name: 'John Doe', email: 'john@example.com', createdAt: new Date() },
      ];
      mockUsersService.findAll.mockReturnValue(result);

      expect(controller.findAll()).toBe(result);
      expect(service.findAll).toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('should return a user by id', () => {
      const user: User = {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: new Date(),
      };
      mockUsersService.findOne.mockReturnValue(user);

      expect(controller.findOne(1)).toBe(user);
      expect(service.findOne).toHaveBeenCalledWith(1);
    });

    it('should throw HttpException when user not found', () => {
      mockUsersService.findOne.mockReturnValue(undefined);

      expect(() => controller.findOne(999)).toThrow(HttpException);
      expect(() => controller.findOne(999)).toThrow('User not found');
    });
  });

  describe('create', () => {
    it('should create a new user', () => {
      const createUserDto: CreateUserDto = {
        name: 'Test User',
        email: 'test@example.com',
      };
      const user: User = { id: 1, ...createUserDto, createdAt: new Date() };

      mockUsersService.create.mockReturnValue(user);

      expect(controller.create(createUserDto)).toBe(user);
      expect(service.create).toHaveBeenCalledWith(createUserDto);
    });
  });

  describe('remove', () => {
    it('should remove a user by id', () => {
      const user: User = {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: new Date(),
      };
      mockUsersService.remove.mockReturnValue(user);

      expect(controller.remove(1)).toBe(user);
      expect(service.remove).toHaveBeenCalledWith(1);
    });

    it('should throw HttpException when user not found', () => {
      mockUsersService.remove.mockReturnValue(undefined);

      expect(() => controller.remove(999)).toThrow(HttpException);
      expect(() => controller.remove(999)).toThrow('User not found');
    });
  });
});
