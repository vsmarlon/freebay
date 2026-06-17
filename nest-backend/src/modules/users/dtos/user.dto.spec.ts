import { validate } from 'class-validator';
import { plainToClass } from 'class-transformer';
import { UpdateProfileDTO } from './user.dto';

describe('UpdateProfileDTO', () => {
  it('accepts valid CPF', async () => {
    const dto = plainToClass(UpdateProfileDTO, { cpf: '529.982.247-25' });
    const errors = await validate(dto);
    const cpfError = errors.find((e) => e.property === 'cpf');
    expect(cpfError).toBeUndefined();
  });

  it('accepts valid CNPJ', async () => {
    const dto = plainToClass(UpdateProfileDTO, { cpf: '04.252.011/0001-10' });
    const errors = await validate(dto);
    const cpfError = errors.find((e) => e.property === 'cpf');
    expect(cpfError).toBeUndefined();
  });

  it('rejects invalid CPF or CNPJ', async () => {
    const dto = plainToClass(UpdateProfileDTO, { cpf: '123.456.789-00' });
    const errors = await validate(dto);
    const cpfError = errors.find((e) => e.property === 'cpf');
    expect(cpfError).toBeDefined();
  });

  it('keeps CPF optional', async () => {
    const dto = plainToClass(UpdateProfileDTO, { displayName: 'John Doe' });
    const errors = await validate(dto);
    expect(errors.length).toBe(0);
  });

  it('rejects invalid avatar URL', async () => {
    const dto = plainToClass(UpdateProfileDTO, { avatarUrl: 'not-a-url' });
    const errors = await validate(dto);
    const urlError = errors.find((e) => e.property === 'avatarUrl');
    expect(urlError).toBeDefined();
  });
});
