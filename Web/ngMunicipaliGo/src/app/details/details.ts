import { Component, inject, signal } from '@angular/core';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { ApiService } from '../services/api-service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Status, Categories } from '../models/Incidents';
import { TranslateService, TranslateModule } from '@ngx-translate/core';
import { ModalService } from '../modal/modal.service';
import { formatDistanceToNowStrict } from 'date-fns';
import { fr, enUS } from 'date-fns/locale';

@Component({
  selector: 'app-details',
  standalone: true,
  imports: [RouterModule, CommonModule, FormsModule, TranslateModule],
  templateUrl: './details.html',
  styleUrls: ['./details.css'],
})
export class Details {
  private apiService = inject(ApiService);
  private router = inject(Router);
  private translate = inject(TranslateService);
  private modal = inject(ModalService);
  private route = inject(ActivatedRoute);

  Status = Status;
  Categories = Categories;

  incident = signal<any | null>(null);
  incidentHistory = signal<any[]>([]);
  comments = signal<any[]>([]);
  isLoadingComments = signal(false);

  errorType = signal<'none' | 'offline' | 'server'>('none');
  isSubmitting = signal(false);

  isOpen = signal(false);
  currentIndex = signal(0);

  commentPage = 1;
  commentPageSize = 10;
  newComment = '';
  commentsSort: 'newest' | 'mostReported' = 'newest';
  points = '';
  userRole = '';
x: any;

  constructor() {
    const saved = localStorage.getItem('language');
    if (saved) this.translate.use(saved);
    this.userRole = localStorage.getItem('role') ?? '';
    this.init();
  }

  private setError(e: any) {
    if (!navigator.onLine) {
      this.errorType.set('offline');
      return;
    }

    const status = e?.status;
    if (status === 0 || status >= 500) {
      this.errorType.set('server');
      return;
    }

    this.errorType.set('server');
  }

  private async runOnce(action: () => Promise<void>) {
    if (this.isSubmitting()) return;
    this.isSubmitting.set(true);
    try {
      this.errorType.set('none');
      await action();
    } catch (e: any) {
      console.log('STATUS', e?.status);
      console.log('ERROR BODY', e?.error);
      this.setError(e);
    } finally {
      this.isSubmitting.set(false);
    }
  }

  async init() {
    try {
      this.errorType.set('none');

      const id = Number(this.route.snapshot.paramMap.get('id'));
      if (!id) return;

      const inc = await this.apiService.GetDetails(id);
      const hist = await this.apiService.GetIncidentHistory(id);

      const incident = inc ?? {};

      if (incident.createdDate && typeof incident.createdDate === 'string') {
        try { incident.createdAt = new Date(incident.createdDate); } catch {}
      }

      incident.id = Number(incident.id ?? incident.Id ?? id);
      incident.title = String(incident.title ?? incident.Title ?? '');
      incident.description = String(incident.description ?? incident.Description ?? '');
      incident.imagesUrl = Array.isArray(incident.imagesUrl ?? incident.ImagesUrl) ? (incident.imagesUrl ?? incident.ImagesUrl) : [];
      incident.points = Number(incident.points ?? incident.Points ?? '');

      if (incident.status !== undefined && !isNaN(Number(incident.status))) {
        incident.status = Number(incident.status);
      }

      if (incident.category !== undefined && incident.category !== null && !isNaN(Number(incident.category))) {
        incident.categories = Number(incident.category);
      } else if (incident.categories === undefined || incident.categories === null) {
        incident.categories = -1;
      } else if (!isNaN(Number(incident.categories))) {
        incident.categories = Number(incident.categories);
      }

      this.incident.set(incident);
      this.incidentHistory.set(Array.isArray(hist) ? hist : []);

      await this.loadComments();
    } catch (e) {
      this.setError(e);
      this.incident.set(null);
      this.incidentHistory.set([]);
      this.comments.set([]);
    }
  }

  retry() {
    this.runOnce(async () => {
      await this.init();
    });
  }
clearPoints(e: MouseEvent) {
  e.preventDefault();
  this.points = '';
}
  goBack() {
    window.history.back();
  }

 async approveIncident(points: any) {
  await this.runOnce(async () => {
    const inc = this.incident();
    if (!inc) return;

    const dto = { Points: Number(points) };

    await this.apiService.ApproveIncident(inc.id, dto);

    this.router.navigate(['/attente']);
    this.modal.open({
      title: this.translate.instant('details.alerts.approved'),
      type: 'success',
    });
  });
}

