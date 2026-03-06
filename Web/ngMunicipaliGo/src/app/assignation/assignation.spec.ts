import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Assignation } from './assignation';

describe('Assignation', () => {
  let component: Assignation;
  let fixture: ComponentFixture<Assignation>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Assignation]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Assignation);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
