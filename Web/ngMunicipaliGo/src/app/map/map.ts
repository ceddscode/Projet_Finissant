import { CommonModule } from '@angular/common';
import {
  Component,
  OnInit,
  ViewChild,
  HostListener,
  AfterViewInit,
  OnDestroy
} from '@angular/core';
import { FormsModule } from '@angular/forms';
import { GoogleMap, GoogleMapsModule } from '@angular/google-maps';
import { Router, RouterModule } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { ApiService } from '../services/api-service';
import { Incident } from '../models/Incidents';
import { QUARTIER_SHAPES, QUARTIER_NAMES } from '../services/quartiers.services';

type MarkerVM = {
  id: number;
  position: google.maps.LatLngLiteral;
  options: google.maps.MarkerOptions;
};

type BoundsLiteral = {
  north: number;
  south: number;
  east: number;
  west: number;
};

type QuartierShape = {
  bounds: BoundsLiteral;
  polygon?: google.maps.LatLngLiteral[];
};

@Component({
  selector: 'app-map',
  standalone: true,
  imports: [GoogleMapsModule, RouterModule, CommonModule, FormsModule, TranslateModule],
  templateUrl: './map.html',
  styleUrls: ['./map.css'],
})
export class Map implements OnInit, AfterViewInit, OnDestroy {
  @ViewChild('map') map?: GoogleMap;

  incidents: Incident[] = [];
  visible: Incident[] = [];
  incidentMarkers: MarkerVM[] = [];

  center: google.maps.LatLngLiteral = { lat: 45.5312, lng: -73.5181 };
  zoom = 13;

  options: google.maps.MapOptions = {
    disableDefaultUI: true,
    clickableIcons: false,
    styles: [
      { featureType: 'poi', stylers: [{ visibility: 'off' }] },
      { featureType: 'transit', stylers: [{ visibility: 'off' }] },
    ],
  };

  private icon: google.maps.Icon = {
    url: 'https://static.vecteezy.com/system/resources/thumbnails/017/178/327/small_2x/warning-hazard-sign-on-transparent-background-free-png.png',
    scaledSize: new google.maps.Size(28, 28),
    anchor: new google.maps.Point(14, 28),
  };

