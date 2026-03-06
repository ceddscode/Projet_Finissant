import { Component, OnInit, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { TranslateService, TranslateModule } from '@ngx-translate/core';
import { ApiService } from '../services/api-service';
import { Citizen } from '../models/Incidents';

@Component({
  selector: 'app-user-details',
  imports: [RouterModule, CommonModule, ReactiveFormsModule, TranslateModule],
  templateUrl: './user-details.html',
  styleUrls: ['./user-details.css'],
})
export class UserDetails implements OnInit {

  user = signal<Citizen | null>(null);
  userId!: string;
  language: string = "fr";
  isSaving = signal(false);
  isOnline = signal(navigator.onLine);

  selectedUserId: number | null = null;

  formGroup!: FormGroup;

  // Utilisation de l'API d'injection moderne
  public apiService = inject(ApiService);
  private route = inject(ActivatedRoute);
  private translator = inject(TranslateService);
  private router = inject(Router);

  private fb = inject(FormBuilder);

  async ngOnInit() {
    // Initialiser le formulaire ici (fb est disponible via inject)


    // 👇 écoute connexion
    window.addEventListener('online', () => {
      this.isOnline.set(true);
    });

    window.addEventListener('offline', () => {
      this.isOnline.set(false);
    });

    
    this.formGroup = this.fb.group({
      firstName: [
        '',
        [
          Validators.required,
          Validators.minLength(2),
          Validators.maxLength(50)
        ]
      ],

      lastName: [
        '',
        [
          Validators.required,
          Validators.minLength(2),
          Validators.maxLength(50)
        ]
      ],

      email: [
        '',
        [
          Validators.required,
          Validators.email
        ]
      ],

      phoneNumber: [
        '',
        [
          Validators.required,
          Validators.pattern(/^(\+1\s?)?(\(?\d{3}\)?[\s\-]?)?\d{3}[\s\-]?\d{4}$/)
        ]
      ],
      role: ['', Validators.required],


      roadNumber: [
        null,
        [
          Validators.required,
          Validators.min(1),
          Validators.max(999999)
        ]
      ],

      roadName: [
        '',
        [
          Validators.required,
          Validators.minLength(2),
          Validators.maxLength(100)
        ]
      ],

      postalCode: [
        '',
        [
          Validators.required,
          Validators.pattern(/^[A-Za-z]\d[A-Za-z][ ]?\d[A-Za-z]\d$/)
        ]
      ],

      city: [
        '',
        [
          Validators.required,
          Validators.minLength(2),
          Validators.maxLength(80)
        ]
      ]
    });

    // Traduction
    this.translator.addLangs(['en', 'fr']);
    this.translator.setFallbackLang(this.language);
    const saved = localStorage.getItem('language');
    if (saved) {
      this.language = saved;
    }
    this.translator.use(this.language);

    const Id = this.route.snapshot.paramMap.get('id');

    console.log('USER ID FROM ROUTE:', Id);

    if (!Id) {
      console.error('ID manquant dans la route');
      this.router.navigate(['/admin']); // sécurité
      return;
    }

    this.userId = Id;
    this.loadUser();
  }

  async loadUser() {
    const user = await this.apiService.GetUserById(this.userId);

    if (!user) {
      console.error('User not found');
      this.router.navigate(['/admin']);
      return;
    }

    this.user.set(user);

    this.formGroup.patchValue({
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.role,
      roadNumber: user.roadNumber,
      roadName: user.roadName,
      city: user.city,
      postalCode: user.postalCode
    });

    if (user.role === 'Admin') {
      this.formGroup.get('role')?.disable();
    }
  }

  async saveChanges() {
    if (this.formGroup.invalid) {
      this.formGroup.markAllAsTouched();
      return;
    }

    const currentUser = this.user();
    if (!currentUser) return;

    const updatedUser: Citizen = {
      ...currentUser,
      ...this.formGroup.value
    };

    this.isSaving.set(true);

    try {
      await this.apiService.UpdateUser(currentUser.id, updatedUser);
    } catch (error) {
      console.error('Failed to update user:', error);
      return;
    }

    this.router.navigate(['/admin']);
  }

  isAdmin() {
    return localStorage.getItem("role") === "Admin";

  }

}