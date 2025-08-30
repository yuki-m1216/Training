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
    it('should return an array of users', async () => {
      const result: User[] = [
        { id: 1, name: 'John Doe', email: 'john@example.com', createdAt: new Date() },
      ];
      mockUsersService.findAll.mockResolvedValue(result);

      expect(await controller.findAll()).toBe(result);
      expect(service.findAll).toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('should return a user by id', async () => {
      const user: User = {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: new Date(),
      };
      mockUsersService.findOne.mockResolvedValue(user);

      expect(await controller.findOne(1)).toBe(user);
      expect(service.findOne).toHaveBeenCalledWith(1);
    });

    it('should throw HttpException when user not found', async () => {
      mockUsersService.findOne.mockResolvedValue(undefined);

      await expect(controller.findOne(999)).rejects.toThrow(HttpException);
      await expect(controller.findOne(999)).rejects.toThrow('User not found');
    });
  });

  describe('create', () => {
    it('should create a new user', async () => {
      const createUserDto: CreateUserDto = {
        name: 'Test User',
        email: 'test@example.com',
      };
      const user: User = { id: 1, ...createUserDto, createdAt: new Date() };

      mockUsersService.create.mockResolvedValue(user);

      expect(await controller.create(createUserDto)).toBe(user);
      expect(service.create).toHaveBeenCalledWith(createUserDto);
    });
  });

  describe('remove', () => {
    it('should remove a user by id', async() => {
      const user: User = {
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: new Date(),
      };
      mockUsersService.remove.mockResolvedValue(user);

      expect(await controller.remove(1)).toBe(user);
      expect(service.remove).toHaveBeenCalledWith(1);
    });

    it('should throw HttpException when user not found', async () => {
      mockUsersService.remove.mockResolvedValue(undefined);

      await expect(controller.remove(999)).rejects.toThrow(HttpException);
      await expect(controller.remove(999)).rejects.toThrow('User not found');
    });
  });
});
