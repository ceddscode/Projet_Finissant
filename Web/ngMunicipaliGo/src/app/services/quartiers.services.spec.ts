import { TestBed } from '@angular/core/testing';

import { QuartiersServices } from './quartiers.services';

describe('QuartiersServices', () => {
  let service: QuartiersServices;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(QuartiersServices);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
