import { Component, signal, OnInit, OnDestroy, HostListener } from '@angular/core';
import { RouterOutlet, RouterLink, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatSelectModule } from '@angular/material/select';
import { FormsModule } from '@angular/forms';
import { ConfirmModalComponent } from './modal/confirm-modal.component';
import { ChatSignalRService } from './hub/ChatSignalRService';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { FlappyComponent } from './flappy/flappy';
import { SnakeOverlayComponent } from './snake/snake';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    RouterOutlet, RouterLink, CommonModule,
    MatButtonModule, TranslateModule,
    MatFormFieldModule, MatSelectModule,
    FormsModule, ConfirmModalComponent, FlappyComponent, SnakeOverlayComponent
  ],
  templateUrl: './app.html',
  styleUrls: ['./app.css']
})
export class App implements OnInit, OnDestroy {
  protected readonly title = signal('ngMunicipaliGo');

  language: string = 'fr';
  totalUnread = 0;

  private destroy$ = new Subject<void>();

  constructor(
    public translator: TranslateService,
    private router: Router,
    private chatSignalR: ChatSignalRService
  ) {
    this.translator.addLangs(['en', 'fr']);
    this.translator.setFallbackLang('fr');
    const saved = localStorage.getItem('language');
    const initial = saved ?? 'fr';
    this.language = initial;
    this.translator.use(initial);
  }

  async ngOnInit() {
    if (this.isLoggedIn()) {
      await this.chatSignalR.connect();

      // Derive totalUnread directly from unreadMap$ — single source of truth
      this.chatSignalR.unreadMap$
        .pipe(takeUntil(this.destroy$))
        .subscribe(map => {
          let total = 0;
          map.forEach(v => total += v);
          this.totalUnread = total;
        });
    }
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  changeLanguage(lang: string) {
    this.language = lang;
    this.translator.use(lang);
    localStorage.setItem('language', lang);
  }

  isLoggedIn() {
    return localStorage.getItem('token') != null;
  }

  isAdmin() {
    return localStorage.getItem('role') === 'Admin';
  }

  isWhiteCollar() {
    return localStorage.getItem("role") === "White collar";
  }

  logout() {
    localStorage.clear();
    this.router.navigate(['/login']);
  }
  
  private secretCode = 'pobrille';
  private buffer = '';
clickCount = 0;
showGame = false;
showSnake = false;
 @HostListener('window:keydown', ['$event'])
  handleSecret(event: KeyboardEvent) {

    // On ignore les touches spéciales (Shift, Alt, etc.)
    if (event.key.length !== 1) return;

    this.buffer += event.key.toLowerCase();

    // On garde seulement la longueur du code
    if (this.buffer.length > this.secretCode.length) {
      this.buffer = this.buffer.slice(-this.secretCode.length);
    }

    if (this.buffer === this.secretCode) {
      this.showSnake = true;
      this.buffer = '';
    }
  }




private clickTimer: any;

logoClick() {
  this.clickCount++;

  clearTimeout(this.clickTimer);

  // Reset if user waits too long
  this.clickTimer = setTimeout(() => {
    this.clickCount = 0;
  }, 800);

  if (this.clickCount === 5) {
    this.showGame = true;
    this.clickCount = 0;
  }
}
}