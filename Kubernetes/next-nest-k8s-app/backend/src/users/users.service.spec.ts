import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';

describe('UsersService', () => {
  let service: UsersService;

  const mockRepository = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('should return an array of users', async () => {
      const users = [
        {id: 1, name: 'John Doe', email: 'john@example.com', createdAt: new Date()},
      ];
      mockRepository.find.mockResolvedValue(users);

      const result = await service.findAll();
      expect(result).toEqual(users);
      expect(mockRepository.find).toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('should return a user by id', async () => {
      const user = {id: 1, name: 'John Doe', email: 'john@example.com', createdAt: new Date()};
      mockRepository.findOne.mockResolvedValue(user);

      const result = await service.findOne(1);
      expect(result).toEqual(user);
      expect(mockRepository.findOne).toHaveBeenCalledWith({ where: { id: 1 } });
    });

    it('should return undefined for non-existing user', async () => {
      mockRepository.findOne.mockResolvedValue(null);

      const result = await service.findOne(999);
      expect(result).toBeNull();
    });
  });

  describe('create', () => {
    it('should create a new user', async() => {
      const createUserDto: CreateUserDto = {
        name: 'Test User',
        email: 'test@example.com',
      };
      const user = {id: 1, ...createUserDto, createdAt: new Date()};
      mockRepository.create.mockReturnValue(user);
      mockRepository.save.mockResolvedValue(user);

      const result = await service.create(createUserDto);
      expect(result).toEqual(user);
      expect(mockRepository.create).toHaveBeenCalledWith(createUserDto);
      expect(mockRepository.save).toHaveBeenCalledWith(user);
    });

    it('should create a user with avatar', async() => {
      const createUserDto: CreateUserDto = {
        name: 'Avatar User',
        email: 'avatar@example.com',
        avatar: 'http://example.com/avatar.jpg',
      };
      const user = {id: 2, ...createUserDto, createdAt: new Date()};
      mockRepository.create.mockReturnValue(user);
      mockRepository.save.mockResolvedValue(user);

      const result = await service.create(createUserDto);
      expect(result.avatar).toBe(createUserDto.avatar);
    });
  });

  describe('remove', () => {
    it('should remove a user by id', async () => {
      const user = {id: 1, name: 'John Doe', email: 'john@example.com', createdAt: new Date()};
      mockRepository.findOne.mockResolvedValue(user);
      mockRepository.delete.mockResolvedValue({ affected: 1 });

      const result = await service.remove(1);
      expect(result).toEqual(user);
      expect(mockRepository.findOne).toHaveBeenCalledWith({ where: { id: 1 } });
      expect(mockRepository.delete).toHaveBeenCalledWith(1);
    });

    it('should return undefined for non-existing user', async () => {
      mockRepository.findOne.mockResolvedValue(null);

      const result = await service.remove(999);
      expect(result).toBeNull();
    });
  });
});