  // Ajout d'une map d'icônes par catégorie
  private readonly categoryIcons: Record<number, google.maps.Icon> = {
    0: {
      url: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f9f9.png', // Propreté (balai)
      scaledSize: new google.maps.Size(28, 28),
      anchor: new google.maps.Point(14, 28),
    },
    1: {
      url: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f6cb.png', // Mobilier (banc)
      scaledSize: new google.maps.Size(28, 28),
      anchor: new google.maps.Point(14, 28),
    },
    2: {
      url: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f6a6.png', // Signalisation (feu tricolore)
      scaledSize: new google.maps.Size(28, 28),
      anchor: new google.maps.Point(14, 28),
    },
    3: {
      url: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f333.png', // EspacesVerts (arbre)
      scaledSize: new google.maps.Size(28, 28),
      anchor: new google.maps.Point(14, 28),
    },
    4: {
      url: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f342.png', // Saisonnier (feuille d'arbre)
      scaledSize: new google.maps.Size(28, 28),
      anchor: new google.maps.Point(14, 28),
    },
    5: {
      url: 'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/1f465.png', // Social (personnes)
      scaledSize: new google.maps.Size(28, 28),
      anchor: new google.maps.Point(14, 28),
    },
  };

  q = '';
  selectedQuartier = '';
  selectedCategory: number | null = null;
  selectedStatus = '';

  quartiers: string[] = QUARTIER_NAMES;
  private readonly quartierShapes: Record<string, QuartierShape> = QUARTIER_SHAPES as any;

  categories: Array<{ value: number; label: string }> = [
    { value: 0, label: 'enums.category.Propreté' },
    { value: 1, label: 'enums.category.Mobilier' },
    { value: 2, label: 'enums.category.Signalisation' },
    { value: 3, label: 'enums.category.EspacesVerts' },
    { value: 4, label: 'enums.category.Saisonnier' },
    { value: 5, label: 'enums.category.Social' },
  ];

  statuses: Array<{ value: number; label: string }> = [
    { value: 0, label: 'enums.status.WaitingForValidation' },
    { value: 1, label: 'enums.status.WaitingForAssignation' },
    { value: 2, label: 'enums.status.AssignedToCitizen' },
    { value: 3, label: 'enums.status.UnderRepair' },
    { value: 4, label: 'enums.status.Done' },
    { value: 5, label: 'enums.status.AssignedToBlueCollar' },
    { value: 6, label: 'enums.status.WaitingForAssignationToCitizen' },
    { value: 7, label: 'enums.status.WaitingForConfirmation' },
  ];

  selectedPolygonPaths: google.maps.LatLngLiteral[] | null = null;

  sheetMin = 120;
  sheetMax = 520;
  sheetHeight = 260;

  private dragging = false;
  private dragStartY = 0;
  private startHeight = 0;

  constructor(
    private apiService: ApiService,
    private router: Router,
    public translator: TranslateService
  ) {}

  ngAfterViewInit() {
    this.sheetMax = Math.min(620, Math.floor(window.innerHeight * 0.75));
    this.sheetHeight = Math.min(Math.max(this.sheetHeight, this.sheetMin), this.sheetMax);
  }
  ngOnDestroy() {
  const main = document.querySelector('.app-main') as HTMLElement;
  if (main) main.style.overflow = ''; // ← restores scroll for all other pages
}

  async ngOnInit() {
      const main = document.querySelector('.app-main') as HTMLElement;
  if (main) main.style.overflow = 'hidden';
    try {
      this.incidents = await this.apiService.GetValidatedIncidents();
      this.applyFilters();
    } catch (e) {
      console.error(e);
      this.incidents = [];
      this.visible = [];
      this.incidentMarkers = [];
    }
  }

  private normalizeQuartierName(v: string) {
    return (v ?? '').toString().trim().replace(/\s+/g, ' ');
  }

  applyFilters() {
    const q = this.q.trim().toLowerCase();
    const quartier = this.normalizeQuartierName(this.selectedQuartier).toLowerCase();
    const cat = this.selectedCategory;
    const st = this.selectedStatus;

    this.visible = this.incidents.filter(i => {
      const t = (i.title ?? '').toLowerCase();
      const matchesText = !q || t.includes(q);

      const iq = this.normalizeQuartierName((i as any).quartier).toLowerCase();
      const matchesQuartier = !quartier || iq === quartier;

      const incidentCat = (i as any).category ?? (i as any).categories;
      const matchesCategory = cat === null || cat === undefined || incidentCat === cat;

      const incidentStatus = (i as any).status;
      const matchesStatus = st === '' || st === null || st === undefined || incidentStatus === Number(st);

      return matchesText && matchesQuartier && matchesCategory && matchesStatus;
    });

    // Marker par catégorie
    this.incidentMarkers = this.visible
      .filter(i => (i as any).latitude != null && (i as any).longitude != null)
      .map(i => {
        const cat = (i as any).category ?? (i as any).categories;
        return {
          id: (i as any).id,
          position: { lat: Number((i as any).latitude), lng: Number((i as any).longitude) },
          options: { icon: this.categoryIcons[cat] ?? this.icon },
        };
      });

    this.applyQuartierZoomAndBorder();
  }

  onQuartierChanged() {
    this.applyFilters();
    this.applyQuartierZoomAndBorder();
  }

  private applyQuartierZoomAndBorder() {
    const name = this.normalizeQuartierName(this.selectedQuartier);
    if (!name) {
      this.selectedPolygonPaths = null;
      return;
    }

    const shape = this.quartierShapes[name];
    if (!shape) {
      this.selectedPolygonPaths = null;
      return;
    }

    const b = shape.bounds;
    const bounds = new google.maps.LatLngBounds(
      { lat: b.south, lng: b.west },
      { lat: b.north, lng: b.east }
    );

    this.map?.googleMap?.fitBounds(bounds, 60);
    this.selectedPolygonPaths = shape.polygon ?? this.boundsToPolygon(b);
  }

  private boundsToPolygon(b: BoundsLiteral): google.maps.LatLngLiteral[] {
    return [
      { lat: b.north, lng: b.west },
      { lat: b.north, lng: b.east },
      { lat: b.south, lng: b.east },
      { lat: b.south, lng: b.west },
    ];
  }

  resetFilters() {
    this.q = '';
    this.selectedQuartier = '';
    this.selectedCategory = null;
    this.selectedStatus = '';
    this.selectedPolygonPaths = null;

    this.applyFilters();
    this.map?.googleMap?.panTo(this.center);
    this.map?.googleMap?.setZoom(this.zoom);
  }

  onMarkerClick(id: number) {
    this.router.navigate(['/details', id]);
  }

  openDetails(i: Incident) {
    this.router.navigate(['/details', (i as any).id]);
  }

  focusOn(i: Incident) {
    const lat = Number((i as any).latitude);
    const lng = Number((i as any).longitude);
    if (!isFinite(lat) || !isFinite(lng)) return;

    this.map?.googleMap?.panTo({ lat, lng });
    this.map?.googleMap?.setZoom(16);
    this.sheetHeight = this.sheetMin;
  }

  trackById(_: number, item: Incident) {
    return (item as any).id;
  }

  startDrag(ev: MouseEvent | TouchEvent) {
    this.dragging = true;
    this.dragStartY = this.getClientY(ev);
    this.startHeight = this.sheetHeight;
    ev.preventDefault();
  }

  @HostListener('window:mousemove', ['$event'])
  onMoveMouse(ev: MouseEvent) {
    if (!this.dragging) return;
    this.onDrag(ev);
  }

  @HostListener('window:touchmove', ['$event'])
  onMoveTouch(ev: TouchEvent) {
    if (!this.dragging) return;
    this.onDrag(ev);
  }

  @HostListener('window:mouseup')
  endMoveMouse() {
    this.dragging = false;
  }

  @HostListener('window:touchend')
  endMoveTouch() {
    this.dragging = false;
  }

  private onDrag(ev: MouseEvent | TouchEvent) {
    const y = this.getClientY(ev);
    const delta = this.dragStartY - y;
    const next = this.startHeight + delta;
    this.sheetHeight = Math.min(this.sheetMax, Math.max(this.sheetMin, next));
  }

  private getClientY(ev: MouseEvent | TouchEvent) {
    return ev instanceof MouseEvent ? ev.clientY : ev.touches[0].clientY;
  }

  thumbUrl(i: Incident) {
    const list = ((i as any).imagesUrl as any) as string[] | undefined;
    const url = list?.[0];
    return url && typeof url === 'string' && url.length ? url : '';
  }

  categoryLabel(cat: number) {
    const keys = [
      'Propreté',
      'Mobilier',
      'Signalisation',
      'EspacesVerts',
      'Saisonnier',
      'Social',
    ];
    return this.translator.instant('enums.category.' + keys[cat]);
  }

  statusLabel(status: number) {
    const keys = [
      'WaitingForValidation',
      'WaitingForAssignation',
      'AssignedToCitizen',
      'UnderRepair',
      'Done',
      'AssignedToBlueCollar',
      'WaitingForAssignationToCitizen',
      'WaitingForConfirmation',
    ];
    return this.translator.instant('enums.status.' + keys[status]);
  }

  private categoryEnumIndexToName(idx: any): string | undefined {
    const map = ['Propreté', 'Mobilier', 'Signalisation', 'EspacesVerts', 'Saisonnier', 'Social'];
    if (typeof idx === 'number' && idx >= 0 && idx < map.length) return map[idx];
    if (!isNaN(Number(idx)) && Number(idx) >= 0 && Number(idx) < map.length) return map[Number(idx)];
    return undefined;
  }
}