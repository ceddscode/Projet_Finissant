import { Component, ChangeDetectionStrategy, input, output } from '@angular/core';
import { SortedIncidentdsDTO } from '../models/Incidents';
import { StatusLabelPipe } from '../pipes/statusLabel/status-label-pipe';
import { CategoryLabelPipe } from '../pipes/categoryLabel/category-label.pipe';
import { StatusClassPipe } from '../pipes/statusClass/status-class.pipe';
import { TranslateModule } from '@ngx-translate/core';
import { AsyncPipe, DatePipe } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-incident-list',
  templateUrl: './incident-list.component.html',
  imports: [RouterModule, StatusLabelPipe, CategoryLabelPipe, StatusClassPipe, TranslateModule, AsyncPipe, DatePipe],
  styleUrls: ['./incident-list.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IncidentListComponent {
  readonly incidents = input<SortedIncidentdsDTO[]>();
  readonly isLoading = input<boolean>();
  readonly currentPage = input<number>();
  readonly totalPages = input<number>();
  readonly pagesArray = input<number[]>();
  readonly errorMessage = input<string | null>();

  readonly pageChange = output<number>();

  goToPage(page: number) {
    const total = this.totalPages?.() ?? 1;
    if (page < 1 || page > total) return;
    this.pageChange.emit(page);
  }
}
