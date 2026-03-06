import { Injectable, OnDestroy } from '@angular/core';
import * as signalR from '@microsoft/signalr';
import { BehaviorSubject } from 'rxjs';
import { ApiService } from '../services/api-service';

export interface Message {
  fromCitizenId: number;
  message: string;
  sentAt: Date;
  sharedIncident?: any;
}

@Injectable({ providedIn: 'root' })
export class ChatSignalRService implements OnDestroy {

  private hub: signalR.HubConnection;

  // Single source of truth: citizenId -> unread count
  // App reads totalUnread from this, ChatComponent clears per-conversation
  unreadMap$ = new BehaviorSubject<Map<number, number>>(new Map());
  private activePartnerId: number | null = null;
  messages$        = new BehaviorSubject<Message[]>([]);
  partnerOnline$   = new BehaviorSubject<boolean>(false);
  partnerTyping$   = new BehaviorSubject<boolean>(false);
  lastMessage$     = new BehaviorSubject<{ fromCitizenId: number; message: string; sentAt: Date } | null>(null);
  newConversation$ = new BehaviorSubject<{
    fromCitizenId: number;
    fromName: string;
    message: string;
    sentAt: Date;
  } | null>(null);

  private typingTimeout: any;

  constructor(private api: ApiService) {
    this.hub = new signalR.HubConnectionBuilder()
      .withUrl(`${this.api['serverUrl']}/hubs/chat`, {
        accessTokenFactory: () => localStorage.getItem('token') ?? ''
      })
      .withAutomaticReconnect()
      .build();

    // ── ReceiveMessage ───────────────────────────────────────────────────────
    this.hub.on('ReceiveMessage', (fromCitizenId: number, message: string, sentAt: string) => {
      const msg: Message = { fromCitizenId, message, sentAt: new Date(sentAt) };
      this.messages$.next([...this.messages$.value, msg]);
      this.lastMessage$.next(msg);
      this.partnerTyping$.next(false);
    });

    // ── ReceiveIncident ──────────────────────────────────────────────────────
    this.hub.on('ReceiveIncident', (fromCitizenId: number, incident: any, sentAt: string) => {
    const msg: Message = {
        fromCitizenId,
        message: '',
        sentAt: new Date(sentAt),
        sharedIncident: incident
    };
    this.messages$.next([...this.messages$.value, msg]);
    this.lastMessage$.next({ fromCitizenId, message: '', sentAt: new Date(sentAt) });
    });

    // ── NewConversationMessage ───────────────────────────────────────────────
    // This fires when the partner is NOT in the room (background notification)
    this.hub.on('NewConversationMessage', (fromCitizenId: number, fromName: string, message: string, sentAt: string) => {
    if (fromCitizenId !== this.activePartnerId) {
        this._addUnread(fromCitizenId);
    }
    this.newConversation$.next({ fromCitizenId, fromName, message, sentAt: new Date(sentAt) });
    });

    // ── PartnerTyping ────────────────────────────────────────────────────────
    this.hub.on('PartnerTyping', () => {
      this.partnerTyping$.next(true);
      clearTimeout(this.typingTimeout);
      this.typingTimeout = setTimeout(() => this.partnerTyping$.next(false), 3000);
    });

    // ── Online/Offline ───────────────────────────────────────────────────────
    this.hub.on('PartnerOnline',  () => this.partnerOnline$.next(true));
    this.hub.on('PartnerOffline', () => this.partnerOnline$.next(false));
  }

  async connect(): Promise<void> {
    if (this.hub.state === signalR.HubConnectionState.Disconnected) {
      await this.hub.start();
    }
  }
  
  setActiveConversation(citizenId: number | null) {
    this.activePartnerId = citizenId;
  }

  async openConversation(partnerUserId: number): Promise<void> {
    const history = await this.api.GetMessages(partnerUserId);
    this.messages$.next(history.map(m => ({
      fromCitizenId: m.fromCitizenId,
      message: m.message,
      sentAt: new Date(m.sentAt),
      sharedIncident: m.sharedIncident
    })));
    await this.hub.invoke('OpenConversation', partnerUserId);
  }

  async closeConversation(partnerUserId: number): Promise<void> {
    await this.hub.invoke('CloseConversation', partnerUserId);
    this.messages$.next([]);
    this.partnerOnline$.next(false);
    this.partnerTyping$.next(false);
  }

  // Called when user opens a conversation — removes it from unread map
  markRead(citizenId: number): void {
    const map = new Map(this.unreadMap$.value);
    map.delete(citizenId);
    this.unreadMap$.next(map);
  }

  // Internal only
  private _addUnread(citizenId: number): void {
    const map = new Map(this.unreadMap$.value);
    map.set(citizenId, (map.get(citizenId) ?? 0) + 1);
    this.unreadMap$.next(map);
  }

  async sendMessage(toUserId: number, message: string): Promise<void> {
    const msg: Message = { fromCitizenId: -1, message, sentAt: new Date() };
    this.messages$.next([...this.messages$.value, msg]);
    await this.hub.invoke('SendMessage', toUserId, message);
  }

  async sendIncident(toCitizenId: number, incidentId: number, incident: any): Promise<void> {
    const msg: Message = { fromCitizenId: -1, message: '', sentAt: new Date(), sharedIncident: incident };
    this.messages$.next([...this.messages$.value, msg]);
    await this.hub.invoke('SendIncident', toCitizenId, incidentId);
  }

  async sendTyping(toCitizenId: number): Promise<void> {
    if (this.hub.state === signalR.HubConnectionState.Connected)
      await this.hub.invoke('Typing', toCitizenId);
  }

  async disconnect(): Promise<void> {
    if (this.hub.state !== signalR.HubConnectionState.Disconnected)
      await this.hub.stop();
  }

  ngOnDestroy(): void {
    this.disconnect();
  }
}