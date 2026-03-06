import { Component } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { Router, RouterLink } from '@angular/router';
import { ApiService } from '../services/api-service';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [ ReactiveFormsModule,
    MatButtonModule,
    MatInputModule,
    MatFormFieldModule,
    MatSnackBarModule,
    TranslateModule,
  CommonModule],
  templateUrl: './login.html',
  styleUrl: './login.css',
})
export class Login {
  language : string = "fr";
 formGroup: FormGroup;
  constructor(private formBuilder: FormBuilder, private apiService: ApiService, private snackBar: MatSnackBar, private router: Router, public translator: TranslateService){  
    this.formGroup = this.formBuilder.group(
      {
        courriel: ['', [Validators.required, Validators.email]],
        password: ['', [Validators.required]],
      },
    );

    this.translator.addLangs(['en', 'fr']);
    this.translator.setFallbackLang(this.language);
    const saved = localStorage.getItem('language');
    if (saved) {
      this.language = saved;
    }
    this.translator.use(this.language);

  }

  async login() {
     this.formGroup.markAllAsTouched(); 
    if (!this.formGroup.valid) {
      return;
    }
    
    const courriel = this.formGroup.get('courriel')?.value;
    const password = this.formGroup.get('password')?.value;

    let errorMessage: string = "";

    

    try {
      await this.apiService.login(courriel, password);
      //console.log('Login réussi pour', courriel, 'token=', localStorage.getItem('token'));

      const role = localStorage.getItem('role');
      console.log('ROLE EXACT =', JSON.stringify(role));
      console.log('role=', localStorage.getItem('role'));
      if (role?.toLowerCase().trim() === 'admin') {
      this.router.navigate(['/admin']);
      } else {
      this.router.navigate(['/attente']);
      }
    } catch (err: any) {
      if (err.error && err.error.message){
        errorMessage = err.error.message;
      } else {
        errorMessage = "Une erreur est survenue, veuillez réessayer.";
      }
      this.snackBar.open(errorMessage, 'Fermer', { duration: 5000 });
    }
  }
}
