import { Component, OnInit } from '@angular/core';
import { RouterModule, ActivatedRoute } from '@angular/router';
import { ApiService } from '../services/api-service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Status, Categories } from '../models/Incidents';
import { TranslateService, TranslateModule } from '@ngx-translate/core';
import { Router } from '@angular/router';
import { ModalService } from '../modal/modal.service';

@Component({
  selector: 'app-details-confirmation',
  standalone: true,
  imports: [RouterModule, CommonModule, FormsModule, TranslateModule],
  templateUrl: './details-confirmation.html',
  styleUrl: './details-confirmation.css',
})

export class DetailsConfirmation implements OnInit {
  incident!: any;
  Status = Status;
  Categories = Categories;
  isSuccessOverlayOpen = false;
  selectedIncidentID: number = 1;
  carouselImageUrls: string[] = [];
  incidentHistory: any[] = [];


  constructor(public apiService: ApiService, private route: ActivatedRoute, private translate: TranslateService, private router: Router, private modal: ModalService) {
    const saved = localStorage.getItem('language');
    if (saved) {
      this.translate.use(saved);
    }
  }

  async ngOnInit() {
    const id = Number(this.route.snapshot.paramMap.get('id'));

    if (!id) {
      console.error('ID invalide');
      return;
    }
    this.incident = await this.apiService.GetConfirmationDetails(id);
    console.log(this.incident);
    this.incidentHistory = await this.apiService.GetIncidentHistory(id);
    this.Status = Status;
    this.Categories = Categories;
    console.log(this.incident);

    // --- Normalize response fields to avoid issues in template ---
    if (!this.incident) this.incident = {};

    // IncidentDetailsDTO: createdDate comes as string, convert to Date for pipe
    if (this.incident.createdDate && typeof this.incident.createdDate === 'string') {
      try {
        this.incident.createdAt = new Date(this.incident.createdDate);
      } catch (e) {
        // keep original if conversion fails
      }
    }

    // Ensure images array exists (DTO uses imagesUrl)
    this.incident.imagesUrl = this.incident.imagesUrl ?? [];
    this.incident.confirmationImagesUrl = this.incident.confirmationImagesUrl ?? [];

    // Status comes as number from DTO (0, 1, 2, etc.)
    if (this.incident.status !== undefined && !isNaN(Number(this.incident.status))) {
      this.incident.status = Number(this.incident.status);
    }

    // Categories: API might return 'categories' or 'category', prefer 'category' if it has a valid value
    // If categories is -1 but category has a value, use category instead
    if (this.incident.category !== undefined && this.incident.category !== null && !isNaN(Number(this.incident.category))) {
      this.incident.categories = Number(this.incident.category);
    } else if (this.incident.categories === undefined || this.incident.categories === null) {
      this.incident.categories = -1;
    } else if (!isNaN(Number(this.incident.categories))) {
      this.incident.categories = Number(this.incident.categories);
    }
  }

  async confirmIncident() {
    if (this.incident.id != null) {
      await this.apiService.ConfirmIncident(this.incident.id);
      this.router.navigate(['/confirmation'])

      this.modal.open({
        title: this.translate.instant('details.alerts.confirmed'),
        type: 'danger',
      });
    }
  }

  async refuseIncident() {
    if (this.incident.id == null) return;

    this.modal.open({
      title: this.translate.instant('details.alerts.refused'),
      type: 'danger',
      kind: 'refuse',
      descPlaceholder: this.translate.instant('details.alerts.descPlaceholderRefused'),
      onClose: async (description?: string) => {

        if (description === undefined) return;

        await this.apiService.RefuseConfirmationIncident(
          this.incident.id,
          description
        );

        this.router.navigate(['/confirmation']);
      }
    });
  }


  goBack() {
    window.history.back();
  }

  async approveIncident() {
    if (this.incident.id != null) {
      await this.apiService.ApproveIncident(this.incident.id,{ points: 0 });
      this.router.navigate(['/attente']);

      this.modal.open({
        title: this.translate.instant('details.alerts.approved'),
        type: 'success',
      });
    }
  }

  selectedImage: string | null = null;

  openImage(url: string) {
    this.selectedImage = url;
  }

  closeImage() {
    this.selectedImage = null;
  }
  isOpen = false;
  currentIndex = 0;

