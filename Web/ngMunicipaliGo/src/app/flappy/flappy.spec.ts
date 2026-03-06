import { ComponentFixture, TestBed } from '@angular/core/testing';

import { Flappy } from './flappy';

describe('Flappy', () => {
  let component: Flappy;
  let fixture: ComponentFixture<Flappy>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [Flappy]
    })
    .compileComponents();

    fixture = TestBed.createComponent(Flappy);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
