import { Pipe, PipeTransform } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { Categories } from '../../models/Incidents';
import { Observable } from 'rxjs';

@Pipe({ name: 'categoryLabel', standalone: true, pure: false })
export class CategoryLabelPipe implements PipeTransform {
    constructor(private translator: TranslateService) {}
    transform(categoryNumber: number): Observable<string> {
        return this.translator.stream(`enums.category.${Categories[categoryNumber]}`);
    }
}