  openCarousel(nomListeImage: string, imageIndex: number) {
    if (nomListeImage == "confirmationImagesUrl") {
      this.carouselImageUrls = this.incident.confirmationImagesUrl;
      this.currentIndex = imageIndex;
    }
    else if (nomListeImage == "imagesUrl") {
      this.carouselImageUrls = this.incident.imagesUrl;
      this.currentIndex = imageIndex;
    }
    else {
      this.carouselImageUrls = [];
    }
    this.isOpen = true;
  }

  closeCarousel() {
    this.isOpen = false;
  }

  prev() {
    if (this.currentIndex > 0) this.currentIndex--;
  }

  next() {
    if (this.currentIndex < this.carouselImageUrls.length - 1) this.currentIndex++;
  }


  statusLabel(statusNumber: number) {
    return this.translate.instant(`enums.status.${Status[statusNumber]}`);
  }

  categoryLabel(categoryValue: number | string) {
    // Normalize incoming value (could be number, numeric string, or enum name)
    const normalize = (s: string) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/\s+/g, '').toLowerCase();

    let key: string | undefined;
    if (typeof categoryValue === 'number') {
      key = Categories[categoryValue];
    } else if (!isNaN(Number(categoryValue))) {
      key = Categories[Number(categoryValue)];
    } else if (typeof categoryValue === 'string') {
      // Try direct match
      if ((Categories as any)[categoryValue] !== undefined) {
        key = categoryValue;
      } else {
        // Try to find a key matching when normalized (ignore accents/spaces/case)
        const keys = Object.keys(Categories).filter(k => isNaN(Number(k)));
        const found = keys.find(k => normalize(k) === normalize(categoryValue));
        if (found) key = found;
      }
    }

    if (!key) key = String(categoryValue);

    return this.translate.instant(`enums.category.${key}`);
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
        return this.translate.instant('date.justNow');
      } else if (minutes < 60) {
        const key = minutes === 1 ? 'date.minutesAgo_one' : 'date.minutesAgo_other';
        return this.translate.instant(key, { count: minutes });
      } else if (hours < 24) {
        const key = hours === 1 ? 'date.hoursAgo_one' : 'date.hoursAgo_other';
        return this.translate.instant(key, { count: hours });
      } else if (days < 30) {
        const key = days === 1 ? 'date.daysAgo_one' : 'date.daysAgo_other';
        return this.translate.instant(key, { count: days });
      } else {
        const months = Math.floor(days / 30);
        const key = months === 1 ? 'date.monthsAgo_one' : 'date.monthsAgo_other';
        return this.translate.instant(key, { count: months });
      }
    } catch (e) {
      console.error('Error translating date:', e);
      return '';
    }
  }

  getHistoryIcon(type: number): string {
    switch (type) {
      case 0:
        return 'fas fa-plus-circle';
      case 1:
        return 'fas fa-check-circle';
      case 2:
        return 'fas fa-user-tag';
      case 3:
        return 'fas fa-hand-paper';
      case 4:
        return 'fas fa-user-gear';
      case 5:
        return 'fas fa-screwdriver-wrench';
      case 6:
        return 'fas fa-circle-check';
      case 7:
        return 'fas fa-circle-xmark';
      case 8:
        return 'fas fa-thumbs-up';
      default:
        return 'fas fa-circle';
    }
  }

  interventionLabel(type: number): string {
    switch (type) {
      case 0:
        return this.translate.instant('interventionType.Created');
      case 1:
        return this.translate.instant('interventionType.Validated');
      case 2:
        return this.translate.instant('interventionType.AssignedToCitizen');
      case 3:
        return this.translate.instant('interventionType.TaskTookByCitizen');
      case 4:
        return this.translate.instant('interventionType.AssignedToBlueCollar');
      case 5:
        return this.translate.instant('interventionType.UnderRepair');
      case 6:
        return this.translate.instant('interventionType.DoneRepairing');
      case 7:
        return this.translate.instant('interventionType.RefusedRepair');
      case 8:
        return this.translate.instant('interventionType.ApprovedRepair');
      default:
        return 'error';
    }
  }

  roleLabel(type: string): string {
    switch (type) {
      case '1':
        return this.translate.instant('role.WhiteCollar');
      case '2':
        return this.translate.instant('role.BlueCollar');
      case '3':
        return this.translate.instant('role.Citizen');
      case '4':
        return this.translate.instant('role.Admin');
      default:
        return 'error';
    }
  }

}