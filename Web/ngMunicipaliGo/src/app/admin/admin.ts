import { Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { ApiService } from '../services/api-service';
import { CommonModule } from '@angular/common';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [RouterModule, CommonModule, TranslateModule],
  templateUrl: './admin.html',
  styleUrls: ['./admin.css'],
})
export class Admin implements OnInit {

  users: any[] = [];
  language: string = 'fr';

  constructor(
    public apiService: ApiService,
    public translator: TranslateService
  ) {
    this.translator.addLangs(['en', 'fr']);
    this.translator.setFallbackLang(this.language);

    const savedLanguage = localStorage.getItem('language');
    if (savedLanguage) {
      this.language = savedLanguage;
    }

    this.translator.use(this.language);
  }

  async ngOnInit(): Promise<void> {
    try {
      this.users = await this.apiService.GetUsers();
    } catch (error) {
      console.error(error);
      this.users = [];
    }
  }

  roleLabel(role: string): string {
    switch (role) {
      case 'Admin':
        return 'roles.admin';
      case 'Citizen':
        return 'roles.citizen';
      case 'Blue collar':
        return 'roles.blueCollar';
      case 'White collar':
        return 'roles.whiteCollar';
      default:
        return role;
    }
  }
}