export class User {
  id: number;
  name: string;
  email: string;
  avatar?: string;
  createdAt: Date;

  constructor(partial: Partial<User>) {
    Object.assign(this, partial);
  }
}
