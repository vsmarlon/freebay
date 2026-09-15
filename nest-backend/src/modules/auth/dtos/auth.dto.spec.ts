import { plainToClass } from 'class-transformer';
import { validate } from 'class-validator';
import { BiometricLoginDTO, RegisterDTO, CompleteProfileDTO } from './auth.dto';

describe('BiometricLoginDTO', () => {
  it('rejects oversized biometric tokens', async () => {
    const dto = plainToClass(BiometricLoginDTO, { biometricToken: 'a'.repeat(2049) });

    const errors = await validate(dto);

    expect(errors.find((error) => error.property === 'biometricToken')).toBeDefined();
  });
});

describe('RegisterDTO & CompleteProfileDTO validation', () => {
  const baseValid = {
    displayName: 'João da Silva',
    username: 'joao_silva',
    email: 'joao@example.com',
    password: 'password123',
  };

  it('accepts valid display names and usernames', async () => {
    const validNames = [
      'John Doe',
      'João da Silva',
      'Maria-Eduarda',
      "D'Angelo",
      'Dr. Smith',
      'Loja 10',
    ];

    for (const name of validNames) {
      const dto = plainToClass(RegisterDTO, { ...baseValid, displayName: name });
      const errors = await validate(dto);
      const nameError = errors.find((e) => e.property === 'displayName');
      expect(nameError).toBeUndefined();
    }
  });

  it('rejects hacky display names containing special characters (#$!%^@*()*#$,./\\, etc.)', async () => {
    const hackyNames = [
      '#$!%^@*()*#$,./\\',
      'John#Doe',
      'User$1',
      'Hey!There',
      '50%Off',
      'test^user',
      '@hacker',
      'user*name',
      '(admin)',
      'Tom, Jerry',
      'user/admin',
      'path\\to\\file',
      'Tom & Jerry',
      '<script>alert(1)</script>',
      'user_name_with_underscores',
    ];

    for (const name of hackyNames) {
      const dto = plainToClass(RegisterDTO, { ...baseValid, displayName: name });
      const errors = await validate(dto);
      const nameError = errors.find((e) => e.property === 'displayName');
      expect(nameError).toBeDefined();
    }
  });

  it('rejects display names that are too short, too long, or consecutive spaces', async () => {
    const invalidLengths = ['A', 'A'.repeat(51), 'John  Doe'];

    for (const name of invalidLengths) {
      const dto = plainToClass(RegisterDTO, { ...baseValid, displayName: name });
      const errors = await validate(dto);
      const nameError = errors.find((e) => e.property === 'displayName');
      expect(nameError).toBeDefined();
    }
  });

  it('transforms uppercase usernames to lowercase and accepts them', async () => {
    const dto = plainToClass(RegisterDTO, { ...baseValid, username: 'JohnDoe' });
    expect(dto.username).toBe('johndoe');
    const errors = await validate(dto);
    expect(errors.find((e) => e.property === 'username')).toBeUndefined();
  });

  it('rejects invalid usernames with special characters, unicode, spaces, or invalid length', async () => {
    const invalidUsernames = [
      'ab',
      'a'.repeat(21),
      'john doe',
      'user#name',
      'user$name',
      'user!name',
      'user%name',
      'user^name',
      'user@name',
      'user*name',
      'user(name)',
      'user,name',
      'user.name',
      'user/name',
      'user\\name',
      'user&name',
      'joão_silva',
      'usuário',
    ];

    for (const username of invalidUsernames) {
      const dto = plainToClass(RegisterDTO, { ...baseValid, username });
      const errors = await validate(dto);
      const usernameError = errors.find((e) => e.property === 'username');
      expect(usernameError).toBeDefined();
    }
  });

  it('enforces display name and username constraints on CompleteProfileDTO', async () => {
    const invalidDto = plainToClass(CompleteProfileDTO, {
      displayName: 'Hacker#123',
      username: 'Hacker#123',
    });

    const errors = await validate(invalidDto);
    expect(errors.find((e) => e.property === 'displayName')).toBeDefined();
    expect(errors.find((e) => e.property === 'username')).toBeDefined();

    const validDto = plainToClass(CompleteProfileDTO, {
      displayName: 'Carlos Eduardo',
      username: 'carlos_eduardo',
    });

    const validErrors = await validate(validDto);
    expect(validErrors.find((e) => e.property === 'displayName')).toBeUndefined();
    expect(validErrors.find((e) => e.property === 'username')).toBeUndefined();
  });
});
