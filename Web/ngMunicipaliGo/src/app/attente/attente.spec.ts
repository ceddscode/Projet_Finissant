import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Attente } from './attente';

describe('Attente', () => {
  let component: Attente;
  let fixture: ComponentFixture<Attente>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Attente]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Attente);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