  async refuseIncident() {
    await this.runOnce(async () => {
      const inc = this.incident();
      if (!inc?.id) return;

      await this.apiService.RefuseIncident(inc.id);
      this.router.navigate(['/attente']);

      this.modal.open({
        title: this.translate.instant('details.alerts.refused'),
        type: 'danger',
      });
    });
  }

  async assignIncidentToCitizen() {
    await this.runOnce(async () => {
      const inc = this.incident();
      if (!inc?.id) return;

      await this.apiService.AssignIncidentToCitizen(inc.id);
      this.router.navigate(['/assignation']);

      this.modal.open({
        title: this.translate.instant('details.alerts.assignedToCitizen'),
        type: 'danger',
      });
    });
  }

  async assignIncidentToBlueCollar() {
    await this.runOnce(async () => {
      const inc = this.incident();
      if (!inc?.id) return;

      await this.apiService.AssignIncidentToBlueCollar(inc.id);
      this.router.navigate(['/assignation']);

      this.modal.open({
        title: this.translate.instant('details.alerts.assignedToBlueCollar'),
        type: 'danger',
      });
    });
  }

  async editIncident() {
    await this.runOnce(async () => {
      const inc = this.incident();
      if (!inc?.id) return;

      const dto = {
        Id: Number(inc.id),
        Title: String(inc.title ?? ''),
        Description: String(inc.description ?? ''),
        Categories: Number(inc.categories),
        
        ImagesUrl: Array.isArray(inc.imagesUrl) ? inc.imagesUrl : []
      };

      await this.apiService.EditIncident(inc.id, dto);

      this.modal.open({
        title: this.translate.instant('details.alerts.edited'),
        type: 'success',
      });

      this.goBack();
    });
  }

  async loadComments() {
    this.isLoadingComments.set(true);
    try {
      this.errorType.set('none');

      const inc = this.incident();
      if (!inc?.id) {
        this.comments.set([]);
        return;
      }

      const list = await this.apiService.GetComments(inc.id, this.commentPage, this.commentPageSize);
      const base = Array.isArray(list) ? [...list] : [];

      if (this.commentsSort === 'mostReported') {
        base.sort((a, b) => (b.reportsCount || 0) - (a.reportsCount || 0));
      } else {
        base.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
      }
      this.comments.set(base);
    } catch (e) {
      this.setError(e);
      this.comments.set([]);
    } finally {
      this.isLoadingComments.set(false);
    }
  }

  applyCommentsSort() {
    this.loadComments();
  }

  async postComment() {
    await this.runOnce(async () => {
      const inc = this.incident();
      if (!inc?.id) return;
      if (!this.newComment.trim()) return;

      await this.apiService.PostComment(inc.id, this.newComment);
      this.newComment = '';
      await this.loadComments();
    });
  }

  async deleteComment(commentId: number) {
    await this.runOnce(async () => {
      await this.apiService.DeleteComment(commentId);
      await this.loadComments();
    });
  }

  openCarousel(index: number) {
    this.currentIndex.set(index);
    this.isOpen.set(true);
  }

  closeCarousel() {
    this.isOpen.set(false);
  }

  prev() {
    const i = this.currentIndex();
    if (i > 0) this.currentIndex.set(i - 1);
  }

  next() {
    const inc = this.incident();
    const len = inc?.imagesUrl?.length ?? 0;
    const i = this.currentIndex();
    if (i < len - 1) this.currentIndex.set(i + 1);
  }

