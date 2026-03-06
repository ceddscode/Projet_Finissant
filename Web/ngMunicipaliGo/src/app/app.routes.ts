import { Routes } from '@angular/router';
import { Login } from './login/login';
import { Attente } from './attente/attente';
import { securityGuard } from './security-guard';
import { Details } from './details/details';
import { Assignation } from './assignation/assignation';
import { Admin } from './admin/admin';
import { adminGuard} from './admin-guard-guard';
import { Map } from './map/map';
import { UserDetails } from './user-details/user-details';
import { UserCreate } from './user-create/user-create';
import { Confirmation } from './confirmation/confirmation';
import { DetailsConfirmation } from './details-confirmation/details-confirmation';
import { AdminIncidentList } from './admin-incident-list/admin-incident-list';
import { WhitecolarAll } from './whitecolar-all/whitecolar-all';
import { Statistics } from './statistics/statistics';
import { ChatComponent } from './chat/chat';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'login', component: Login },
  { path: 'map', component: Map, canActivate : [securityGuard] },
  { path: 'whitecolar', component: WhitecolarAll, canActivate : [securityGuard] },
  { path: 'attente', component: Attente , canActivate : [securityGuard] },
  { path: 'details/:id', component: Details  , canActivate : [securityGuard]},
  { path: 'assignation', component: Assignation , canActivate : [securityGuard] },
  { path: 'confirmation', component: Confirmation, canActivate: [securityGuard]},
  { path: 'statistics', component: Statistics, canActivate: [securityGuard]},
  { path: 'confirmation-details/:id', component: DetailsConfirmation, canActivate: [securityGuard]},
  { path: 'chat', component: ChatComponent, canActivate: [securityGuard]},
  { path: 'user-create', component: UserCreate, canActivate: [securityGuard, adminGuard]},
  {
  path: 'admin',
  canActivate: [securityGuard, adminGuard],
  children: [
    { path: '', component: Admin },
    { path: 'user-details/:id', component: UserDetails },
    { path: 'allIncidents', component: AdminIncidentList },
  ]
},
  { path: '**', redirectTo: 'login' }

];

