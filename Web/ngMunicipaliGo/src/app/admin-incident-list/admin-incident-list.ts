import { Component, signal, inject } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslateModule } from '@ngx-translate/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../services/api-service';
import { SortedIncidentdsDTO, Status, Categories } from '../models/Incidents';
import { QueryParametersDTO } from '../models/Incidents';
import { enumToOptions } from '../utils/enum-utils';
import { IncidentListComponent } from '../incident-list/incident-list.component';
import { IncidentFilterBarComponent } from '../incident-filter-bar/incident-filter-bar.component';

@Component({
  selector: 'app-admin-incident-list',
  standalone: true,
  imports: [RouterModule, CommonModule, TranslateModule, FormsModule, IncidentListComponent, IncidentFilterBarComponent],
  templateUrl: './admin-incident-list.html',
  styleUrls: ['./admin-incident-list.css'],
})

export class AdminIncidentList {
  private pageBeforeSearch = signal(1);
  private searchDebounce: any;
  incidents = signal<SortedIncidentdsDTO[]>([]);
  totalCount = signal(0);
  pageSize = signal(5);
  currentPage = signal(1);
  totalPages = signal(1);
  pagesArray = signal<number[]>([]);
  searchTerm = signal('');
  selectedCategory = signal('');
  selectedStatus = signal('');
  dateFrom = signal<string | undefined>(undefined);
  dateTo = signal<string | undefined>(undefined);
  sort = signal<string>('CreatedAt');
  direction = signal<'asc' | 'desc'>('desc');
  dateField = signal<'creation' | 'closing'>('creation');
  selectOpen = signal(false);
  categories = enumToOptions(Categories);
  statuses = enumToOptions(Status);
  isSearching = signal(false);
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  apiService = inject(ApiService);

  async ngOnInit() {
    await this.loadIncidents();
  }

  onFilterChange() {
    this.loadIncidents();
  }

  onSearchChange() {
    this.isLoading.set(true);
    clearTimeout(this.searchDebounce);
    this.searchDebounce = setTimeout(() => {
      this.loadIncidents();
    }, 1000);
  }

  goToPage(page: number) {
    if (page < 1 || page > this.totalPages())
       return;
    this.currentPage.set(page);
    this.loadIncidents();
  }

  getQueryParamsDTO(): QueryParametersDTO {
    return {
      category: this.selectedCategory() ? +this.selectedCategory() : undefined,
      status: this.selectedStatus() ? +this.selectedStatus() : undefined,
      dateFrom: this.dateFrom() ? this.dateFrom() : undefined,
      dateEnd: this.dateTo() ? this.dateTo() : undefined,
      filterByCreation: this.dateField() === 'creation',
      filterByClosing: this.dateField() === 'closing',
      pageSize: this.pageSize(),
      page: this.currentPage(),
      sort: this.sort(),
      direction: this.direction(),
      search: this.searchTerm() ? this.searchTerm() : undefined,
    };
  }

  async loadIncidents() {
    this.errorMessage.set(null);

    if (this.searchTerm() && !this.isSearching()) {
      this.pageBeforeSearch.set(this.currentPage());
      this.isSearching.set(true);
      this.currentPage.set(1);
    } else if (!this.searchTerm() && this.isSearching()) {
      this.currentPage.set(this.pageBeforeSearch());
      this.isSearching.set(false);
    }

    try {
      const result = await this.apiService.GetAllSortedIncidents(this.getQueryParamsDTO());
      const totalPages = Math.max(1, Math.ceil(result.totalCount / this.pageSize()));

      this.incidents.set(result.incidents);
      this.totalCount.set(result.totalCount);
      this.totalPages.set(totalPages);
      this.pagesArray.set(Array.from({ length: totalPages }, (_, i) => i + 1));

      if (this.currentPage() > totalPages) {
        this.currentPage.set(totalPages);
        await this.loadIncidents();
      }
    } catch {
      this.incidents.set([]);
      this.totalCount.set(0);
      this.totalPages.set(1);
      this.pagesArray.set([1]);
      this.errorMessage.set(
        !navigator.onLine ? 'Pas de connexion Internet' : 'Erreur lors du chargement des incidents'
      );
    } finally {
      this.isLoading.set(false);
    }
  }
}