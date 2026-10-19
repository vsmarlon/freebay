import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { CancelOrderDTO } from './order.dto';

describe('CancelOrderDTO reason boundary', () => {
  const errorsFor = (reason: unknown) =>
    validateSync(plainToInstance(CancelOrderDTO, { reason }));

  it.each([null, undefined])('rejects missing/non-string reason %s', (reason) => {
    expect(errorsFor(reason).length).toBeGreaterThan(0);
  });

  it('strips C0/C1 controls while preserving ordinary accented Portuguese', () => {
    const dto = plainToInstance(CancelOrderDTO, { reason: 'Ação\u0000\u009f válida' });

    expect(dto.reason).toBe('Ação válida');
    expect(validateSync(dto)).toHaveLength(0);
  });

  it('rejects a reason that is blank after control stripping', () => {
    expect(errorsFor('\u0000\u009f  ').length).toBeGreaterThan(0);
  });

  it('accepts exactly 500 characters and rejects 501 after transformations', () => {
    expect(errorsFor('ã'.repeat(500))).toHaveLength(0);
    expect(errorsFor('ã'.repeat(501))).toEqual(expect.arrayContaining([
      expect.objectContaining({ property: 'reason' }),
    ]));
    expect(errorsFor(`${'ã'.repeat(501)}\u0000`)).toEqual(expect.arrayContaining([
      expect.objectContaining({ property: 'reason' }),
    ]));
  });
});
