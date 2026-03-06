import { Component, ChangeDetectionStrategy, input, output } from '@angular/core';
import { CategoryLabelPipe } from '../pipes/categoryLabel/category-label.pipe';
import { StatusLabelPipe } from '../pipes/statusLabel/status-label-pipe';
import { TranslateModule } from '@ngx-translate/core';
import { FormsModule } from '@angular/forms';
import { AsyncPipe } from '@angular/common';

@Component({
  selector: 'app-incident-filter-bar',
  templateUrl: './incident-filter-bar.component.html',
  styleUrls: ['./incident-filter-bar.component.css'],
  imports: [CategoryLabelPipe, StatusLabelPipe, TranslateModule, FormsModule, AsyncPipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IncidentFilterBarComponent {
  readonly searchTerm = input<string>();
  readonly isLoading = input<boolean>();
  readonly selectedCategory = input<string>();
  readonly selectedStatus = input<string>();
  readonly sort = input<string>();
  readonly direction = input<'asc' | 'desc'>();
  readonly dateFrom = input<string>();
  readonly dateTo = input<string>();
  readonly dateField = input<'creation' | 'closing'>();
  readonly categories = input<any[]>();
  readonly statuses = input<any[]>();

  readonly searchTermChange = output<string>();
  readonly selectedCategoryChange = output<string>();
  readonly selectedStatusChange = output<string>();
  readonly sortChange = output<string>();
  readonly directionChange = output<'asc' | 'desc'>();
  readonly dateFromChange = output<string>();
  readonly dateToChange = output<string>();
  readonly dateFieldChange = output<'creation' | 'closing'>();
}
