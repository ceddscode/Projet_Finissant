import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DetailsConfirmation } from './details-confirmation';

describe('DetailsConfirmation', () => {
  let component: DetailsConfirmation;
  let fixture: ComponentFixture<DetailsConfirmation>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DetailsConfirmation]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DetailsConfirmation);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
