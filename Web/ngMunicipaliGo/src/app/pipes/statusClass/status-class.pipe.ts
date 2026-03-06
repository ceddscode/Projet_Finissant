import { Pipe, PipeTransform } from '@angular/core';
import { Status } from '../../models/Incidents';

@Pipe({ name: 'statusClass', standalone: true })
export class StatusClassPipe implements PipeTransform {
    transform(statusNumber: number): string {
        const statusName = Status[statusNumber];
        if (!statusName) return 'pending';
        return statusName.charAt(0).toLowerCase() + statusName.slice(1);
    }
}