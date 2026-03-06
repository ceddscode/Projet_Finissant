import {
  Component, OnInit, OnDestroy, ViewChild,
  ElementRef, AfterViewChecked, ChangeDetectorRef
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { ChatSignalRService } from '../hub/ChatSignalRService';
import { ApiService } from '../services/api-service';
import { Conversation, CitizenDto, Message, MessageGroup, ConversationDto } from '../models/Incidents';
import { Router } from '@angular/router';
import { CategoryLabelPipe } from '../pipes/categoryLabel/category-label.pipe';
import { StatusLabelPipe } from '../pipes/statusLabel/status-label-pipe';
import { TranslateModule } from '@ngx-translate/core';

const AVATAR_COLORS = ['#6366f1', '#f59e0b', '#10b981', '#ec4899', '#8b5cf6', '#06b6d4', '#f97316'];

@Component({
  selector: 'app-chat',
  standalone: true,
  imports: [CommonModule, FormsModule, CategoryLabelPipe, StatusLabelPipe, TranslateModule],
  templateUrl: './chat.html',
  styleUrls: ['./chat.css']
})
export class ChatComponent implements OnInit, OnDestroy, AfterViewChecked {
  @ViewChild('messagesContainer') messagesContainer!: ElementRef;
  @ViewChild('messageInput') messageInput!: ElementRef;

  conversations: Conversation[] = [];
  filteredConversations: Conversation[] = [];

  incidents: any[] = [];
  showIncidentPicker = false;

  allCitizens: CitizenDto[] = [];
  filteredCitizens: CitizenDto[] = [];

  activeConversation: Conversation | null = null;
  messages: Message[] = [];
  groupedMessages: MessageGroup[] = [];

  newMessage = '';
  searchQuery = '';
  citizenSearchQuery = '';
  showNewChatModal = false;
  partnerTyping = false;
  loading = false;

  private destroy$ = new Subject<void>();
  private shouldScrollToBottom = false;

  constructor(
    private chatSignalR: ChatSignalRService,
    private api: ApiService,
    private cdr: ChangeDetectorRef,
    private router: Router
  ) {}

  async ngOnInit() {
    await this.chatSignalR.connect();
    await this.loadConversations();

    this.chatSignalR.messages$
      .pipe(takeUntil(this.destroy$))
      .subscribe(msgs => {
        this.messages = msgs;
        this.groupedMessages = this.groupMessagesByDate(msgs);
        this.shouldScrollToBottom = true;
        this.cdr.detectChanges();
      });

    this.chatSignalR.partnerOnline$
      .pipe(takeUntil(this.destroy$))
      .subscribe(online => {
        if (this.activeConversation) this.activeConversation.online = online;
      });

    this.chatSignalR.partnerTyping$
      .pipe(takeUntil(this.destroy$))
      .subscribe(typing => {
        this.partnerTyping = typing;
        if (typing) {
          // ✅ Only scroll if already near bottom
          const el = this.messagesContainer?.nativeElement;
          if (el) {
            const isNearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 100;
            if (isNearBottom) this.shouldScrollToBottom = true;
          }
        }
        this.cdr.detectChanges();
      });

    this.chatSignalR.lastMessage$
      .pipe(takeUntil(this.destroy$))
      .subscribe(msg => {
        if (!msg) return;
        const isIncoming = msg.fromCitizenId === this.activeConversation?.citizenId;
        const relatedCitizenId = isIncoming ? msg.fromCitizenId : this.activeConversation?.citizenId;
        if (!relatedCitizenId) return;
        const conv = this.conversations.find(c => c.citizenId === relatedCitizenId);
        if (conv) {
          conv.lastMessage = msg.message;
          conv.lastMessageTime = msg.sentAt;
          if (isIncoming && this.activeConversation?.citizenId === relatedCitizenId) {
            this.api.MarkAsRead(relatedCitizenId);
          }
          this.conversations = [conv, ...this.conversations.filter(c => c.citizenId !== conv.citizenId)];
          this.filteredConversations = [...this.conversations];
        }
        this.cdr.detectChanges();
      });

    // Subscribe to unreadMap$ to keep conversation badges in sync
    this.chatSignalR.unreadMap$
      .pipe(takeUntil(this.destroy$))
      .subscribe(map => {
        for (const conv of this.conversations) {
          // Only update unread from map if we haven't opened the conversation
          if (map.has(conv.citizenId)) {
            conv.unreadCount = map.get(conv.citizenId)!;
          }
        }
        this.cdr.detectChanges();
      });

    this.chatSignalR.newConversation$
      .pipe(takeUntil(this.destroy$))
      .subscribe(data => {
        if (!data) return;
        const isActive = this.activeConversation?.citizenId === data.fromCitizenId;
        if (isActive) return;

        const exists = this.conversations.find(c => c.citizenId === data.fromCitizenId);
        if (exists) {
          // ✅ Update lastMessage regardless (empty string = incident preview in template)
          exists.lastMessage = data.message;
          exists.lastMessageTime = data.sentAt;
          this.conversations = [exists, ...this.conversations.filter(c => c.citizenId !== exists.citizenId)];
        } else {
          const newConv: Conversation = {
            citizenId:       data.fromCitizenId,
            userId:          '',
            name:            data.fromName || 'Unknown',
            online:          true,
            lastMessage:     data.message,
            lastMessageTime: data.sentAt,
            unreadCount:     1,
            color:           this.getAvatarColor(data.fromCitizenId)
          };
          this.conversations = [newConv, ...this.conversations];
        }
        this.filteredConversations = [...this.conversations];
        this.cdr.detectChanges();
      });
  }

  ngAfterViewChecked() {
    if (this.shouldScrollToBottom) {
      this.scrollToBottom();
      this.shouldScrollToBottom = false;
    }
  }

  ngOnDestroy() {
    this.chatSignalR.setActiveConversation(null);
    this.destroy$.next();
    this.destroy$.complete();
  }

  // ── Conversations ─────────────────────────────────────────────────────────

  async loadConversations() {
    try {
      this.loading = true;
      const dtos = await this.api.GetConversations();
      const unreadMap = this.chatSignalR.unreadMap$.value;

      this.conversations = dtos.map(d => {
        const conv = this.mapConversation(d);
        // If service has marked this as read (not in map), force 0
        // If service has a count for it, use service value (more up to date)
        if (unreadMap.has(conv.citizenId)) {
          conv.unreadCount = unreadMap.get(conv.citizenId)!;
        } else if (!unreadMap.has(conv.citizenId) && conv.unreadCount > 0) {
          // Server says unread but user hasn't received it via SignalR this session
          // Check if they've explicitly read it (not in map means either never got it or already read)
          // We trust the server for initial load only if map has no opinion
          conv.unreadCount = conv.unreadCount;
        }
        return conv;
      });

      this.filteredConversations = [...this.conversations];
    } catch (e) {
      console.error('Failed to load conversations:', e);
    } finally {
      this.loading = false;
    }
  }

  async openIncidentPicker() {
    this.showIncidentPicker = true;
    this.incidents = await this.api.GetChatIncidents();
  }

  openIncident(incident: any) {
    this.router.navigate(['/details/', incident.id]);
  }

  getMessagePreview(msg: string | null | undefined): string {
    if (!msg || msg.trim() === '') return '';
    return msg.length > 40 ? msg.substring(0, 40) + '...' : msg;
  }

  async shareIncident(incident: any) {
    if (!this.activeConversation) return;
    this.showIncidentPicker = false;
    await this.chatSignalR.sendIncident(this.activeConversation.citizenId, incident.id, incident);
    const conv = this.conversations.find(c => c.citizenId === this.activeConversation!.citizenId);
    if (conv) {
      conv.lastMessage = '';
      conv.lastMessageTime = new Date();
      this.conversations = [conv, ...this.conversations.filter(c => c.citizenId !== conv.citizenId)];
      this.filteredConversations = [...this.conversations];
      this.cdr.detectChanges();
    }
  }

  async selectConversation(conv: Conversation) {
    if (this.activeConversation) {
      await this.chatSignalR.closeConversation(this.activeConversation.citizenId);
    }
    this.activeConversation = conv;
    conv.unreadCount = 0;
    this.chatSignalR.markRead(conv.citizenId);
    this.chatSignalR.setActiveConversation(conv.citizenId);
    this.messages = [];
    this.groupedMessages = [];
    this.partnerTyping = false;
    await this.chatSignalR.openConversation(conv.citizenId);
    await this.api.MarkAsRead(conv.citizenId);
    this.shouldScrollToBottom = true;
  }

  filterConversations() {
    const q = this.searchQuery.toLowerCase();
    this.filteredConversations = this.conversations.filter(c =>
      c.name.toLowerCase().includes(q) || c.lastMessage.toLowerCase().includes(q)
    );
  }

  // ── New Chat Modal ────────────────────────────────────────────────────────

  async openNewChat() {
    this.showNewChatModal = true;
    this.citizenSearchQuery = '';
    try {
      this.allCitizens = await this.api.SearchCitizens();
      this.filteredCitizens = [...this.allCitizens];
    } catch (e) {
      console.error('Failed to load citizens:', e);
    }
  }

  closeNewChat() {
    this.showNewChatModal = false;
  }

  async filterCitizens() {
    try {
      this.filteredCitizens = await this.api.SearchCitizens(this.citizenSearchQuery);
    } catch (e) {
      console.error('Failed to search citizens:', e);
    }
  }

  startConversation(citizen: CitizenDto) {
    const existing = this.conversations.find(c => c.citizenId === citizen.id);
    if (existing) {
      this.selectConversation(existing);
    } else {
      const newConv: Conversation = {
        citizenId:       citizen.id,
        userId:          '',
        name:            citizen.name,
        online:          citizen.online,
        lastMessage:     '',
        lastMessageTime: null,
        unreadCount:     0,
        color:           this.getAvatarColor(citizen.id)
      };
      this.conversations.unshift(newConv);
      this.filteredConversations = [...this.conversations];
      this.selectConversation(newConv);
    }
    this.closeNewChat();
  }

  // ── Messaging ─────────────────────────────────────────────────────────────

  async sendMessage() {
    const text = this.newMessage.trim();
    if (!text || !this.activeConversation) return;
    this.newMessage = '';
    this.autoResizeTextarea();
    this.partnerTyping = false;
    await this.chatSignalR.sendMessage(this.activeConversation.citizenId, text);
  }

  onEnterKey(event: Event) {
    const e = event as KeyboardEvent;
    if (!e.shiftKey) {
      e.preventDefault();
      this.sendMessage();
    }
  }

  onTyping() {
    this.autoResizeTextarea();
    if (this.activeConversation) {
      this.chatSignalR.sendTyping(this.activeConversation.citizenId);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  private mapConversation(dto: ConversationDto): Conversation {
    return {
      citizenId:       dto.citizenId,
      userId:          '',
      name:            dto.name,
      online:          dto.online,
      lastMessage:     dto.lastMessage || '',
      lastMessageTime: new Date(dto.lastMessageTime),
      unreadCount:     dto.unreadCount,
      color:           this.getAvatarColor(dto.citizenId)
    };
  }

  getAvatarColor(citizenId: number): string {
    return AVATAR_COLORS[citizenId % AVATAR_COLORS.length];
  }

  getInitial(name: string): string {
    return name.charAt(0).toUpperCase();
  }

  isMyMessage(msg: Message): boolean {
    return msg.fromCitizenId !== this.activeConversation?.citizenId;
  }

  private groupMessagesByDate(messages: Message[]): MessageGroup[] {
    const groups = new Map<string, MessageGroup>();
    for (const msg of messages) {
      const key = new Date(msg.sentAt).toDateString();
      if (!groups.has(key)) {
        groups.set(key, { date: new Date(msg.sentAt), messages: [] });
      }
      groups.get(key)!.messages.push(msg);
    }
    return Array.from(groups.values());
  }

  async deleteConversation(conv: Conversation, event: Event) {
    event.stopPropagation();
    await this.api.DeleteConversation(conv.citizenId);
    this.chatSignalR.markRead(conv.citizenId); // clean up badge too
    this.conversations = this.conversations.filter(c => c.citizenId !== conv.citizenId);
    this.filteredConversations = this.filteredConversations.filter(c => c.citizenId !== conv.citizenId);
    if (this.activeConversation?.citizenId === conv.citizenId) {
      await this.chatSignalR.closeConversation(conv.citizenId);
      this.activeConversation = null;
    }
  }

  private scrollToBottom() {
    try {
      const el = this.messagesContainer?.nativeElement;
      if (el) el.scrollTop = el.scrollHeight;
    } catch {}
  }

  private autoResizeTextarea() {
    const el = this.messageInput?.nativeElement;
    if (el) {
      el.style.height = 'auto';
      el.style.height = Math.min(el.scrollHeight, 120) + 'px';
    }
  }
}