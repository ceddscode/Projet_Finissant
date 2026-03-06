import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, Validators, ReactiveFormsModule, AbstractControl, ValidationErrors, FormGroup } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { ApiService } from '../services/api-service';
import { ModalService } from '../modal/modal.service';
import { RegisterDTO } from '../models/Incidents';

function passwordMatchValidator(group: AbstractControl): ValidationErrors | null {
  const password = group.get('password')?.value;
  const confirm = group.get('passwordConfirm')?.value;
  if (!password || !confirm) return null;
  return password === confirm ? null : { passwordMismatch: true };
}

@Component({
  selector: 'app-user-create',
  standalone: true,
  imports: [RouterModule, CommonModule, ReactiveFormsModule, TranslateModule],
  templateUrl: './user-create.html',
  styleUrl: './user-create.css',
})
export class UserCreate {
  language = 'fr';
  form: FormGroup;

  constructor(
    public apiService: ApiService,
    private translator: TranslateService,
    public router: Router,
    private modal: ModalService,
    private fb: FormBuilder
  ) {
    this.form = this.fb.group(
      {
        firstName: ['', [Validators.required, Validators.minLength(2)]],
        lastName: ['', [Validators.required, Validators.minLength(2)]],
        email: ['', [Validators.required, Validators.pattern(/^\S+@\S+\.\S+$/)]],
        phoneNumber: ['', [Validators.required, Validators.pattern(/^(\+1\s?)?(\(?\d{3}\)?[\s\-]?)?\d{3}[\s\-]?\d{4}$/)]],
        password: ['', [Validators.required, Validators.minLength(5)]],
        passwordConfirm: ['', [Validators.required]],
        roadNumber: [0, [Validators.required, Validators.min(1)]],
        roadName: ['', [Validators.required]],
        postalCode: ['', [Validators.required, Validators.pattern(/^[A-Za-z]\d[A-Za-z][ ]?\d[A-Za-z]\d$/)]],
        city: ['', [Validators.required]],
      },
      { validators: passwordMatchValidator }
    );

    this.translator.addLangs(['en', 'fr']);
    this.translator.setFallbackLang(this.language);

    const savedLanguage = localStorage.getItem('language');
    if (savedLanguage) this.language = savedLanguage;

    this.translator.use(this.language);
  }
  goBack() { this.router.navigate(['/admin']); }

  get f() {
    return this.form.controls;
  }

  async Create() {
    this.form.markAllAsTouched();
    if (this.form.invalid) return;

    const v = this.form.getRawValue();

    const dto: RegisterDTO = {
      firstName: v.firstName ?? '',
      lastName: v.lastName ?? '',
      email: v.email ?? '',
      phoneNumber: v.phoneNumber ?? '',
      password: v.password ?? '',
      passwordConfirm: v.passwordConfirm ?? '',
      roadNumber: v.roadNumber ?? 0,
      roadName: v.roadName ?? '',
      postalCode: v.postalCode ?? '',
      city: v.city ?? '',
    };

    await this.apiService.createUser(dto);
    this.router.navigate(['/admin']);
  }
}