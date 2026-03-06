import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { TranslateService, TranslateModule } from '@ngx-translate/core';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../services/api-service';
import { SortedIncidentdsDTO, Status, Categories } from '../models/Incidents';
import { QueryParametersDTO, PagedResult } from '../models/Incidents';
import { enumToOptions } from '../utils/enum-utils';
import { IncidentListDTO } from '../models/Incidents';
@Component({
  selector: 'app-whitecolar-all',
  standalone: true,
  imports: [RouterModule, CommonModule, TranslateModule, FormsModule],
  templateUrl: './whitecolar-all.html',
  styleUrls: ['./whitecolar-all.css'],
})

export class WhitecolarAll {
   private pageBeforeSearch: number = 1;
  private searchDebounce: any;
  language: string = 'fr';
  incidents: SortedIncidentdsDTO[] = [];
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
  categories = enumToOptions(Categories);
  statuses = enumToOptions(Status);
  search?: string;
  isSearching: boolean = false;
  exportModalOpen = false;
  constructor(public apiService: ApiService, private translator: TranslateService) {
  }

  async ngOnInit() {
    await this.loadIncidents();
  }

  onFilterChange() {
    this.loadIncidents();
  }

  onSearchChange() {
    clearTimeout(this.searchDebounce);
    this.searchDebounce = setTimeout(() => {
      this.loadIncidents();
    }, 50);
  }

  goToPage(page: number) {
    if (page < 1 || page > this.totalPages)
       return;

    this.currentPage = page;
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
      let result: PagedResult<SortedIncidentdsDTO> = await this.apiService.GetAllSortedIncidents(filter);
this.incidents = result.incidents;
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


openExportModal() { this.exportModalOpen = true; }
closeExportModal() { this.exportModalOpen = false; }

private buildFilter(): QueryParametersDTO {
  return {
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
}

async export(format: 'pdf' | 'excel' | 'csv' | 'json') {
  const filter = this.buildFilter();

  if (format === 'excel') await this.apiService.ExportIncidentsToExcel(filter);
  if (format === 'pdf') await this.apiService.ExportIncidentsToPDF(filter);
  if (format === 'json') await this.apiService.ExportIncidentsToJSON(filter);

  this.closeExportModal();
}
}
