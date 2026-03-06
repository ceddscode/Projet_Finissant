import { CanActivateFn, createUrlTreeFromSnapshot, Router } from '@angular/router';
import { inject } from "@angular/core";
import { ApiService } from './services/api-service';
export const securityGuard: CanActivateFn = () => {
  const token = localStorage.getItem('token');
  console.log('SECURITY GUARD – token:', !!token);
  return !!token;
};
