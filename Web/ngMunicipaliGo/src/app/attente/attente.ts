import { Component, OnInit } from '@angular/core';
import { RouterModule } from '@angular/router';
import { ApiService } from '../services/api-service';
import { CommonModule } from '@angular/common';
import { Status, Categories, QueryParametersDTO, PagedResult, SortedIncidentdsDTO } from '../models/Incidents';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { enumToOptions } from '../utils/enum-utils';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-attente',
  imports: [RouterModule, CommonModule, TranslateModule, FormsModule],
  templateUrl: './attente.html',
  styleUrls: ['./attente.css'],
})
export class Attente implements OnInit {
private pageBeforeSearch: number = 1;
  private searchDebounce: any;
  incidents: any[] = [];
  Status = Status;
  Categories = Categories;
  language: string = 'fr';
  totalCount: number = 0;
  pageSize: number = 5;
  currentPage: number = 1;
  totalPages: number = 1;
  pagesArray: number[] = [];
  searchTerm: string = '';
  selectedCategory: string = '';
  selectedStatus: string = '';
  dateFrom?: string;
  dateTo?: string;
  sort?: string = 'CreatedAt';
  direction: 'asc' | 'desc' = 'desc';
  dateField: 'creation' | 'closing' = 'creation';
  selectOpen: boolean = false;
  search?: string;
  isSearching: boolean = false;
  categories = enumToOptions(Categories);
  statuses = enumToOptions(Status);
  isLoading: boolean = false;

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
    this.loadIncidents();
  }

    async loadIncidents() {
      if (this.searchTerm && !this.isSearching) {
        this.pageBeforeSearch = this.currentPage;
        this.isSearching = true;
        this.currentPage = 1;
      }

      if (!this.searchTerm && this.isSearching) {
        this.currentPage = this.pageBeforeSearch;
        this.isSearching = false;
      }

      let filter: QueryParametersDTO = {
        category: this.selectedCategory ? +this.selectedCategory : undefined,
        status: this.selectedStatus ? +this.selectedStatus : undefined,
        dateFrom: this.dateFrom ? this.dateFrom : undefined,
        dateEnd: this.dateTo ? this.dateTo : undefined,
        filterByCreation: this.dateField === 'creation',
        filterByClosing: this.dateField === 'closing',
        pageSize: this.pageSize,
        page: this.currentPage,
        sort: this.sort,
        direction: this.direction,
        search: this.searchTerm ? this.searchTerm : undefined,
      };
  
      try {
        let result: PagedResult<SortedIncidentdsDTO> = await this.apiService.GetNotValidatedSortedIncidents(filter);
        this.incidents = result.incidents;
        this.totalCount = result.totalCount;
        this.totalPages = Math.ceil(this.totalCount / this.pageSize);
  
        if (this.totalPages < 1)
          this.totalPages = 1;

        if (this.currentPage > this.totalPages) {
          this.currentPage = this.totalPages;
          await this.loadIncidents();
          return;
        }
  
        this.pagesArray = Array.from({ length: this.totalPages }, (_, i) => i + 1);
  
      } catch (e) {
        console.error(e);
        this.incidents = [];
        this.totalCount = 0;
        this.totalPages = 1;
        this.pagesArray = [1];
      } finally {
        this.isLoading = false;
      }
    }

  onFilterChange() {
    this.loadIncidents();
  }

  onSearchChange() {
    this.isLoading = true;
    clearTimeout(this.searchDebounce);
    this.searchDebounce = setTimeout(() => {
      this.loadIncidents();
    }, 1000);
  }

  goToPage(page: number) {
    if (page < 1 || page > this.totalPages)
       return;

    this.currentPage = page;
    this.loadIncidents();
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