  translateDate(createdAt: string | Date): string {
    const date = new Date(createdAt);
    if (isNaN(date.getTime())) return '';

    const locale = this.translate.currentLang === 'fr' ? fr : enUS;

    const r = formatDistanceToNowStrict(date, {
      addSuffix: false,
      roundingMethod: 'floor',
      locale,
    });

    const m = r.match(/(\d+)\s+(\w+)/);
    if (!m) return this.translate.instant('date.justNow');

    const count = Number(m[1]);
    const unit = m[2].toLowerCase();

    if (count <= 0) return this.translate.instant('date.justNow');

    if (unit.startsWith('minute') || unit === 'min') {
      const key = count === 1 ? 'date.minutesAgo_one' : 'date.minutesAgo_other';
      return this.translate.instant(key, { count });
    }

    if (unit.startsWith('hour') || unit.startsWith('heure')) {
      const key = count === 1 ? 'date.hoursAgo_one' : 'date.hoursAgo_other';
      return this.translate.instant(key, { count });
    }

    if (unit.startsWith('day') || unit.startsWith('jour')) {
      const key = count === 1 ? 'date.daysAgo_one' : 'date.daysAgo_other';
      return this.translate.instant(key, { count });
    }

    if (unit.startsWith('month') || unit.startsWith('mois')) {
      const key = count === 1 ? 'date.monthsAgo_one' : 'date.monthsAgo_other';
      return this.translate.instant(key, { count });
    }

    if (unit.startsWith('year') || unit.startsWith('an')) {
      const key = count === 1 ? 'date.yearsAgo_one' : 'date.yearsAgo_other';
      return this.translate.instant(key, { count });
    }

    return this.translate.instant('date.justNow');
  }

  categories = [
    { value: 0, label: 'enums.category.Propreté' },
    { value: 1, label: 'enums.category.Mobilier' },
    { value: 2, label: 'enums.category.Signalisation' },
    { value: 3, label: 'enums.category.EspacesVerts' },
    { value: 4, label: 'enums.category.Saisonnier' },
    { value: 5, label: 'enums.category.Social' },
  ];

  categoryLabel(categoryValue: number | string) {
    const normalize = (s: string) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/\s+/g, '').toLowerCase();

    let key: string | undefined;
    if (typeof categoryValue === 'number') {
      key = Categories[categoryValue];
    } else if (!isNaN(Number(categoryValue))) {
      key = Categories[Number(categoryValue)];
    } else if (typeof categoryValue === 'string') {
      if ((Categories as any)[categoryValue] !== undefined) {
        key = categoryValue;
      } else {
        const keys = Object.keys(Categories).filter(k => isNaN(Number(k)));
        const found = keys.find(k => normalize(k) === normalize(categoryValue));
        if (found) key = found;
      }
    }

    if (!key) key = String(categoryValue);
    return this.translate.instant(`enums.category.${key}`);
  }

  getHistoryIcon(type: number): string {
    switch (type) {
      case 0: return 'fas fa-plus-circle';
      case 1: return 'fas fa-check-circle';
      case 2: return 'fas fa-user-tag';
      case 3: return 'fas fa-hand-paper';
      case 4: return 'fas fa-user-gear';
      case 5: return 'fas fa-screwdriver-wrench';
      case 6: return 'fas fa-circle-check';
      case 7: return 'fas fa-circle-xmark';
      case 8: return 'fas fa-thumbs-up';
      default: return 'fas fa-circle';
    }
  }

  interventionLabel(type: number): string {
    switch (type) {
      case 0: return this.translate.instant('interventionType.Created');
      case 1: return this.translate.instant('interventionType.Validated');
      case 2: return this.translate.instant('interventionType.AssignedToCitizen');
      case 3: return this.translate.instant('interventionType.TaskTookByCitizen');
      case 4: return this.translate.instant('interventionType.AssignedToBlueCollar');
      case 5: return this.translate.instant('interventionType.UnderRepair');
      case 6: return this.translate.instant('interventionType.DoneRepairing');
      case 7: return this.translate.instant('interventionType.RefusedRepair');
      case 8: return this.translate.instant('interventionType.ApprovedRepair');
      default: return 'error';
    }
  }

  roleLabel(type: string): string {
    switch (type) {
      case '1': return this.translate.instant('role.WhiteCollar');
      case '2': return this.translate.instant('role.BlueCollar');
      case '3': return this.translate.instant('role.Citizen');
      case '4': return this.translate.instant('role.Admin');
      default: return 'error';
    }
  }

  isConfirmationImgOpen = false;
confirmationImgIndex = 0;

openConfirmationImage(idx: number) {
  this.confirmationImgIndex = idx;
  this.isConfirmationImgOpen = true;
}

closeConfirmationImgModal() {
  this.isConfirmationImgOpen = false;
}

prevConfirmationImg() {
  if (this.confirmationImgIndex > 0) this.confirmationImgIndex--;
}

nextConfirmationImg() {
  const imgs = this.incident()?.confirmationImagesUrl;
  if (imgs && this.confirmationImgIndex < imgs.length - 1) {
    this.confirmationImgIndex++;
  }
}

}