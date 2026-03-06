import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ModalService } from './modal.service';
import { FormsModule } from '@angular/forms';
import { TranslateModule } from '@ngx-translate/core';

@Component({
  selector: 'app-confirm-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, TranslateModule],
  template: `
    <div class="overlay" *ngIf="modal.open$ | async">
      <div class="modal" [ngClass]="modal.type$ | async">

        <h2>{{ modal.title$ | async | translate }}</h2>

        <ng-container *ngIf="(modal.kind$ | async) === 'simple'">
          <button class="ok-btn" (click)="modal.close()">{{ 'modal.ok' | translate }}</button>
        </ng-container>

        <ng-container *ngIf="(modal.kind$ | async) === 'refuse'">
          <textarea
            [(ngModel)]="description"
            [placeholder]="modal.descPlaceholder$ | async"
            rows="4"
            class="description-field">
          </textarea>
          <div class="actions">
            <button class="btn ghost" (click)="modal.close()">{{ 'modal.cancel' | translate }}</button>
            <button class="btn danger" (click)="confirmRefuse()">{{ 'modal.refuse' | translate }}</button>
          </div>
        </ng-container>

      </div>
    </div>
  `,
  styleUrls: ['./confirm-modal.component.css'],
})
export class ConfirmModalComponent {
  constructor(public modal: ModalService) { }

  description: string = '';

  confirmRefuse() {
    this.modal.close(this.description);
    this.description = '';
  }
}