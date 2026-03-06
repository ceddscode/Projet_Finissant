import { Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { ApiService } from '../services/api-service';
import { CommonModule } from '@angular/common';
import { Status, Categories } from '../models/Incidents';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-confirmation',
  imports: [RouterModule, CommonModule, TranslateModule],
  templateUrl: './confirmation.html',
  styleUrls: ['./confirmation.css'],
})
export class Confirmation implements OnInit {
  incidents: any[] = [];
  Status = Status;
  Categories = Categories;

  language: string = "fr";

  constructor(
    public apiService: ApiService,
    public translator: TranslateService,
  ) {
    this.translator.addLangs(['en', 'fr']);
    this.translator.setFallbackLang(this.language);
    const saved = localStorage.getItem('language');
    if (saved) {
      this.language = saved;
    }
    this.translator.use(this.language);
  }

  async ngOnInit() {
    try {
      this.incidents = await this.apiService.GetNotConfirmedIncidents();
    } catch (e) {
      console.error(e);
      this.incidents = [];
    }
  }

  statusLabel(statusNumber: number) {
    return this.translator.instant(`enums.status.${Status[statusNumber]}`);
  }

  categoryLabel(categoryNumber: number) {
    return this.translator.instant(`enums.category.${Categories[categoryNumber]}`);
  }

  getStatusClass(statusNumber: number): string {
    const statusName = Status[statusNumber];
    if (!statusName) return 'pending';
    
    return statusName.charAt(0).toLowerCase() + statusName.slice(1);
  }

  translateDate(createdAt: string | Date): string {
    try {
      const incidentDate = new Date(createdAt);
      const now = new Date();
      const diff = now.getTime() - incidentDate.getTime();
      
      const minutes = Math.floor(diff / (1000 * 60));
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const days = Math.floor(diff / (1000 * 60 * 60 * 24));
      
      if (minutes < 1) {
        return this.translator.instant('date.justNow');
      } else if (minutes < 60) {
        const key = minutes === 1 ? 'date.minutesAgo_one' : 'date.minutesAgo_other';
        return this.translator.instant(key, { count: minutes });
      } else if (hours < 24) {
        const key = hours === 1 ? 'date.hoursAgo_one' : 'date.hoursAgo_other';
        return this.translator.instant(key, { count: hours });
      } else if (days < 30) {
        const key = days === 1 ? 'date.daysAgo_one' : 'date.daysAgo_other';
        return this.translator.instant(key, { count: days });
      } else {
        const months = Math.floor(days / 30);
        const key = months === 1 ? 'date.monthsAgo_one' : 'date.monthsAgo_other';
        return this.translator.instant(key, { count: months });
      }
    } catch (e) {
      console.error('Error translating date:', e);
      return '';
    }
  }
}