import { Pipe, PipeTransform, OnDestroy } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { Status } from '../../models/Incidents';
import { Observable } from 'rxjs';

@Pipe({ name: 'statusLabel', standalone: true, pure: false })
export class StatusLabelPipe implements PipeTransform {

  constructor(private translator: TranslateService) {}

  transform(status: number | string): Observable<string> {

    let key: string;

    if (typeof status === 'number') {
      key = Status[status];
    } else {
      key = status; // already enum name
    }

    return this.translator.stream(`enums.status.${key}`);
  }
}