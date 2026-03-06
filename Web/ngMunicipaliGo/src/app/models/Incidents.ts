export interface Incident {
    id: number;
    title: string;
    description: string;
    location : string;
    createdAt : Date;
    categories : number;
    status : number;
    assignedAt : string;
    imagesUrl: string[];
    latitude : number;
    longitude : number;
    confirmationDescription : string | undefined;
    confirmationImagesUrl : string[] | undefined;
    likeCount: number;
    quartier : string;
    points:number;
}
export interface IncidentHistoryItem {
  interventionType: number;
  nomUtilisateur: string;
  roleUtilisateur: string;
  updatedAt: string | Date;
  refusDescription?: string;
  confirmationImgUrls?: string[];
}

export interface CommentDTO {
  id: number;
  citizenName: string;
  message: string;
  createdAt: string | Date;
  reportsCount?: number;
}

export enum Status {
  WaitingForValidation = 0,
  WaitingForAssignation = 1,
  AssignedToCitizen = 2,
  UnderRepair = 3,  
  Done = 4,
  AssignedToBlueCollar,
  WaitingForAssignationToCitizen,
  WaitingForConfirmation = 7,
}

export enum Categories {
  Propreté = 0,
  Mobilier = 1,
  Signalisation = 2,
  EspacesVerts = 3,
  Saisonnier = 4,
  Social = 5
}

export interface Citizen {
  id: string; 
  firstName : string;
  lastName : string;
  email : string;
  phoneNumber: string;
  roadNumber: number;
  roadName: string;
  postalCode: string;
  city: string;
  role : string;
}

export interface RegisterDTO {
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  password: string;
  passwordConfirm: string;
  roadNumber: number;
  roadName: string;
  postalCode: string;
  city: string;
}

export interface SortedIncidentdsDTO {
  id: number,
  title: string,
  location: string,
  createdDate: Date,
  status: number,
  category: number,
  closedDate: Date,
  imageUrl: string,
  likeCount: number,
  quartier: string;
}

export interface QueryParametersDTO {
  category?: number;
  status?: number;
  dateFrom?: string;
  dateEnd?: string;
  filterByCreation?: boolean;
  filterByClosing?: boolean;
  search?: string;
  sort?: string;
  direction?: 'asc' | 'desc';
  page?: number;
  pageSize?: number;
}

export interface PagedResult<T> {
  incidents: T[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export interface IncidentListDTO {
  id: number;
  title: string;
  location: string;
  createdAt: string;
  imagesUrl: string[];
  status: number;
  category: number;
  likeCount: number;
  quartier?: string | null;
}

// ── Chat ──────────────────────────────────────────────────────────────────────

// Matches ConversationDto from the server
export interface ConversationDto {
  citizenId: number;
  name: string;
  online: boolean;
  lastMessage: string;
  lastMessageTime: Date;
  unreadCount: number;
}

// Matches MessageDto from the server
export interface SharedIncidentDto {
  id: number;
  title: string;
  description: string;
  status: number;
  category: number;
  location: string;
  photoUrl?: string;
}

export interface MessageDto {
  fromCitizenId: number;
  message: string;
  sentAt: Date;
  read: boolean;
  sharedIncident?: SharedIncidentDto;
}

// Matches CitizenDto from the server — used in the new conversation modal
export interface CitizenDto {
  id: number;
  name: string;
  online: boolean;
}

export interface SharedIncident {
  id: number;
  title: string;
  description: string;
  status: number;
  category: number;
  location: string;
  photoUrl?: string;
}

// Local message model used in the chat component
export interface Message {
  fromCitizenId: number;
  message: string;
  sentAt: Date;
  sharedIncident?: SharedIncident;
}

// Groups messages by date for display
export interface MessageGroup {
  date: Date;
  messages: Message[];
}

// Local conversation model used in the chat component (enriched from ConversationDto)
export interface Conversation {
  citizenId: number;
  userId: string;   // identity user id — used for SignalR hub calls
  name: string;
  online: boolean;
  lastMessage: string;
  lastMessageTime: Date | null;
  unreadCount: number;
  color: string;    // generated client-side for avatar background
}

export interface CategoryChartDto {
  category: string;
  count: number;
}

export interface EvolutionChartDto {
  label: string;
  count: number;
}